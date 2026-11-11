import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config_provider.dart';
import '../session/session_events.dart';
import 'auth_token_store.dart';
import 'dio_client.dart';
import 'token_refresher.dart';

/// Guarda dos tokens de sessão.
///
/// Default volátil ([InMemoryAuthTokenStore]), seguro para testes; o
/// bootstrap (`buildAppRoot`) sobrescreve este provider com o
/// `SecureAuthTokenStore`, que persiste a sessão no armazenamento seguro.
final authTokenStoreProvider = Provider<AuthTokenStore>(
  (ref) => InMemoryAuthTokenStore(),
  name: 'authTokenStoreProvider',
);

/// Transporte HTTP de todos os `Dio` do app. `null` = o padrão do `dio`
/// (rede de verdade). Os testes de ponta a ponta trocam por um backend em
/// memória, mantendo interceptors, repositórios e telas reais.
final httpClientAdapterProvider = Provider<HttpClientAdapter?>(
  (ref) => null,
  name: 'httpClientAdapterProvider',
);

/// Serviço de renovação de token (`POST /auth/refresh`).
final tokenRefresherProvider = Provider<TokenRefresher>((ref) {
  final adapter = ref.watch(httpClientAdapterProvider);
  final dio = buildRefreshDio(ref.watch(appConfigProvider));
  if (adapter != null) dio.httpClientAdapter = adapter;
  return HttpTokenRefresher(dio);
}, name: 'tokenRefresherProvider');

/// `Dio` da aplicação, pronto para as camadas de dados.
final dioProvider = Provider<Dio>((ref) {
  final dio = buildAppDio(
    config: ref.watch(appConfigProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
    refresher: ref.watch(tokenRefresherProvider),
    onSessionExpired: ref.watch(sessionEventsProvider).notifyExpired,
  );
  final adapter = ref.watch(httpClientAdapterProvider);
  if (adapter != null) dio.httpClientAdapter = adapter;
  ref.onDispose(() => dio.close(force: true));
  return dio;
}, name: 'dioProvider');
