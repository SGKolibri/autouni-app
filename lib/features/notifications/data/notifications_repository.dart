import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cache_providers.dart';
import '../../../core/cache/cached.dart';
import '../../../core/cache/local_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/session/session_hooks.dart';
import '../domain/app_notification.dart';

/// Notificações do usuário logado.
///
/// As rotas `/notifications/me` e `/notifications/me/read-all` do backend
/// passam o payload do JWT inteiro como `userId` e respondem 500. Por isso
/// a lista vem de `/notifications/user/:userId` e "marcar todas" é um
/// `PATCH /:id/read` por alerta.
abstract interface class NotificationsRepository {
  /// Mais recentes primeiro. Cache primeiro. Sem sessão, lista vazia.
  Stream<Cached<List<AppNotification>>> watchMine();

  /// `PATCH /notifications/:id/read`.
  Future<void> markRead(String id);

  /// Marca [ids] como lidas, em paralelo. Devolve os que falharam.
  Future<List<String>> markAllRead(List<String> ids);
}

class HttpNotificationsRepository implements NotificationsRepository {
  HttpNotificationsRepository({
    required this._dio,
    required this._cache,
    required this._userId,
  });

  static String cacheKeyFor(String userId) => 'notifications:user:$userId';

  final Dio _dio;
  final LocalCache _cache;
  final String? _userId;

  @override
  Stream<Cached<List<AppNotification>>> watchMine() {
    final userId = _userId;
    if (userId == null) return Stream.value(const Cached(<AppNotification>[]));
    return cacheThenNetwork(
      cache: _cache,
      key: cacheKeyFor(userId),
      fetch: () => _dio.getJson('/notifications/user/$userId'),
      parse: (json) =>
          parseList(json, AppNotification.fromJson)..sort(_newestFirst),
    );
  }

  @override
  Future<void> markRead(String id) => _dio.patchJson('/notifications/$id/read');

  @override
  Future<List<String>> markAllRead(List<String> ids) async {
    final results = await Future.wait([
      for (final id in ids)
        markRead(id)
            .then<String?>((_) => null)
            .catchError(
              (Object _) => id,
              test: (error) => error is ApiException,
            ),
    ]);
    return results.whereType<String>().toList();
  }

  static int _newestFirst(AppNotification a, AppNotification b) =>
      (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => HttpNotificationsRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(localCacheProvider),
    userId: ref.watch(sessionUserIdProvider),
  ),
  name: 'notificationsRepositoryProvider',
);
