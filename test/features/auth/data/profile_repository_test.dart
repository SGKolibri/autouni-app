import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/network/auth_token_store.dart';
import 'package:autouni_app/core/network/dio_client.dart';
import 'package:autouni_app/core/network/token_refresher.dart';
import 'package:autouni_app/features/auth/data/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/fake_http_adapter.dart';

class _MockRefresher extends Mock implements TokenRefresher {}

const _userJson = {
  'id': 'u1',
  'email': 'ana@uni.br',
  'name': 'Ana Souza',
  'phone': '62999990000',
  'role': 'TECHNICIAN',
};

void main() {
  late Map<String, FakeResponse> responses;
  late FakeHttpAdapter adapter;
  late HttpProfileRepository repository;
  late _MockRefresher refresher;

  setUp(() {
    responses = {};
    refresher = _MockRefresher();
    adapter = FakeHttpAdapter(
      (options) =>
          responses['${options.method} ${options.path}'] ?? FakeResponse(404),
    );
    final dio = buildAppDio(
      config: AppConfig.forFlavor(Flavor.prod, apiBaseUrl: 'https://api.test'),
      tokenStore: InMemoryAuthTokenStore(accessToken: 'a', refreshToken: 'r'),
      refresher: refresher,
    )..httpClientAdapter = adapter;
    addTearDown(() => dio.close(force: true));
    repository = HttpProfileRepository(dio);
  });

  test('lê o perfil completo', () async {
    responses['GET /users/u1'] = FakeResponse(200, body: _userJson);

    final user = await repository.fetch('u1');

    expect(user.phone, '62999990000');
  });

  test('atualiza só nome e telefone', () async {
    responses['PUT /users/u1'] = FakeResponse(
      200,
      body: {..._userJson, 'name': 'Ana S.'},
    );

    final user = await repository.update('u1', name: ' Ana S. ', phone: null);

    expect(user.name, 'Ana S.');
    expect(adapter.requests.single.data, {'name': 'Ana S.', 'phone': null});
  });

  group('trocar senha', () {
    test('confere a senha atual pelo login (público) e grava a nova', () async {
      responses['POST /auth/login'] = FakeResponse(200, body: {});
      responses['PUT /users/u1'] = FakeResponse(200, body: _userJson);

      await repository.changePassword(
        userId: 'u1',
        email: 'ana@uni.br',
        currentPassword: 'antiga123',
        newPassword: 'novaSenha1',
      );

      final [login, put] = adapter.requests;
      expect(login.path, '/auth/login');
      expect(login.data, {'email': 'ana@uni.br', 'password': 'antiga123'});
      expect(login.headers, isNot(contains('Authorization')));
      expect(put.data, {'password': 'novaSenha1'});
    });

    test('senha atual errada não grava nada', () async {
      responses['POST /auth/login'] = FakeResponse(
        401,
        body: {'message': 'Credenciais inválidas'},
      );

      await expectLater(
        repository.changePassword(
          userId: 'u1',
          email: 'ana@uni.br',
          currentPassword: 'errada',
          newPassword: 'novaSenha1',
        ),
        throwsA(isA<WrongCurrentPasswordException>()),
      );
      expect(adapter.requests.where((r) => r.method == 'PUT'), isEmpty);
      verifyNever(() => refresher.refresh(any()));
    });

    test('outras falhas viram ApiException', () async {
      responses['POST /auth/login'] = FakeResponse(500);

      await expectLater(
        repository.changePassword(
          userId: 'u1',
          email: 'ana@uni.br',
          currentPassword: 'antiga123',
          newPassword: 'novaSenha1',
        ),
        throwsA(isA<ServerException>()),
      );
    });
  });
}
