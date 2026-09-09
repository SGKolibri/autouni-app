import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/network/auth_token_store.dart';
import 'package:autouni_app/core/network/interceptors/auth_interceptor.dart';
import 'package:autouni_app/core/network/interceptors/error_interceptor.dart';
import 'package:autouni_app/core/network/interceptors/refresh_interceptor.dart';
import 'package:autouni_app/core/network/token_refresher.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/fake_http_adapter.dart';

class _MockTokenRefresher extends Mock implements TokenRefresher {}

void main() {
  late Dio dio;
  late FakeHttpAdapter adapter;
  late InMemoryAuthTokenStore store;
  late _MockTokenRefresher refresher;

  /// Adapter que devolve 401 enquanto o Bearer for [staleToken] e 200 quando
  /// a request chegar com qualquer outro token (ou seja, após o refresh).
  FakeHttpAdapter guardedBy(String staleToken) {
    return FakeHttpAdapter((options) {
      if (options.path == '/protected') {
        final auth = options.headers['Authorization'];
        if (auth == 'Bearer $staleToken') {
          return FakeResponse(401, body: {'message': 'expirado'});
        }
        return FakeResponse(200, body: {'ok': true});
      }
      return FakeResponse(200);
    });
  }

  void wire() {
    dio.httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(store));
    dio.interceptors.add(
      RefreshInterceptor(tokenStore: store, refresher: refresher, retrier: dio),
    );
    dio.interceptors.add(ErrorInterceptor());
  }

  setUp(() {
    store = InMemoryAuthTokenStore(accessToken: 'stale', refreshToken: 'r0');
    refresher = _MockTokenRefresher();
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    adapter = guardedBy('stale');
  });

  test('em 401 renova o token, regrava e repete a request original', () async {
    when(() => refresher.refresh('r0')).thenAnswer(
      (_) async => const TokenPair(accessToken: 'fresh', refreshToken: 'r1'),
    );
    wire();

    final response = await dio.get<Map<String, dynamic>>('/protected');

    expect(response.statusCode, 200);
    expect(response.data, {'ok': true});
    expect(await store.readAccessToken(), 'fresh');
    expect(await store.readRefreshToken(), 'r1');
    verify(() => refresher.refresh('r0')).called(1);
  });

  test(
    'refresh malsucedido limpa a sessão e emite UnauthorizedException',
    () async {
      when(() => refresher.refresh(any())).thenAnswer((_) async => null);
      wire();

      await expectLater(
        dio.get<void>('/protected'),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<UnauthorizedException>(),
          ),
        ),
      );
      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);
    },
  );

  test('sem refresh token não chama o refresher e derruba a sessão', () async {
    store = InMemoryAuthTokenStore(accessToken: 'stale');
    wire();

    await expectLater(
      dio.get<void>('/protected'),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'error',
          isA<UnauthorizedException>(),
        ),
      ),
    );
    verifyNever(() => refresher.refresh(any()));
  });

  test('não tenta renovar em requests marcadas como skipAuth', () async {
    adapter = FakeHttpAdapter.always(
      FakeResponse(401, body: {'message': 'no'}),
    );
    wire();

    await expectLater(
      dio.post<void>(
        '/auth/refresh',
        options: Options(extra: AuthInterceptor.skipAuth),
      ),
      throwsA(isA<DioException>()),
    );
    verifyNever(() => refresher.refresh(any()));
  });

  test('só renova uma vez para várias requests concorrentes com 401', () async {
    when(() => refresher.refresh('r0')).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return const TokenPair(accessToken: 'fresh', refreshToken: 'r1');
    });
    wire();

    final results = await Future.wait([
      dio.get<Map<String, dynamic>>('/protected'),
      dio.get<Map<String, dynamic>>('/protected'),
      dio.get<Map<String, dynamic>>('/protected'),
    ]);

    expect(results.map((r) => r.statusCode), everyElement(200));
    verify(() => refresher.refresh('r0')).called(1);
  });

  test('desiste se a request repetida ainda receber 401', () async {
    // O adapter responde 401 para qualquer token -> o retry também falha.
    adapter = FakeHttpAdapter.always(
      FakeResponse(401, body: {'message': 'no'}),
    );
    when(() => refresher.refresh(any())).thenAnswer(
      (_) async => const TokenPair(accessToken: 'fresh', refreshToken: 'r1'),
    );
    wire();

    await expectLater(
      dio.get<void>('/protected'),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'error',
          isA<UnauthorizedException>(),
        ),
      ),
    );
    verify(() => refresher.refresh(any())).called(1);
  });
}
