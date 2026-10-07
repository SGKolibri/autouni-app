import 'dart:async';

import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/features/auth/data/auth_data_providers.dart';
import 'package:autouni_app/features/auth/domain/models/user.dart';
import 'package:autouni_app/features/auth/domain/models/user_role.dart';
import 'package:autouni_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:autouni_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _user = User(
  id: 'uuid-user-123',
  email: 'joao@example.com',
  name: 'João Silva',
  role: UserRole.coordinator,
);

void main() {
  late _MockAuthRepository repository;
  late ProviderContainer container;

  When<Future<User>> whenLogin() => when(
    () => repository.login(
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  );

  Future<void> login() => container
      .read(authControllerProvider.notifier)
      .login(email: 'joao@example.com', password: 'secret123');

  setUp(() {
    repository = _MockAuthRepository();
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
  });

  test('sem sessão guardada começa deslogado', () async {
    expect(await container.read(authControllerProvider.future), isNull);
    expect(container.read(authControllerProvider).isLoading, isFalse);
    verify(() => repository.restoreSession()).called(1);
  });

  test('restaura o usuário da sessão guardada ao iniciar', () async {
    when(() => repository.restoreSession()).thenAnswer((_) async => _user);

    expect(container.read(authControllerProvider).isLoading, isTrue);
    expect(await container.read(authControllerProvider.future), _user);
    expect(container.read(authControllerProvider).value, _user);
  });

  test('login pedido durante a restauração espera ela terminar e '
      'prevalece', () async {
    final restoring = Completer<User?>();
    when(() => repository.restoreSession()).thenAnswer((_) => restoring.future);
    whenLogin().thenAnswer((_) async => _user);

    final call = login();
    await Future<void>.delayed(Duration.zero);
    verifyNever(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );

    restoring.complete(null);
    await call;

    expect(container.read(authControllerProvider).value, _user);
  });

  test('login com sucesso expõe o usuário autenticado', () async {
    whenLogin().thenAnswer((_) async => _user);

    await login();

    expect(container.read(authControllerProvider).value, _user);
    verify(
      () => repository.login(email: 'joao@example.com', password: 'secret123'),
    ).called(1);
  });

  test('fica em carregamento enquanto o login está em andamento', () async {
    final pending = Completer<User>();
    whenLogin().thenAnswer((_) => pending.future);
    await container.read(authControllerProvider.future);

    final call = login();

    expect(container.read(authControllerProvider).isLoading, isTrue);

    pending.complete(_user);
    await call;

    expect(container.read(authControllerProvider).isLoading, isFalse);
    expect(container.read(authControllerProvider).value, _user);
  });

  test('login com erro expõe a ApiException e segue sem usuário', () async {
    const failure = UnauthorizedException(message: 'Credenciais inválidas');
    whenLogin().thenThrow(failure);

    await login();

    final state = container.read(authControllerProvider);
    expect(state.hasError, isTrue);
    expect(state.error, same(failure));
    expect(state.value, isNull);
  });

  test('permite tentar de novo depois de um erro', () async {
    whenLogin().thenThrow(const NetworkException());
    await login();

    whenLogin().thenAnswer((_) async => _user);
    await login();

    final state = container.read(authControllerProvider);
    expect(state.hasError, isFalse);
    expect(state.value, _user);
  });

  test('ignora um segundo login enquanto o primeiro não terminou', () async {
    final pending = Completer<User>();
    whenLogin().thenAnswer((_) => pending.future);
    await container.read(authControllerProvider.future);

    final first = login();
    final second = login();
    pending.complete(_user);
    await Future.wait([first, second]);

    verify(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).called(1);
  });

  test('notifica os ouvintes: carregando e depois o usuário', () async {
    whenLogin().thenAnswer((_) async => _user);
    await container.read(authControllerProvider.future);
    final states = <AsyncValue<User?>>[];
    container.listen(
      authControllerProvider,
      (_, AsyncValue<User?> next) => states.add(next),
    );

    await login();

    expect(states, hasLength(2));
    expect(states.first.isLoading, isTrue);
    expect(states.last.value, _user);
  });
}
