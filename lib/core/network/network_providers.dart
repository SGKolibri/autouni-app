import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config_provider.dart';
import 'auth_token_store.dart';
import 'dio_client.dart';
import 'token_refresher.dart';

/// Guarda dos tokens de sessão.
///
/// Default volátil ([InMemoryAuthTokenStore]); a S2-T3 sobrescreve este
/// provider com a implementação em armazenamento seguro.
final authTokenStoreProvider = Provider<AuthTokenStore>(
  (ref) => InMemoryAuthTokenStore(),
  name: 'authTokenStoreProvider',
);

/// Serviço de renovação de token (`POST /auth/refresh`).
final tokenRefresherProvider = Provider<TokenRefresher>(
  (ref) => buildTokenRefresher(ref.watch(appConfigProvider)),
  name: 'tokenRefresherProvider',
);

/// `Dio` da aplicação, pronto para as camadas de dados.
final dioProvider = Provider<Dio>((ref) {
  final dio = buildAppDio(
    config: ref.watch(appConfigProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
    refresher: ref.watch(tokenRefresherProvider),
  );
  ref.onDispose(() => dio.close(force: true));
  return dio;
}, name: 'dioProvider');
