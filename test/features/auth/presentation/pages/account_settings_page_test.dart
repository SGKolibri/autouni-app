import 'package:autouni_app/core/biometrics/biometric_authenticator.dart';
import 'package:autouni_app/core/biometrics/biometric_providers.dart';
import 'package:autouni_app/core/preferences/app_preferences.dart';
import 'package:autouni_app/core/push/push_messaging.dart';
import 'package:autouni_app/core/push/push_providers.dart';
import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/core/router/app_tab.dart';
import 'package:autouni_app/core/session/session_hooks.dart';
import 'package:autouni_app/features/auth/data/auth_data_providers.dart';
import 'package:autouni_app/features/auth/data/biometrics/biometric_login_settings.dart';
import 'package:autouni_app/features/auth/data/repositories/profile_repository.dart';
import 'package:autouni_app/features/auth/domain/models/user.dart';
import 'package:autouni_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:autouni_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autouni_app/features/auth/presentation/pages/account_settings_page.dart';
import 'package:autouni_app/shared/models/user_role.dart';
import 'package:autouni_app/shared/push/push_registration.dart';
import 'package:autouni_app/shared/push/push_token_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/pump_router_app.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockProfile extends Mock implements ProfileRepository {}

class _MockBiometrics extends Mock implements BiometricAuthenticator {}

class _MockMessaging extends Mock implements PushMessaging {}

class _MockTokens extends Mock implements PushTokenRepository {}

const _user = User(
  id: 'u1',
  email: 'ana@uni.br',
  name: 'Ana Souza',
  role: UserRole.technician,
);

void main() {
  late _MockAuthRepository repository;
  late _MockProfile profile;
  late _MockBiometrics biometrics;
  late _MockMessaging messaging;
  late _MockTokens tokens;
  late InMemoryBiometricLoginSettings settings;
  late InMemoryPreferencesStore preferences;

  setUpAll(() => registerFallbackValue(PushPlatform.android));

  Future<(ProviderContainer, GoRouter)> pumpPage(
    WidgetTester tester, {
    bool withPush = true,
  }) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final result = await tester.pumpRouterApp(
      initialLocation: AppTab.settings.path,
      routes: [
        GoRoute(
          path: AppTab.settings.path,
          builder: (_, _) => const AccountSettingsPage(),
        ),
        stubRoute(AppPaths.profile),
        stubRoute(AppPaths.changePassword),
        stubRoute(AppPaths.reportsRoot),
      ],
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        profileRepositoryProvider.overrideWithValue(profile),
        biometricAuthenticatorProvider.overrideWithValue(biometrics),
        biometricLoginSettingsProvider.overrideWithValue(settings),
        preferencesStoreProvider.overrideWithValue(preferences),
        pushMessagingProvider.overrideWithValue(withPush ? messaging : null),
        pushTokenRepositoryProvider.overrideWithValue(tokens),
        pushPlatformProvider.overrideWithValue(PushPlatform.android),
        // Como no bootstrap: o push segue o usuário da sessão.
        sessionUserIdProvider.overrideWith(
          (ref) => ref.watch(authControllerProvider).value?.id,
        ),
      ],
    );
    await result.$1.read(authControllerProvider.future);
    await tester.pumpAndSettle();
    return result;
  }

  setUp(() {
    repository = _MockAuthRepository();
    profile = _MockProfile();
    biometrics = _MockBiometrics();
    messaging = _MockMessaging();
    tokens = _MockTokens();
    settings = InMemoryBiometricLoginSettings();
    preferences = InMemoryPreferencesStore();
    when(() => repository.restoreSession()).thenAnswer((_) async => _user);
    when(() => repository.logout()).thenAnswer((_) async {});
    when(() => profile.fetch('u1'))
        .thenAnswer((_) async => _user.copyWith(phone: '62999990000'));
    when(() => biometrics.isAvailable()).thenAnswer((_) async => true);
    when(() => messaging.permission())
        .thenAnswer((_) async => PushPermission.granted);
    when(() => messaging.getToken()).thenAnswer((_) async => 'fcm-1');
    when(() => messaging.onTokenRefresh)
        .thenAnswer((_) => const Stream.empty());
    when(() => messaging.deleteToken()).thenAnswer((_) async {});
    when(() => tokens.register(any(), any())).thenAnswer((_) async {});
    when(() => tokens.unregister(any())).thenAnswer((_) async {});
  });

  testWidgets('mostra a conta completa e o papel', (tester) async {
    await pumpPage(tester);

    expect(find.text('Ana Souza'), findsOneWidget);
    expect(find.text('ana@uni.br\n62999990000'), findsOneWidget);
    expect(find.text('Técnico'), findsOneWidget);
  });

  for (final (key, path) in [
    ('settings-profile', AppPaths.profile),
    ('settings-password', AppPaths.changePassword),
    ('settings-reports', AppPaths.reportsRoot),
  ]) {
    testWidgets('"$key" leva a $path', (tester) async {
      final (_, router) = await pumpPage(tester);

      await tester.tap(find.byKey(Key(key)));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, path);
    });
  }

  testWidgets('tema escolhido é gravado (preferência persiste)', (
    tester,
  ) async {
    final (container, _) = await pumpPage(tester);

    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();

    expect(preferences.load().themeMode, ThemeMode.dark);
    expect(container.read(appPreferencesProvider).themeMode, ThemeMode.dark);
  });

  testWidgets('idioma mostra pt-BR', (tester) async {
    await pumpPage(tester);

    expect(find.text('Português (Brasil)'), findsOneWidget);
  });

  group('alertas por push', () {
    testWidgets('desligar remove o token e grava a preferência', (
      tester,
    ) async {
      final (container, _) = await pumpPage(tester);
      expect(container.read(pushRegistrationProvider), PushStatus.enabled);

      await tester.tap(find.byKey(const Key('settings-push')));
      await tester.pumpAndSettle();

      verify(() => tokens.unregister('fcm-1')).called(1);
      expect(preferences.load().pushEnabled, isFalse);
      expect(
        find.text('Alertas por push desligados neste aparelho.'),
        findsOneWidget,
      );
    });

    testWidgets('bloqueado no sistema explica onde liberar', (tester) async {
      preferences = InMemoryPreferencesStore(
        const AppPreferences(pushEnabled: false),
      );
      when(() => messaging.permission())
          .thenAnswer((_) async => PushPermission.denied);
      await pumpPage(tester);

      await tester.tap(find.byKey(const Key('settings-push')));
      await tester.pumpAndSettle();

      expect(find.textContaining('bloqueados nas configurações'), findsWidgets);
    });

    testWidgets('sem push no aparelho, o switch fica desabilitado', (
      tester,
    ) async {
      await pumpPage(tester, withPush: false);

      final tile = tester.widget<SwitchListTile>(
        find.byKey(const Key('settings-push')),
      );
      expect(tile.onChanged, isNull);
      expect(find.text('Indisponível neste aparelho'), findsOneWidget);
    });
  });

  group('segurança', () {
    testWidgets('liga a biometria confirmando no prompt', (tester) async {
      when(() => biometrics.authenticate(reason: any(named: 'reason')))
          .thenAnswer((_) async => BiometricAuthResult.success);
      await pumpPage(tester);

      await tester.tap(find.byKey(const Key('settings-biometrics')));
      await tester.pumpAndSettle();

      expect(await settings.isEnabled(), isTrue);
      expect(find.text('Acesso por biometria ativado.'), findsOneWidget);
    });

    testWidgets('sem biometria no aparelho, a opção não aparece', (
      tester,
    ) async {
      when(() => biometrics.isAvailable()).thenAnswer((_) async => false);
      await pumpPage(tester);

      expect(find.byKey(const Key('settings-biometrics')), findsNothing);
    });
  });

  group('sair', () {
    testWidgets('pede confirmação e encerra a sessão', (tester) async {
      final (container, _) = await pumpPage(tester);

      await tester.tap(find.byKey(const Key('settings-logout')));
      await tester.pumpAndSettle();
      expect(find.text('Sair da conta?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Sair'));
      await tester.pumpAndSettle();

      verify(() => repository.logout()).called(1);
      expect(container.read(authControllerProvider).value, isNull);
    });

    testWidgets('cancelar mantém a sessão', (tester) async {
      final (container, _) = await pumpPage(tester);

      await tester.tap(find.byKey(const Key('settings-logout')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      verifyNever(() => repository.logout());
      expect(container.read(authControllerProvider).value, _user);
    });
  });
}
