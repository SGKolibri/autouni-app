import 'package:autouni_app/core/biometrics/biometric_authenticator.dart';
import 'package:autouni_app/core/biometrics/biometric_providers.dart';
import 'package:autouni_app/features/auth/data/auth_data_providers.dart';
import 'package:autouni_app/features/auth/data/biometrics/biometric_login_settings.dart';
import 'package:autouni_app/features/auth/domain/models/user.dart';
import 'package:autouni_app/features/auth/domain/models/user_role.dart';
import 'package:autouni_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:autouni_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autouni_app/features/auth/presentation/controllers/biometric_login_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockBiometricAuthenticator extends Mock
    implements BiometricAuthenticator {}

const _user = User(
  id: 'uuid-user-123',
  email: 'joao@example.com',
  name: 'João Silva',
  role: UserRole.coordinator,
);

void main() {
  late _MockAuthRepository repository;
  late _MockBiometricAuthenticator biometrics;
  late InMemoryBiometricLoginSettings settings;
  late ProviderContainer container;

  void storedSession(User? user) =>
      when(() => repository.restoreSession()).thenAnswer((_) async => user);

  void deviceHasBiometrics(bool available) =>
      when(() => biometrics.isAvailable()).thenAnswer((_) async => available);

  void promptAnswers(BiometricAuthResult result) =>
      when(() => biometrics.authenticate(reason: any(named: 'reason')))
          .thenAnswer((_) async => result);

  void verifyNoPrompt() =>
      verifyNever(() => biometrics.authenticate(reason: any(named: 'reason')));

  AuthController auth() => container.read(authControllerProvider.notifier);
  BiometricLoginController preference() =>
      container.read(biometricLoginEnabledProvider.notifier);

  setUp(() {
    repository = _MockAuthRepository();
    biometrics = _MockBiometricAuthenticator();
    settings = InMemoryBiometricLoginSettings();
    container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        biometricAuthenticatorProvider.overrideWithValue(biometrics),
        biometricLoginSettingsProvider.overrideWithValue(settings),
      ],
    );
    storedSession(_user);
    deviceHasBiometrics(true);
    promptAnswers(BiometricAuthResult.success);
  });

  group('abertura do app', () {
    test('com biometria desligada, a sessão guardada entra direto', () async {
      expect(await container.read(authControllerProvider.future), _user);
      verifyNoPrompt();
    });

    test('com biometria ligada, a sessão guardada fica bloqueada', () async {
      await settings.setEnabled(true);

      expect(await container.read(authControllerProvider.future), isNull);
      verifyNoPrompt();
    });
  });

  group('loginWithBiometrics', () {
    setUp(() => settings.setEnabled(true));

    test('biometria confirmada libera o usuário da sessão guardada', () async {
      final result = await auth().loginWithBiometrics();

      expect(result, BiometricAuthResult.success);
      expect(container.read(authControllerProvider).value, _user);
      verify(() => biometrics.authenticate(reason: any(named: 'reason')))
          .called(1);
    });

    for (final failure in [
      BiometricAuthResult.failed,
      BiometricAuthResult.lockedOut,
      BiometricAuthResult.unavailable,
    ]) {
      test('${failure.name} mantém deslogado, sem estado de erro', () async {
        promptAnswers(failure);

        final result = await auth().loginWithBiometrics();

        expect(result, failure);
        final state = container.read(authControllerProvider);
        expect(state.value, isNull);
        expect(state.hasError, isFalse);
        expect(state.isLoading, isFalse);
      });
    }

    test('não abre o prompt se o login por biometria está desligado', () async {
      await settings.setEnabled(false);
      storedSession(null);

      expect(
        await auth().loginWithBiometrics(),
        BiometricAuthResult.unavailable,
      );
      verifyNoPrompt();
    });

    test('não abre o prompt se o aparelho ficou sem biometria', () async {
      deviceHasBiometrics(false);

      expect(
        await auth().loginWithBiometrics(),
        BiometricAuthResult.unavailable,
      );
      verifyNoPrompt();
      expect(container.read(authControllerProvider).value, isNull);
    });

    test('sessão expirada: não abre o prompt e segue deslogado', () async {
      storedSession(null);

      expect(
        await auth().loginWithBiometrics(),
        BiometricAuthResult.unavailable,
      );
      verifyNoPrompt();
      expect(container.read(authControllerProvider).value, isNull);
    });

    test('login por senha continua funcionando como alternativa', () async {
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => _user);

      await auth().login(email: 'joao@example.com', password: 'secret123');

      expect(container.read(authControllerProvider).value, _user);
      verifyNoPrompt();
    });
  });

  group('biometricLoginAvailableProvider', () {
    Future<bool> available() =>
        container.read(biometricLoginAvailableProvider.future);

    test(
      'true com biometria ligada, aparelho apto e sessão guardada',
      () async {
        await settings.setEnabled(true);

        expect(await available(), isTrue);
      },
    );

    test('false antes do primeiro acesso (biometria nunca ligada)', () async {
      expect(await available(), isFalse);
    });

    test('false se o aparelho não tem biometria', () async {
      await settings.setEnabled(true);
      deviceHasBiometrics(false);

      expect(await available(), isFalse);
    });

    test('false sem sessão guardada (expirou ou saiu)', () async {
      await settings.setEnabled(true);
      storedSession(null);

      expect(await available(), isFalse);
    });
  });

  group('ligar/desligar o login por biometria', () {
    test('começa desligado', () async {
      expect(await container.read(biometricLoginEnabledProvider.future), false);
    });

    test('ligar pede a biometria e guarda a escolha, sem deslogar', () async {
      await container.read(authControllerProvider.future);

      final result = await preference().enable();

      expect(result, BiometricAuthResult.success);
      expect(await settings.isEnabled(), isTrue);
      expect(container.read(biometricLoginEnabledProvider).value, isTrue);
      expect(container.read(authControllerProvider).value, _user);
    });

    test('não liga se a biometria não for confirmada', () async {
      await container.read(authControllerProvider.future);
      promptAnswers(BiometricAuthResult.failed);

      expect(await preference().enable(), BiometricAuthResult.failed);
      expect(await settings.isEnabled(), isFalse);
      expect(container.read(biometricLoginEnabledProvider).value, isFalse);
    });

    test('não liga em aparelho sem biometria', () async {
      await container.read(authControllerProvider.future);
      deviceHasBiometrics(false);

      expect(await preference().enable(), BiometricAuthResult.unavailable);
      verifyNoPrompt();
      expect(await settings.isEnabled(), isFalse);
    });

    test('só liga depois do primeiro acesso (precisa estar logado)', () async {
      storedSession(null);
      await container.read(authControllerProvider.future);

      expect(await preference().enable(), BiometricAuthResult.unavailable);
      verifyNoPrompt();
      expect(await settings.isEnabled(), isFalse);
    });

    test('desligar apaga a escolha', () async {
      await settings.setEnabled(true);
      await container.read(biometricLoginEnabledProvider.future);

      await preference().disable();

      expect(await settings.isEnabled(), isFalse);
      expect(container.read(biometricLoginEnabledProvider).value, isFalse);
    });
  });
}
