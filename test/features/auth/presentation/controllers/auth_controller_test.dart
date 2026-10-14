import 'dart:async';

import 'package:autouni_app/core/cache/cache_providers.dart';
import 'package:autouni_app/core/cache/local_cache.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/session/session_events.dart';
import 'package:autouni_app/shared/devices/device_live_state.dart';
import 'package:autouni_app/shared/models/campus/campus_enums.dart';
import 'package:autouni_app/shared/realtime/device_events.dart';
import 'package:autouni_app/features/auth/data/auth_data_providers.dart';
import 'package:autouni_app/features/auth/domain/models/user.dart';
import 'package:autouni_app/shared/models/user_role.dart';
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

  group('logout', () {
    setUp(() {
      when(() => repository.restoreSession()).thenAnswer((_) async => _user);
      when(() => repository.logout()).thenAnswer((_) async {});
    });

    test('encerra a sessão no backend, limpa o cache e desloga', () async {
      final cache = InMemoryLocalCache();
      await cache.write('buildings', [1]);
      container = ProviderContainer.test(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          localCacheProvider.overrideWithValue(cache),
        ],
      );
      expect(await container.read(authControllerProvider.future), _user);

      await container.read(authControllerProvider.notifier).logout();

      verify(() => repository.logout()).called(1);
      expect(container.read(authControllerProvider).value, isNull);
      expect(await cache.read('buildings'), isNull);
    });

    test('descarta o estado ao vivo dos dispositivos', () async {
      container = ProviderContainer.test(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          deviceEventsProvider.overrideWithValue(const Stream.empty()),
        ],
      );
      await container.read(authControllerProvider.future);
      container
          .read(deviceLiveStateProvider.notifier)
          .begin('d1', const DeviceOverride(status: DeviceStatus.on));

      await container.read(authControllerProvider.notifier).logout();

      expect(container.read(deviceLiveStateProvider).overrides, isEmpty);
    });
  });

  group('sessão expirada (refresh recusado)', () {
    test(
      'desloga, limpa o cache e liga o aviso para a tela de login',
      () async {
        when(() => repository.restoreSession()).thenAnswer((_) async => _user);
        final cache = InMemoryLocalCache();
        await cache.write('buildings', [1]);
        container = ProviderContainer.test(
          overrides: [
            authRepositoryProvider.overrideWithValue(repository),
            localCacheProvider.overrideWithValue(cache),
          ],
        );
        expect(await container.read(authControllerProvider.future), _user);

        container.read(sessionEventsProvider).notifyExpired();
        await Future<void>.delayed(Duration.zero);

        expect(container.read(authControllerProvider).value, isNull);
        expect(container.read(sessionExpiredNoticeProvider), isTrue);
        expect(await cache.read('buildings'), isNull);
      },
    );

    test('o aviso some no próximo login', () async {
      when(() => repository.restoreSession()).thenAnswer((_) async => _user);
      whenLogin().thenAnswer((_) async => _user);
      await container.read(authControllerProvider.future);
      container.read(sessionEventsProvider).notifyExpired();
      await Future<void>.delayed(Duration.zero);

      await login();

      expect(container.read(sessionExpiredNoticeProvider), isFalse);
    });

    test('sem usuário logado, o aviso de expiração é ignorado', () async {
      await container.read(authControllerProvider.future);

      container.read(sessionEventsProvider).notifyExpired();
      await Future<void>.delayed(Duration.zero);

      expect(container.read(sessionExpiredNoticeProvider), isFalse);
    });
  });
}
