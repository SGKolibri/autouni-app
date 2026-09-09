import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:autouni_app/core/network/auth_token_store.dart';
import 'package:autouni_app/core/network/dio_client.dart';
import 'package:autouni_app/core/network/interceptors/auth_interceptor.dart';
import 'package:autouni_app/core/network/interceptors/error_interceptor.dart';
import 'package:autouni_app/core/network/interceptors/refresh_interceptor.dart';
import 'package:autouni_app/core/network/token_refresher.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTokenRefresher extends Mock implements TokenRefresher {}

void main() {
  final config = AppConfig.forFlavor(Flavor.prod);

  Dio build() => buildAppDio(
    config: config,
    tokenStore: InMemoryAuthTokenStore(),
    refresher: _MockTokenRefresher(),
  );

  test('usa baseUrl e timeouts da AppConfig', () {
    final dio = build();

    expect(dio.options.baseUrl, config.apiBaseUrl);
    expect(dio.options.connectTimeout, config.connectTimeout);
    expect(dio.options.receiveTimeout, config.receiveTimeout);
  });

  test('pede e aceita JSON por padrão', () {
    final dio = build();

    expect(dio.options.contentType, Headers.jsonContentType);
    expect(dio.options.responseType, ResponseType.json);
  });

  test('registra os interceptors na ordem auth -> refresh -> error', () {
    final dio = build();

    final types = dio.interceptors
        .whereType<Interceptor>()
        .map((i) => i.runtimeType)
        .toList();
    final authIdx = types.indexOf(AuthInterceptor);
    final refreshIdx = types.indexOf(RefreshInterceptor);
    final errorIdx = types.indexOf(ErrorInterceptor);

    expect(authIdx, isNonNegative);
    expect(refreshIdx, greaterThan(authIdx));
    expect(errorIdx, greaterThan(refreshIdx));
  });

  test('buildRefreshDio não carrega os interceptors da aplicação', () {
    final dio = buildRefreshDio(config);

    expect(dio.options.baseUrl, config.apiBaseUrl);
    expect(dio.interceptors.whereType<AuthInterceptor>(), isEmpty);
    expect(dio.interceptors.whereType<RefreshInterceptor>(), isEmpty);
  });
}
