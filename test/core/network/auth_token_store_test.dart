import 'package:autouni_app/core/network/auth_token_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InMemoryAuthTokenStore', () {
    test('começa vazio', () async {
      final store = InMemoryAuthTokenStore();

      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);
    });

    test('guarda e lê o par de tokens', () async {
      final store = InMemoryAuthTokenStore();

      await store.saveTokens(accessToken: 'a1', refreshToken: 'r1');

      expect(await store.readAccessToken(), 'a1');
      expect(await store.readRefreshToken(), 'r1');
    });

    test('clear apaga os dois tokens', () async {
      final store = InMemoryAuthTokenStore()
        ..saveTokens(accessToken: 'a1', refreshToken: 'r1');

      await store.clear();

      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);
    });

    test('seed injeta tokens iniciais', () async {
      final store = InMemoryAuthTokenStore(
        accessToken: 'seed-a',
        refreshToken: 'seed-r',
      );

      expect(await store.readAccessToken(), 'seed-a');
      expect(await store.readRefreshToken(), 'seed-r');
    });
  });

  group('TokenPair', () {
    test('fromJson aceita as chaves do backend', () {
      final pair = TokenPair.fromJson(const {
        'accessToken': 'a',
        'refreshToken': 'r',
      });

      expect(pair.accessToken, 'a');
      expect(pair.refreshToken, 'r');
    });

    test('fromJson aceita snake_case', () {
      final pair = TokenPair.fromJson(const {
        'access_token': 'a',
        'refresh_token': 'r',
      });

      expect(pair.accessToken, 'a');
      expect(pair.refreshToken, 'r');
    });

    test('igualdade por valor', () {
      expect(
        const TokenPair(accessToken: 'a', refreshToken: 'r'),
        const TokenPair(accessToken: 'a', refreshToken: 'r'),
      );
    });
  });
}
