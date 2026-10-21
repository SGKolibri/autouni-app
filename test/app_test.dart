import 'package:autouni_app/app.dart';
import 'package:autouni_app/bootstrap.dart';
import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/app_config_provider.dart';
import 'package:autouni_app/core/cache/cache_providers.dart';
import 'package:autouni_app/core/cache/local_cache.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:autouni_app/core/realtime/realtime_providers.dart';
import 'package:autouni_app/features/auth/data/auth_data_providers.dart';
import 'package:autouni_app/features/auth/domain/models/user.dart';
import 'package:autouni_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:autouni_app/features/auth/presentation/pages/login_page.dart';
import 'package:autouni_app/features/dashboard/data/dashboard_repository.dart';
import 'package:autouni_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:autouni_app/core/push/push_messaging.dart';
import 'package:autouni_app/core/push/push_providers.dart';
import 'package:autouni_app/core/session/session_hooks.dart';
import 'package:autouni_app/shared/push/push_prompt_store.dart';
import 'package:autouni_app/shared/push/push_registration.dart';
import 'package:autouni_app/shared/rbac/rbac_providers.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mocktail/mocktail.dart';

import 'support/app_fakes.dart';

import 'package:autouni_app/core/network/network_providers.dart';
import 'package:autouni_app/core/network/secure_auth_token_store.dart';
import 'package:autouni_app/features/auth/data/biometrics/biometric_login_settings.dart';
import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockPushMessaging extends Mock implements PushMessaging {}

const _user = User(id: 'u1', email: 'ana@uni.br', name: 'Ana');

void main() {
  late _MockAuthRepository repository;
  late MockRealtimeClient realtime;

  setUp(() {
    repository = _MockAuthRepository();
    realtime = MockRealtimeClient.connected();
    when(() => repository.restoreSession()).thenAnswer((_) async => _user);
    FlutterSecureStorage.setMockInitialValues({});
  });

  Widget appWith(AppConfig config) => ProviderScope(
    overrides: [
      appConfigProvider.overrideWithValue(config),
      authRepositoryProvider.overrideWithValue(repository),
      realtimeClientProvider.overrideWithValue(realtime),
      dashboardRepositoryProvider.overrideWithValue(EmptyDashboardRepository()),
    ],
    child: const AutoUniApp(),
  );

  group('AutoUniApp', () {
    testWidgets('usa o nome do app definido pelo flavor', (tester) async {
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.dev)));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, 'AutoUni Dev');
    });

    testWidgets('mostra a faixa do flavor em dev', (tester) async {
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.dev)));

      expect(find.text('DEV'), findsOneWidget);
    });

    testWidgets('esconde a faixa do flavor em produção', (tester) async {
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.prod)));

      expect(find.text('DEV'), findsNothing);
      expect(find.text('PROD'), findsNothing);
    });

    testWidgets('abre no shell de navegação, na aba Início', (tester) async {
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.prod)));
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNav), findsOneWidget);
      expect(find.byType(DashboardPage), findsOneWidget);
    });

    testWidgets('sem sessão guardada abre no login', (tester) async {
      when(() => repository.restoreSession()).thenAnswer((_) async => null);
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.prod)));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);
    });

    testWidgets('conecta o tempo real com a sessão aberta', (tester) async {
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.prod)));
      await tester.pumpAndSettle();

      verify(() => realtime.connect()).called(1);
    });

    testWidgets('repassa o ciclo de vida do app ao tempo real', (tester) async {
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.prod)));
      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

      verify(() => realtime.handleAppLifecycleState(AppLifecycleState.paused))
          .called(1);
    });

    testWidgets('mantém a faixa do flavor por cima do shell em dev', (
      tester,
    ) async {
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.dev)));
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNav), findsOneWidget);
      expect(find.text('DEV'), findsOneWidget);
    });

    testWidgets('usa os temas claro e escuro do design system', (tester) async {
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.prod)));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(
        app.theme?.colorScheme.primary,
        AppTheme.light().colorScheme.primary,
      );
      expect(app.darkTheme?.brightness, Brightness.dark);
    });
  });

  group('buildAppRoot', () {
    testWidgets('injeta a config no ProviderScope raiz', (tester) async {
      final config = AppConfig.forFlavor(Flavor.prod);

      await tester.pumpWidget(buildAppRoot(config));

      final element = tester.element(find.byType(AutoUniApp));
      final container = ProviderScope.containerOf(element);
      expect(container.read(appConfigProvider), same(config));
    });

    testWidgets('guarda os tokens de sessão no armazenamento seguro', (
      tester,
    ) async {
      await tester.pumpWidget(buildAppRoot(AppConfig.forFlavor(Flavor.prod)));

      final element = tester.element(find.byType(AutoUniApp));
      final container = ProviderScope.containerOf(element);
      expect(
        container.read(authTokenStoreProvider),
        isA<SecureAuthTokenStore>(),
      );
    });

    testWidgets('o papel do RBAC vem da sessão', (tester) async {
      await tester.pumpWidget(buildAppRoot(AppConfig.forFlavor(Flavor.prod)));
      await tester.pumpAndSettle();

      final element = tester.element(find.byType(AutoUniApp));
      final container = ProviderScope.containerOf(element);
      expect(container.read(currentUserRoleProvider), isNull);
    });

    testWidgets('usa o cache local recebido', (tester) async {
      final cache = InMemoryLocalCache();
      await tester.pumpWidget(
        buildAppRoot(AppConfig.forFlavor(Flavor.prod), cache: cache),
      );

      final element = tester.element(find.byType(AutoUniApp));
      final container = ProviderScope.containerOf(element);
      expect(container.read(localCacheProvider), same(cache));
    });

    testWidgets('guarda a preferência de biometria no armazenamento seguro', (
      tester,
    ) async {
      await tester.pumpWidget(buildAppRoot(AppConfig.forFlavor(Flavor.prod)));

      final element = tester.element(find.byType(AutoUniApp));
      final container = ProviderScope.containerOf(element);
      expect(
        container.read(biometricLoginSettingsProvider),
        isA<SecureBiometricLoginSettings>(),
      );
    });

    testWidgets('sem Firebase, push desligado e sem sessão não há usuário', (
      tester,
    ) async {
      await tester.pumpWidget(buildAppRoot(AppConfig.forFlavor(Flavor.prod)));

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AutoUniApp)),
      );
      expect(container.read(pushMessagingProvider), isNull);
      expect(container.read(sessionUserIdProvider), isNull);
      expect(container.read(pushRegistrationProvider), PushStatus.unavailable);
    });

    testWidgets('com push, injeta o plugin e guarda o convite no seguro', (
      tester,
    ) async {
      final push = _MockPushMessaging();
      await tester.pumpWidget(
        buildAppRoot(AppConfig.forFlavor(Flavor.prod), push: push),
      );

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AutoUniApp)),
      );
      expect(container.read(pushMessagingProvider), same(push));
      expect(
        container.read(pushPromptStoreProvider),
        isA<SecurePushPromptStore>(),
      );
      // deslogado: não pergunta nada ao sistema
      verifyZeroInteractions(push);
    });
  });
}
