import 'package:autouni_app/core/network/api_client.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/network/interceptors/error_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_adapter.dart';

void main() {
  Dio dioWith(FakeHttpAdapter adapter, {bool withErrorInterceptor = true}) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    if (withErrorInterceptor) dio.interceptors.add(const ErrorInterceptor());
    return dio;
  }

  group('ApiClient', () {
    test('getJson devolve o corpo e repassa a query', () async {
      final adapter = FakeHttpAdapter.always(FakeResponse(200, body: [1, 2]));

      final json = await dioWith(adapter)
          .getJson('/devices', query: {'status': 'ON'});

      expect(json, [1, 2]);
      expect(adapter.requests.single.queryParameters, {'status': 'ON'});
    });

    test('postJson envia o corpo', () async {
      final adapter = FakeHttpAdapter.always(FakeResponse(200, body: {}));

      await dioWith(adapter).postJson('/x', data: {'a': 1});

      expect(adapter.requests.single.method, 'POST');
      expect(adapter.requests.single.data, {'a': 1});
    });

    for (final (method, call) in <(String, Future<Object?> Function(Dio))>[
      ('PUT', (dio) => dio.putJson('/x', data: {'a': 1})),
      ('PATCH', (dio) => dio.patchJson('/x', data: {'a': 1})),
      ('DELETE', (dio) => dio.deleteJson('/x', data: {'a': 1})),
    ]) {
      test('${method.toLowerCase()}Json envia o corpo com $method', () async {
        final adapter = FakeHttpAdapter.always(FakeResponse(200, body: {}));

        await call(dioWith(adapter));

        expect(adapter.requests.single.method, method);
        expect(adapter.requests.single.data, {'a': 1});
      });
    }

    test('deleteJson aceita 204 sem corpo', () async {
      final adapter = FakeHttpAdapter.always(FakeResponse(204, body: ''));

      expect(await dioWith(adapter).deleteJson('/x'), anyOf(isNull, ''));
    });

    test('erros chegam como ApiException (com o interceptor)', () async {
      final dio = dioWith(FakeHttpAdapter.always(FakeResponse(404)));

      await expectLater(dio.getJson('/x'), throwsA(isA<NotFoundException>()));
    });

    test('erros chegam como ApiException (sem o interceptor)', () async {
      final dio = dioWith(
        FakeHttpAdapter.always(FakeResponse(500)),
        withErrorInterceptor: false,
      );

      await expectLater(dio.postJson('/x'), throwsA(isA<ServerException>()));
    });
  });

  group('parse', () {
    String name(Map<String, dynamic> json) => json['name'] as String;

    test('parseObject e parseList leem o formato esperado', () {
      expect(parseObject({'name': 'a'}, name), 'a');
      expect(
        parseList([
          {'name': 'a'},
          {'name': 'b'},
        ], name),
        ['a', 'b'],
      );
    });

    for (final (label, json) in [
      ('não é objeto', [1]),
      ('campo ausente', <String, dynamic>{}),
      ('tipo errado', {'name': 1}),
    ]) {
      test('parseObject: $label vira UnexpectedResponseException', () {
        expect(
          () => parseObject(json, name),
          throwsA(isA<UnexpectedResponseException>()),
        );
      });
    }

    test('parseList: não é lista vira UnexpectedResponseException', () {
      expect(
        () => parseList({'name': 'a'}, name),
        throwsA(isA<UnexpectedResponseException>()),
      );
    });
  });
}
