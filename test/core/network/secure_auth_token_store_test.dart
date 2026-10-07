import 'package:autouni_app/core/network/secure_auth_token_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

const _accessKey = SecureAuthTokenStore.accessTokenKey;
const _refreshKey = SecureAuthTokenStore.refreshTokenKey;

void main() {
  group('SecureAuthTokenStore (armazenamento falso do plugin)', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('começa vazio', () async {
      final store = SecureAuthTokenStore();

      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);
    });

    test('grava o par no armazenamento seguro', () async {
      final store = SecureAuthTokenStore();

      await store.saveTokens(accessToken: 'a1', refreshToken: 'r1');

      expect(await store.readAccessToken(), 'a1');
      expect(await store.readRefreshToken(), 'r1');
      expect(await const FlutterSecureStorage().readAll(), {
        _accessKey: 'a1',
        _refreshKey: 'r1',
      });
    });

    test(
      'a sessão sobrevive a um restart (nova instância lê do disco)',
      () async {
        await SecureAuthTokenStore().saveTokens(
          accessToken: 'a1',
          refreshToken: 'r1',
        );

        final afterRestart = SecureAuthTokenStore();

        expect(await afterRestart.readAccessToken(), 'a1');
        expect(await afterRestart.readRefreshToken(), 'r1');
      },
    );

    test('clear apaga os tokens da memória e do disco', () async {
      final store = SecureAuthTokenStore();
      await store.saveTokens(accessToken: 'a1', refreshToken: 'r1');

      await store.clear();

      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
    });

    test('clear só apaga as chaves de sessão', () async {
      FlutterSecureStorage.setMockInitialValues({
        _accessKey: 'a1',
        _refreshKey: 'r1',
        'outra.chave': 'fica',
      });

      await SecureAuthTokenStore().clear();

      expect(await const FlutterSecureStorage().readAll(), {
        'outra.chave': 'fica',
      });
    });
  });

  group('SecureAuthTokenStore (plugin mockado)', () {
    late _MockSecureStorage storage;

    PlatformException keystoreFailure() =>
        PlatformException(code: 'keystore', message: 'chave corrompida');

    setUp(() {
      storage = _MockSecureStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenAnswer((_) async => null);
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async {});
      when(() => storage.delete(key: any(named: 'key')))
          .thenAnswer((_) async {});
    });

    test('lê do plugin uma única vez e depois serve da memória', () async {
      when(() => storage.read(key: _accessKey)).thenAnswer((_) async => 'a1');
      when(() => storage.read(key: _refreshKey)).thenAnswer((_) async => 'r1');
      final store = SecureAuthTokenStore(storage);

      await Future.wait([store.readAccessToken(), store.readRefreshToken()]);
      expect(await store.readAccessToken(), 'a1');
      expect(await store.readRefreshToken(), 'r1');

      verify(() => storage.read(key: _accessKey)).called(1);
      verify(() => storage.read(key: _refreshKey)).called(1);
    });

    test('saveTokens não precisa ler o disco para servir o par novo', () async {
      final store = SecureAuthTokenStore(storage);

      await store.saveTokens(accessToken: 'a2', refreshToken: 'r2');

      expect(await store.readAccessToken(), 'a2');
      verify(() => storage.write(key: _accessKey, value: 'a2')).called(1);
      verify(() => storage.write(key: _refreshKey, value: 'r2')).called(1);
      verifyNever(() => storage.read(key: any(named: 'key')));
    });

    test('falha de leitura vira sessão vazia e descarta o que estava '
        'guardado', () async {
      when(() => storage.read(key: any(named: 'key')))
          .thenThrow(keystoreFailure());
      final store = SecureAuthTokenStore(storage);

      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);
      verify(() => storage.delete(key: _accessKey)).called(1);
      verify(() => storage.delete(key: _refreshKey)).called(1);
    });

    test('falha de escrita mantém a sessão em memória', () async {
      when(
        () => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        ),
      ).thenThrow(keystoreFailure());
      final store = SecureAuthTokenStore(storage);

      await store.saveTokens(accessToken: 'a1', refreshToken: 'r1');

      expect(await store.readAccessToken(), 'a1');
      expect(await store.readRefreshToken(), 'r1');
    });

    test('falha ao apagar ainda encerra a sessão em memória', () async {
      when(() => storage.delete(key: any(named: 'key')))
          .thenThrow(keystoreFailure());
      final store = SecureAuthTokenStore(storage);
      await store.saveTokens(accessToken: 'a1', refreshToken: 'r1');

      await store.clear();

      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);
    });
  });
}
