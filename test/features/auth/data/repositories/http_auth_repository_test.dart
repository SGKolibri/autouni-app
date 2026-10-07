import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/network/auth_token_store.dart';
import 'package:autouni_app/core/network/dio_client.dart';
import 'package:autouni_app/core/network/token_refresher.dart';
import 'package:autouni_app/features/auth/data/repositories/http_auth_repository.dart';
import 'package:autouni_app/features/auth/domain/models/user_role.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/fake_http_adapter.dart';
import '../../../../support/fake_jwt.dart';

class _MockTokenRefresher extends Mock implements TokenRefresher {}

/// Resposta de POST /auth/login como o backend devolve
/// (`{ user, accessToken, refreshToken }`).
const _loginBody = <String, dynamic>{
  'user': {
    'id': 'uuid-user-123',
    'email': 'joao@example.com',
    'name': 'João Silva',
    'role': 'COORDINATOR',
    'createdAt': '2025-01-01T00:00:00.000Z',
  },
  'accessToken': 'access-1',
  'refreshToken': 'refresh-1',
};

void main() {
  late InMemoryAuthTokenStore tokenStore;
  late _MockTokenRefresher refresher;

  /// Repositório sobre o `Dio` real da aplicação (com os interceptors), para
  /// cobrir também a rota pública e a tradução de erros.
  (HttpAuthRepository, FakeHttpAdapter) build(FakeResponse response) {
    final adapter = FakeHttpAdapter.always(response);
    final dio = buildAppDio(
      config: AppConfig.forFlavor(Flavor.prod, apiBaseUrl: 'https://api.test'),
      tokenStore: tokenStore,
      refresher: refresher,
    )..httpClientAdapter = adapter;
    addTearDown(() => dio.close(force: true));
    return (HttpAuthRepository(dio: dio, tokenStore: tokenStore), adapter);
  }

  setUp(() {
    tokenStore = InMemoryAuthTokenStore();
    refresher = _MockTokenRefresher();
  });

  group('HttpAuthRepository.login', () {
    test('POST /auth/login com e-mail e senha e devolve o usuário', () async {
      final (repository, adapter) = build(FakeResponse(200, body: _loginBody));

      final user = await repository.login(
        email: 'joao@example.com',
        password: 'secret123',
      );

      expect(user.id, 'uuid-user-123');
      expect(user.email, 'joao@example.com');
      expect(user.name, 'João Silva');
      expect(user.role, UserRole.coordinator);

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/auth/login');
      expect(request.data, {
        'email': 'joao@example.com',
        'password': 'secret123',
      });
    });

    test('guarda os tokens da resposta no AuthTokenStore', () async {
      final (repository, _) = build(FakeResponse(200, body: _loginBody));

      await repository.login(email: 'joao@example.com', password: 'secret123');

      expect(await tokenStore.readAccessToken(), 'access-1');
      expect(await tokenStore.readRefreshToken(), 'refresh-1');
    });

    test('apara espaços do e-mail, mas não mexe na senha', () async {
      final (repository, adapter) = build(FakeResponse(200, body: _loginBody));

      await repository.login(
        email: '  joao@example.com ',
        password: ' secret123 ',
      );

      expect(adapter.requests.single.data, {
        'email': 'joao@example.com',
        'password': ' secret123 ',
      });
    });

    test('é rota pública: não envia o token de uma sessão anterior', () async {
      await tokenStore.saveTokens(accessToken: 'stale', refreshToken: 'old-r');
      final (repository, adapter) = build(FakeResponse(200, body: _loginBody));

      await repository.login(email: 'joao@example.com', password: 'secret123');

      expect(adapter.requests.single.headers, isNot(contains('Authorization')));
    });

    test('credenciais inválidas (401) viram UnauthorizedException, sem '
        'tentar refresh nem tocar na sessão guardada', () async {
      await tokenStore.saveTokens(accessToken: 'stale', refreshToken: 'old-r');
      final (repository, adapter) = build(
        FakeResponse(
          401,
          body: {
            'statusCode': 401,
            'message': 'Credenciais inválidas',
            'error': 'Unauthorized',
          },
        ),
      );

      await expectLater(
        repository.login(email: 'joao@example.com', password: 'errada'),
        throwsA(
          isA<UnauthorizedException>().having(
            (e) => e.message,
            'message',
            'Credenciais inválidas',
          ),
        ),
      );

      expect(adapter.callCount, 1);
      verifyNever(() => refresher.refresh(any()));
      expect(await tokenStore.readAccessToken(), 'stale');
      expect(await tokenStore.readRefreshToken(), 'old-r');
    });

    test('payload rejeitado (400) vira BadRequestException com as mensagens '
        'de validação', () async {
      final (repository, _) = build(
        FakeResponse(
          400,
          body: {
            'statusCode': 400,
            'message': ['email must be an email'],
            'error': 'Bad Request',
          },
        ),
      );

      await expectLater(
        repository.login(email: 'nao-e-email', password: 'secret123'),
        throwsA(
          isA<BadRequestException>().having(
            (e) => e.message,
            'message',
            'email must be an email',
          ),
        ),
      );
    });

    test('erro do servidor (500) vira ServerException', () async {
      final (repository, _) = build(FakeResponse(500));

      await expectLater(
        repository.login(email: 'joao@example.com', password: 'secret123'),
        throwsA(isA<ServerException>()),
      );
      expect(await tokenStore.readAccessToken(), isNull);
    });

    test('falha de conexão vira NetworkException', () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeHttpAdapter(
          (options) => throw DioException.connectionError(
            requestOptions: options,
            reason: 'sem rede',
          ),
        );
      final repository = HttpAuthRepository(dio: dio, tokenStore: tokenStore);

      await expectLater(
        repository.login(email: 'joao@example.com', password: 'secret123'),
        throwsA(isA<NetworkException>()),
      );
    });

    for (final (description, body) in <(String, Object?)>[
      ('sem user', {'accessToken': 'a', 'refreshToken': 'r'}),
      ('sem tokens', {'user': _loginBody['user']}),
      (
        'com user incompleto',
        {
          'user': {'id': 'u1'},
          'accessToken': 'a',
          'refreshToken': 'r',
        },
      ),
      ('que não é um objeto', ['ok']),
    ]) {
      test('resposta 200 $description vira UnexpectedResponseException e '
          'não guarda tokens', () async {
        final (repository, _) = build(FakeResponse(200, body: body));

        await expectLater(
          repository.login(email: 'joao@example.com', password: 'secret123'),
          throwsA(isA<UnexpectedResponseException>()),
        );
        expect(await tokenStore.readAccessToken(), isNull);
        expect(await tokenStore.readRefreshToken(), isNull);
      });
    }
  });

  group('HttpAuthRepository.restoreSession', () {
    final now = DateTime.utc(2026, 10, 7, 12);

    String token({
      Duration expiresIn = const Duration(days: 7),
      String name = 'João Silva',
      String role = 'COORDINATOR',
    }) => fakeJwt({
      'sub': 'uuid-user-123',
      'email': 'joao@example.com',
      'name': name,
      'role': role,
      'exp': jwtSeconds(now.add(expiresIn)),
    });

    /// Restaurar a sessão é local: qualquer chamada HTTP quebra o teste.
    HttpAuthRepository repository() {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = FakeHttpAdapter(
          (options) => fail('não deveria chamar ${options.path}'),
        );
      return HttpAuthRepository(
        dio: dio,
        tokenStore: tokenStore,
        now: () => now,
      );
    }

    test('sem tokens guardados não há sessão', () async {
      expect(await repository().restoreSession(), isNull);
    });

    test(
      'reconstrói o usuário a partir das claims do token guardado',
      () async {
        await tokenStore.saveTokens(
          accessToken: token(expiresIn: const Duration(minutes: 15)),
          refreshToken: token(),
        );

        final user = await repository().restoreSession();

        expect(user?.id, 'uuid-user-123');
        expect(user?.email, 'joao@example.com');
        expect(user?.name, 'João Silva');
        expect(user?.role, UserRole.coordinator);
      },
    );

    test('access token expirado não impede: o refresh renova depois', () async {
      await tokenStore.saveTokens(
        accessToken: token(expiresIn: const Duration(minutes: -30)),
        refreshToken: token(),
      );

      expect(await repository().restoreSession(), isNotNull);
      expect(await tokenStore.readRefreshToken(), isNotNull);
    });

    test('prefere as claims do access token, que é o mais recente', () async {
      await tokenStore.saveTokens(
        accessToken: token(name: 'João S. Atualizado', role: 'ADMIN'),
        refreshToken: token(),
      );

      final user = await repository().restoreSession();

      expect(user?.name, 'João S. Atualizado');
      expect(user?.role, UserRole.admin);
    });

    test(
      'usa as claims do refresh token se o access token for ilegível',
      () async {
        await tokenStore.saveTokens(accessToken: 'lixo', refreshToken: token());

        expect((await repository().restoreSession())?.id, 'uuid-user-123');
      },
    );

    test('papel desconhecido cai em VIEWER', () async {
      await tokenStore.saveTokens(
        accessToken: token(role: 'SUPERUSER'),
        refreshToken: token(role: 'SUPERUSER'),
      );

      expect((await repository().restoreSession())?.role, UserRole.viewer);
    });

    test('refresh token expirado encerra a sessão e limpa os tokens', () async {
      await tokenStore.saveTokens(
        accessToken: token(),
        refreshToken: token(expiresIn: const Duration(seconds: -1)),
      );

      expect(await repository().restoreSession(), isNull);
      expect(await tokenStore.readAccessToken(), isNull);
      expect(await tokenStore.readRefreshToken(), isNull);
    });

    test('refresh token ilegível encerra a sessão e limpa os tokens', () async {
      await tokenStore.saveTokens(accessToken: token(), refreshToken: 'lixo');

      expect(await repository().restoreSession(), isNull);
      expect(await tokenStore.readRefreshToken(), isNull);
    });

    test('claims sem identificação do usuário encerram a sessão', () async {
      final anonymous = fakeJwt({
        'exp': jwtSeconds(now.add(const Duration(days: 1))),
      });
      await tokenStore.saveTokens(
        accessToken: anonymous,
        refreshToken: anonymous,
      );

      expect(await repository().restoreSession(), isNull);
      expect(await tokenStore.readRefreshToken(), isNull);
    });
  });
}
