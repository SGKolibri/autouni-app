import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/push/push_messaging.dart';
import 'package:autouni_app/shared/push/push_prompt_store.dart';
import 'package:autouni_app/shared/push/push_token_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_http_adapter.dart';

void main() {
  group('HttpPushTokenRepository', () {
    late FakeHttpAdapter adapter;
    late HttpPushTokenRepository repository;
    var status = 200;

    setUp(() {
      status = 200;
      adapter = FakeHttpAdapter(
        (_) => FakeResponse(status, body: status == 204 ? '' : {}),
      );
      repository = HttpPushTokenRepository(
        Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
      );
    });

    test('registra com POST /push/tokens {token, platform}', () async {
      await repository.register('fcm-1', PushPlatform.android);

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/push/tokens');
      expect(request.data, {'token': 'fcm-1', 'platform': 'ANDROID'});
    });

    test('remove com DELETE /push/tokens {token}', () async {
      status = 204;

      await repository.unregister('fcm-1');

      final request = adapter.requests.single;
      expect(request.method, 'DELETE');
      expect(request.path, '/push/tokens');
      expect(request.data, {'token': 'fcm-1'});
    });

    test('erros chegam como ApiException', () async {
      status = 400;

      await expectLater(
        repository.register('x', PushPlatform.ios),
        throwsA(isA<BadRequestException>()),
      );
    });
  });

  group('PushPromptStore', () {
    final when = DateTime.utc(2026, 10, 21, 12);

    test('em memória: guarda e limpa', () async {
      final store = InMemoryPushPromptStore();
      expect(await store.dismissedAt(), isNull);

      await store.setDismissedAt(when);
      expect(await store.dismissedAt(), when);

      await store.setDismissedAt(null);
      expect(await store.dismissedAt(), isNull);
    });

    group('seguro', () {
      setUp(() => FlutterSecureStorage.setMockInitialValues({}));

      test('sobrevive a um restart', () async {
        await SecurePushPromptStore().setDismissedAt(when);

        expect(await SecurePushPromptStore().dismissedAt(), when);
      });

      test('limpar apaga a chave', () async {
        final store = SecurePushPromptStore();
        await store.setDismissedAt(when);
        await store.setDismissedAt(null);

        expect(await store.dismissedAt(), isNull);
      });

      test('valor ilegível conta como nunca dispensado', () async {
        FlutterSecureStorage.setMockInitialValues({
          SecurePushPromptStore.dismissedAtKey: 'ontem',
        });

        expect(await SecurePushPromptStore().dismissedAt(), isNull);
      });
    });
  });
}
