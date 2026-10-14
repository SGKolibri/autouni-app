import 'package:autouni_app/core/realtime/realtime_client.dart';
import 'package:autouni_app/core/realtime/realtime_providers.dart';
import 'package:autouni_app/features/auth/data/auth_data_providers.dart';
import 'package:autouni_app/features/auth/domain/models/user.dart';
import 'package:autouni_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:autouni_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autouni_app/features/auth/presentation/controllers/session_realtime_binding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockRealtimeClient extends Mock implements RealtimeClient {}

const _user = User(id: 'u1', email: 'a@b.com', name: 'Ana');

void main() {
  late _MockAuthRepository repository;
  late _MockRealtimeClient realtime;

  ProviderContainer start({User? storedUser}) {
    when(() => repository.restoreSession()).thenAnswer((_) async => storedUser);
    final container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        realtimeClientProvider.overrideWithValue(realtime),
      ],
    );
    container.read(sessionRealtimeBindingProvider);
    return container;
  }

  setUp(() {
    repository = _MockAuthRepository();
    realtime = _MockRealtimeClient();
    when(() => realtime.connect()).thenAnswer((_) async {});
    when(() => realtime.disconnect()).thenAnswer((_) async {});
    when(() => repository.logout()).thenAnswer((_) async {});
  });

  test('sessão restaurada conecta o WebSocket', () async {
    final container = start(storedUser: _user);

    await container.read(authControllerProvider.future);

    verify(() => realtime.connect()).called(1);
  });

  test('sem sessão não conecta', () async {
    final container = start();

    await container.read(authControllerProvider.future);

    verifyNever(() => realtime.connect());
  });

  test('login conecta e logout desconecta', () async {
    final container = start();
    await container.read(authControllerProvider.future);
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => _user);

    await container
        .read(authControllerProvider.notifier)
        .login(email: 'a@b.com', password: 'secret123');
    verify(() => realtime.connect()).called(1);

    await container.read(authControllerProvider.notifier).logout();
    verify(() => realtime.disconnect()).called(1);
  });
}
