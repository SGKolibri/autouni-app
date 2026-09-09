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
  });
}
