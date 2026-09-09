import 'package:autouni_app/core/network/auth_token_store.dart';
import 'package:autouni_app/core/network/interceptors/auth_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

void main() {
  late Dio dio;
  late FakeHttpAdapter adapter;
  late InMemoryAuthTokenStore store;

  setUp(() {
    store = InMemoryAuthTokenStore();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    adapter = FakeHttpAdapter.always(FakeResponse(200));
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(store));
  });

  test('adiciona Authorization: Bearer quando há access token', () async {
    await store.saveTokens(accessToken: 'tok-123', refreshToken: 'r');

    await dio.get<void>('/me');

    expect(adapter.requests.single.headers['Authorization'], 'Bearer tok-123');
  });

  test('não adiciona header quando não há token', () async {
    await dio.get<void>('/public');

    expect(
      adapter.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });

  test('respeita skipAuth para rotas públicas (login/refresh)', () async {
    await store.saveTokens(accessToken: 'tok-123', refreshToken: 'r');

    await dio.post<void>(
      '/auth/login',
      options: Options(extra: AuthInterceptor.skipAuth),
    );

    expect(
      adapter.requests.single.headers.containsKey('Authorization'),
      isFalse,
    );
  });

  test('não sobrescreve um Authorization já definido na request', () async {
    await store.saveTokens(accessToken: 'tok-123', refreshToken: 'r');

    await dio.get<void>(
      '/me',
      options: Options(headers: {'Authorization': 'Bearer manual'}),
    );

    expect(adapter.requests.single.headers['Authorization'], 'Bearer manual');
  });
}
