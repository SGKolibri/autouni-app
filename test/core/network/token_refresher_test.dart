import 'package:autouni_app/core/network/token_refresher.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_adapter.dart';

void main() {
  group('HttpTokenRefresher', () {
    test(
      'POST /auth/refresh com o refresh token e devolve o novo par',
      () async {
        final adapter = FakeHttpAdapter(
          (_) => FakeResponse(
            200,
            body: {'accessToken': 'new-a', 'refreshToken': 'new-r'},
          ),
        );
        final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter;

        final result = await HttpTokenRefresher(dio).refresh('old-r');

        expect(
          result,
          const TokenPair(accessToken: 'new-a', refreshToken: 'new-r'),
        );
        final request = adapter.requests.single;
        expect(request.path, '/auth/refresh');
        expect(request.method, 'POST');
        expect((request.data as Map)['refreshToken'], 'old-r');
      },
    );

    test('devolve null quando o refresh é rejeitado', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeHttpAdapter.always(FakeResponse(401));

      expect(await HttpTokenRefresher(dio).refresh('old-r'), isNull);
    });

    test('resposta só com accessToken (contrato do backend) mantém o refresh '
        'token em uso', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeHttpAdapter.always(
          FakeResponse(200, body: {'accessToken': 'new-a'}),
        );

      expect(
        await HttpTokenRefresher(dio).refresh('old-r'),
        const TokenPair(accessToken: 'new-a', refreshToken: 'old-r'),
      );
    });

    test('devolve null quando a resposta não traz accessToken', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeHttpAdapter.always(
          FakeResponse(200, body: {'refreshToken': 'new-r'}),
        );

      expect(await HttpTokenRefresher(dio).refresh('old-r'), isNull);
    });

    test('erro do servidor (5xx) não é recusa: propaga a falha', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeHttpAdapter.always(FakeResponse(503));

      await expectLater(
        HttpTokenRefresher(dio).refresh('old-r'),
        throwsA(isA<DioException>()),
      );
    });

    test('falha de conexão não é recusa: propaga a falha', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeHttpAdapter(
          (options) => throw DioException.connectionError(
            requestOptions: options,
            reason: 'sem rede',
          ),
        );

      await expectLater(
        HttpTokenRefresher(dio).refresh('old-r'),
        throwsA(isA<DioException>()),
      );
    });
  });
}
