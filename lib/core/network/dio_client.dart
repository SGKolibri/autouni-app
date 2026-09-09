import 'package:dio/dio.dart';

import '../config/app_config.dart';
import 'auth_token_store.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/error_interceptor.dart';
import 'interceptors/refresh_interceptor.dart';
import 'token_refresher.dart';

BaseOptions _baseOptions(AppConfig config) => BaseOptions(
  baseUrl: config.apiBaseUrl,
  connectTimeout: config.connectTimeout,
  receiveTimeout: config.receiveTimeout,
  sendTimeout: config.connectTimeout,
  contentType: Headers.jsonContentType,
  responseType: ResponseType.json,
);

/// `Dio` da aplicação, com a cadeia de interceptors montada na ordem
/// **auth → refresh → error** (+ log verboso fora de produção).
Dio buildAppDio({
  required AppConfig config,
  required AuthTokenStore tokenStore,
  required TokenRefresher refresher,
}) {
  final dio = Dio(_baseOptions(config));
  dio.interceptors.addAll([
    AuthInterceptor(tokenStore),
    RefreshInterceptor(
      tokenStore: tokenStore,
      refresher: refresher,
      retrier: dio,
    ),
    const ErrorInterceptor(),
    if (config.enableVerboseLogging)
      LogInterceptor(requestBody: true, responseBody: true),
  ]);
  return dio;
}

/// `Dio` cru (sem os interceptors da aplicação) para o fluxo de refresh —
/// senão um 401 no próprio `/auth/refresh` dispararia refresh recursivo.
Dio buildRefreshDio(AppConfig config) => Dio(_baseOptions(config));

/// Monta o [TokenRefresher] HTTP padrão a partir da config.
TokenRefresher buildTokenRefresher(AppConfig config) =>
    HttpTokenRefresher(buildRefreshDio(config));
