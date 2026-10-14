import 'package:autouni_app/core/biometrics/biometric_authenticator.dart';
import 'package:autouni_app/core/biometrics/biometric_providers.dart';
import 'package:autouni_app/features/auth/data/auth_data_providers.dart';
import 'package:autouni_app/features/auth/data/biometrics/biometric_login_settings.dart';
import 'package:autouni_app/features/auth/domain/models/user.dart';
import 'package:autouni_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:autouni_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autouni_app/features/auth/presentation/pages/account_settings_page.dart';
import 'package:autouni_app/shared/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/pump_app.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockBiometrics extends Mock implements BiometricAuthenticator {}

const _user = User(
  id: 'u1',
  email: 'ana@uni.br',
  name: 'Ana Souza',
  role: UserRole.technician,
);

void main() {
  late _MockAuthRepository repository;
  late _MockBiometrics biometrics;
  late InMemoryBiometricLoginSettings settings;

  Future<ProviderContainer> pumpPage(WidgetTester tester) async {
    final container = await tester.pumpApp(
      const AccountSettingsPage(),
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        biometricAuthenticatorProvider.overrideWithValue(biometrics),
        biometricLoginSettingsProvider.overrideWithValue(settings),
      ],
    );
    await container.read(authControllerProvider.future);
    await tester.pumpAndSettle();
    return container;
  }

  setUp(() {
    repository = _MockAuthRepository();
    biometrics = _MockBiometrics();
    settings = InMemoryBiometricLoginSettings();
    when(() => repository.restoreSession()).thenAnswer((_) async => _user);
    when(() => repository.logout()).thenAnswer((_) async {});
    when(() => biometrics.isAvailable()).thenAnswer((_) async => true);
  });

  testWidgets('mostra a conta e o papel do usuário', (tester) async {
    await pumpPage(tester);

    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('ana@uni.br'), findsOneWidget);
    expect(find.text('Técnico'), findsOneWidget);
  });

  testWidgets('logout pede confirmação e encerra a sessão', (tester) async {
    final container = await pumpPage(tester);

    await tester.tap(find.byKey(const Key('settings-logout')));
    await tester.pumpAndSettle();
    expect(find.text('Sair da conta?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Sair'));
    await tester.pumpAndSettle();

    verify(() => repository.logout()).called(1);
    expect(container.read(authControllerProvider).value, isNull);
  });

  testWidgets('cancelar o logout mantém a sessão', (tester) async {
    final container = await pumpPage(tester);

    await tester.tap(find.byKey(const Key('settings-logout')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.logout());
    expect(container.read(authControllerProvider).value, _user);
  });

  testWidgets('liga a biometria confirmando no prompt', (tester) async {
    when(() => biometrics.authenticate(reason: any(named: 'reason')))
        .thenAnswer((_) async => BiometricAuthResult.success);
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('settings-biometrics')));
    await tester.pumpAndSettle();

    expect(await settings.isEnabled(), isTrue);
    expect(find.text('Acesso por biometria ativado.'), findsOneWidget);
  });

  testWidgets('sem biometria no aparelho, a opção não aparece', (tester) async {
    when(() => biometrics.isAvailable()).thenAnswer((_) async => false);
    await pumpPage(tester);

    expect(find.byKey(const Key('settings-biometrics')), findsNothing);
  });
}
