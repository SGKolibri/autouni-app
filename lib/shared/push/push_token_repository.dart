import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/network_providers.dart';
import '../../core/push/push_messaging.dart';

/// Token de push deste aparelho no backend (`/push/tokens`). O dono é o
/// usuário do JWT da request.
abstract interface class PushTokenRepository {
  /// Idempotente: registrar de novo só atualiza; token de outra conta muda
  /// de dono.
  Future<void> register(String token, PushPlatform platform);

  /// Idempotente.
  Future<void> unregister(String token);
}

class HttpPushTokenRepository implements PushTokenRepository {
  HttpPushTokenRepository(this._dio);

  final Dio _dio;

  @override
  Future<void> register(String token, PushPlatform platform) => _dio.postJson(
    '/push/tokens',
    data: {'token': token, 'platform': platform.apiValue},
  );

  @override
  Future<void> unregister(String token) =>
      _dio.deleteJson('/push/tokens', data: {'token': token});
}

final pushTokenRepositoryProvider = Provider<PushTokenRepository>(
  (ref) => HttpPushTokenRepository(ref.watch(dioProvider)),
  name: 'pushTokenRepositoryProvider',
);
