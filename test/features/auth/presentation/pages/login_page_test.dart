import 'dart:async';

import 'package:autouni_app/core/biometrics/biometric_authenticator.dart';
import 'package:autouni_app/core/biometrics/biometric_providers.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/session/session_events.dart';
import 'package:autouni_app/features/auth/data/auth_data_providers.dart';
import 'package:autouni_app/features/auth/data/biometrics/biometric_login_settings.dart';
import 'package:autouni_app/features/auth/domain/models/user.dart';
import 'package:autouni_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:autouni_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autouni_app/features/auth/presentation/pages/login_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/pump_router_app.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockBiometrics extends Mock implements BiometricAuthenticator {}

const _user = User(id: 'u1', email: 'ana@uni.br', name: 'Ana');

void main() {
  late _MockAuthRepository repository;
  late _MockBiometrics biometrics;
  late InMemoryBiometricLoginSettings settings;

  When<Future<User>> whenLogin() => when(
    () => repository.login(
      email: any(named: 'email'),
      password: any(named: 'password'),
    ),
  );

  Future<ProviderContainer> pumpLogin(WidgetTester tester) async {
    final (container, _) = await tester.pumpRouterApp(
      initialLocation: '/login',
      routes: [
        GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
        stubRoute('/forgot-password'),
      ],
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        biometricAuthenticatorProvider.overrideWithValue(biometrics),
        biometricLoginSettingsProvider.overrideWithValue(settings),
      ],
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> fillAndSubmit(
    WidgetTester tester, {
    String email = 'ana@uni.br',
    String password = 'secret123',
  }) async {
    await tester.enterText(find.byKey(const Key('login-email')), email);
    await tester.enterText(find.byKey(const Key('login-password')), password);
    await tester.tap(find.byKey(const Key('login-submit')));
    await tester.pump();
  }

  setUp(() {
    repository = _MockAuthRepository();
    biometrics = _MockBiometrics();
    settings = InMemoryBiometricLoginSettings();
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    when(() => biometrics.isAvailable()).thenAnswer((_) async => true);
  });

  testWidgets('valida os campos antes de chamar o backend', (tester) async {
    await pumpLogin(tester);

    await fillAndSubmit(tester, email: 'ana', password: '123');

    expect(find.text('E-mail inválido.'), findsOneWidget);
    expect(find.textContaining('pelo menos 6'), findsOneWidget);
    verifyNever(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets('entra com as credenciais digitadas', (tester) async {
    whenLogin().thenAnswer((_) async => _user);
    final container = await pumpLogin(tester);

    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    verify(() => repository.login(email: 'ana@uni.br', password: 'secret123'))
        .called(1);
    expect(container.read(authControllerProvider).value, _user);
  });

  testWidgets('mostra progresso e bloqueia o botão durante o login', (
    tester,
  ) async {
    final pending = Completer<User>();
    whenLogin().thenAnswer((_) => pending.future);
    await pumpLogin(tester);

    await fillAndSubmit(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.byKey(const Key('login-submit')),
    );
    expect(button.onPressed, isNull);

    pending.complete(_user);
    await tester.pumpAndSettle();
  });

  testWidgets('credenciais inválidas mostram mensagem amigável', (
    tester,
  ) async {
    whenLogin().thenThrow(
      const UnauthorizedException(message: 'Credenciais inválidas'),
    );
    await pumpLogin(tester);

    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('E-mail ou senha incorretos.'), findsOneWidget);
  });

  testWidgets('sem rede mostra a mensagem da falha', (tester) async {
    whenLogin().thenThrow(const NetworkException());
    await pumpLogin(tester);

    await fillAndSubmit(tester);
    await tester.pumpAndSettle();

    expect(find.text('Sem conexão com a internet.'), findsOneWidget);
  });

  testWidgets('avisa quando a sessão expirou', (tester) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => _user);
    final container = await pumpLogin(tester);

    container.read(sessionEventsProvider).notifyExpired();
    await tester.pumpAndSettle();

    expect(find.text('Sua sessão expirou. Entre novamente.'), findsOneWidget);
  });

  testWidgets('"Esqueci minha senha" abre a recuperação', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Esqueci minha senha'));
    await tester.pumpAndSettle();

    expect(find.text('stub /forgot-password'), findsOneWidget);
  });

  group('biometria', () {
    testWidgets('sem biometria ligada, o botão não aparece', (tester) async {
      await pumpLogin(tester);

      expect(find.text('Entrar com biometria'), findsNothing);
    });

    testWidgets('com biometria ligada e sessão guardada, entra pelo botão', (
      tester,
    ) async {
      await settings.setEnabled(true);
      when(() => repository.restoreSession()).thenAnswer((_) async => _user);
      when(() => biometrics.authenticate(reason: any(named: 'reason')))
          .thenAnswer((_) async => BiometricAuthResult.success);
      final container = await pumpLogin(tester);

      await tester.tap(find.text('Entrar com biometria'));
      await tester.pumpAndSettle();

      expect(container.read(authControllerProvider).value, _user);
    });

    testWidgets('biometria bloqueada sugere a senha', (tester) async {
      await settings.setEnabled(true);
      when(() => repository.restoreSession()).thenAnswer((_) async => _user);
      when(() => biometrics.authenticate(reason: any(named: 'reason')))
          .thenAnswer((_) async => BiometricAuthResult.lockedOut);
      await pumpLogin(tester);

      await tester.tap(find.text('Entrar com biometria'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Entre com sua senha'), findsOneWidget);
    });
  });
}
