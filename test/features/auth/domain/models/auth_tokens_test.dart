import 'package:autouni_app/features/auth/domain/models/auth_tokens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthTokens.fromJson', () {
    test('lê o par de tokens', () {
      final tokens = AuthTokens.fromJson(const {
        'accessToken': 'access.jwt',
        'refreshToken': 'refresh.jwt',
      });

      expect(tokens.accessToken, 'access.jwt');
      expect(tokens.refreshToken, 'refresh.jwt');
    });

    test('lê direto da resposta de POST /auth/login, ignorando o user', () {
      final tokens = AuthTokens.fromJson(const {
        'accessToken': 'access.jwt',
        'refreshToken': 'refresh.jwt',
        'user': {'id': 'u1'},
      });

      expect(tokens.accessToken, 'access.jwt');
      expect(tokens.refreshToken, 'refresh.jwt');
    });

    test('falha quando falta um dos tokens', () {
      expect(
        () => AuthTokens.fromJson(const {'accessToken': 'access.jwt'}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('AuthTokens.toJson', () {
    test('faz o round-trip', () {
      const tokens = AuthTokens(accessToken: 'a', refreshToken: 'r');

      expect(tokens.toJson(), {'accessToken': 'a', 'refreshToken': 'r'});
      expect(AuthTokens.fromJson(tokens.toJson()), tokens);
    });
  });

  group('AuthTokens.refreshedWith', () {
    const current = AuthTokens(accessToken: 'old', refreshToken: 'refresh');

    test('troca só o access token quando o refresh não vem na resposta', () {
      // É o que POST /auth/refresh devolve hoje: { accessToken }.
      final next = current.refreshedWith(const {'accessToken': 'new'});

      expect(next.accessToken, 'new');
      expect(next.refreshToken, 'refresh');
    });

    test('adota o refresh token novo quando o backend o rotaciona', () {
      final next = current.refreshedWith(const {
        'accessToken': 'new',
        'refreshToken': 'rotated',
      });

      expect(next.accessToken, 'new');
      expect(next.refreshToken, 'rotated');
    });

    test('falha quando a resposta não traz access token', () {
      expect(
        () => current.refreshedWith(const {'refreshToken': 'rotated'}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('AuthTokens valor', () {
    test('igualdade por valor', () {
      expect(
        const AuthTokens(accessToken: 'a', refreshToken: 'r'),
        const AuthTokens(accessToken: 'a', refreshToken: 'r'),
      );
    });

    test('toString não vaza os tokens (logs, crash reports)', () {
      const tokens = AuthTokens(
        accessToken: 'segredo-access',
        refreshToken: 'segredo-refresh',
      );

      expect(tokens.toString(), isNot(contains('segredo-access')));
      expect(tokens.toString(), isNot(contains('segredo-refresh')));
      expect(tokens.toString(), contains('AuthTokens'));
    });
  });
}
