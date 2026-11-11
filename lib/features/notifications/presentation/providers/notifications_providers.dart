import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/cached.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/session/session_hooks.dart';
import '../../../../shared/models/notification_type.dart';
import '../../data/notifications_repository.dart';
import '../../domain/app_notification.dart';
import '../../domain/notification_filter.dart';

/// Notificações do usuário logado. Recarrega ao trocar de conta; cada
/// resposta nova da rede descarta as marcações de "lida" já confirmadas.
final notificationsProvider =
    StreamProvider.autoDispose<Cached<List<AppNotification>>>((ref) {
      ref.watch(sessionUserIdProvider);
      final overrides = ref.read(notificationReadOverridesProvider.notifier);
      return ref.watch(notificationsRepositoryProvider).watchMine().map((
        cached,
      ) {
        if (!cached.isStale && !cached.offline) overrides.clearConfirmed();
        return cached;
      });
    }, name: 'notificationsProvider');

/// Marcações de "lida" ainda não refletidas na lista: enviando ([_pending])
/// ou confirmadas pelo backend.
@immutable
class ReadOverrides {
  const ReadOverrides([this._ids = const {}]);

  /// id → ainda enviando?
  final Map<String, bool> _ids;

  bool get isEmpty => _ids.isEmpty;

  AppNotification apply(AppNotification notification) =>
      !notification.read && _ids.containsKey(notification.id)
      ? notification.copyWith(read: true)
      : notification;
}

class NotificationReadOverrides extends Notifier<ReadOverrides> {
  @override
  ReadOverrides build() => const ReadOverrides();

  Map<String, bool> get _ids => state._ids;

  void begin(Iterable<String> ids) =>
      state = ReadOverrides({..._ids, for (final id in ids) id: true});

  void confirm(Iterable<String> ids) =>
      state = ReadOverrides({..._ids, for (final id in ids) id: false});

  void rollback(Iterable<String> ids) {
    final next = {..._ids};
    ids.forEach(next.remove);
    state = ReadOverrides(next);
  }

  /// Descarta as confirmadas (a lista da rede já as traz lidas).
  void clearConfirmed() {
    if (_ids.values.every((pending) => pending)) return;
    state = ReadOverrides({
      for (final entry in _ids.entries)
        if (entry.value) entry.key: true,
    });
  }
}

final notificationReadOverridesProvider =
    NotifierProvider<NotificationReadOverrides, ReadOverrides>(
      NotificationReadOverrides.new,
      name: 'notificationReadOverridesProvider',
    );

/// A lista como a tela mostra (com as marcações de lida); `null` enquanto
/// não carregou.
final visibleNotificationsProvider =
    Provider.autoDispose<List<AppNotification>?>((ref) {
      final list = ref.watch(notificationsProvider).value?.data;
      if (list == null) return null;
      final overrides = ref.watch(notificationReadOverridesProvider);
      return [for (final item in list) overrides.apply(item)];
    }, name: 'visibleNotificationsProvider');

/// Não lidas; `null` enquanto não carregou (badge some, o Início usa o
/// próprio número).
final unreadNotificationsCountProvider = Provider.autoDispose<int?>(
  (ref) =>
      ref.watch(visibleNotificationsProvider)?.where((n) => !n.read).length,
  name: 'unreadNotificationsCountProvider',
);

class NotificationFilterNotifier extends Notifier<NotificationFilter> {
  @override
  NotificationFilter build() => const NotificationFilter();

  void setType(NotificationType? type) =>
      state = state.copyWith(type: type, clearType: type == null);

  void setUnreadOnly(bool value) => state = state.copyWith(unreadOnly: value);
}

final notificationFilterProvider =
    NotifierProvider<NotificationFilterNotifier, NotificationFilter>(
      NotificationFilterNotifier.new,
      name: 'notificationFilterProvider',
    );

/// Marcar como lida, com atualização otimista e rollback. Os métodos
/// devolvem a mensagem de erro, ou `null` em sucesso.
class NotificationsController {
  NotificationsController(this._ref);

  final Ref _ref;

  NotificationsRepository get _repository =>
      _ref.read(notificationsRepositoryProvider);
  NotificationReadOverrides get _overrides =>
      _ref.read(notificationReadOverridesProvider.notifier);

  Future<String?> markRead(AppNotification notification) async {
    if (_ref.read(notificationReadOverridesProvider).apply(notification).read) {
      return null;
    }
    return _run([notification.id], () => _repository.markRead(notification.id));
  }

  Future<String?> markAllRead() async {
    final unread = <String>[
      for (final item
          in _ref.read(visibleNotificationsProvider) ??
              const <AppNotification>[])
        if (!item.read) item.id,
    ];
    if (unread.isEmpty) return null;
    _overrides.begin(unread);
    final failed = await _repository.markAllRead(unread);
    final failedSet = failed.toSet();
    _overrides
      ..confirm(unread.where((id) => !failedSet.contains(id)))
      ..rollback(failed);
    if (failed.isEmpty) return null;
    return failed.length == unread.length
        ? 'Não foi possível marcar os alertas como lidos.'
        : '${failed.length} alerta(s) não puderam ser marcados como lidos.';
  }

  Future<String?> _run(
    List<String> ids,
    Future<void> Function() request,
  ) async {
    _overrides.begin(ids);
    try {
      await request();
      _overrides.confirm(ids);
      return null;
    } on ApiException catch (error) {
      _overrides.rollback(ids);
      return error.message;
    }
  }
}

final notificationsControllerProvider = Provider<NotificationsController>(
  NotificationsController.new,
  name: 'notificationsControllerProvider',
);
