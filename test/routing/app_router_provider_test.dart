import 'dart:async';

import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/app_config_provider.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:autouni_app/core/router/app_tab.dart';
import 'package:autouni_app/core/router/session_guard.dart';
import 'package:autouni_app/core/router/splash_page.dart';
import 'package:autouni_app/features/auth/data/auth_data_providers.dart';
import 'package:autouni_app/features/auth/domain/models/user.dart';
import 'package:autouni_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:autouni_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autouni_app/features/auth/presentation/pages/login_page.dart';
import 'package:autouni_app/core/realtime/realtime_providers.dart';
import 'package:autouni_app/features/automations/data/automations_repository.dart';
import 'package:autouni_app/features/automations/presentation/pages/automations_page.dart';
import 'package:autouni_app/features/dashboard/data/dashboard_repository.dart';
import 'package:autouni_app/features/energy/data/energy_repository.dart';
import 'package:autouni_app/features/energy/presentation/pages/energy_page.dart';
import 'package:autouni_app/routing/app_router_provider.dart';
import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_fakes.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _user = User(id: 'u1', email: 'ana@uni.br', name: 'Ana');

void main() {
  late _MockAuthRepository repository;

  Future<(ProviderContainer, GoRouter)> pumpApp(WidgetTester tester) async {
    final container = ProviderContainer.test(
      overrides: [
        automationsRepositoryProvider.overrideWithValue(
          EmptyAutomationsRepository(),
        ),
        energyRepositoryProvider.overrideWithValue(EmptyEnergyRepository()),
        appConfigProvider.overrideWithValue(AppConfig.forFlavor(Flavor.prod)),
        authRepositoryProvider.overrideWithValue(repository),
        realtimeClientProvider.overrideWithValue(
          MockRealtimeClient.connected(),
        ),
        dashboardRepositoryProvider.overrideWithValue(
          EmptyDashboardRepository(),
        ),
      ],
    );
    final router = container.read(appRouterProvider);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    return (container, router);
  }

  setUp(() => repository = _MockAuthRepository());

  testWidgets('expõe um único GoRouter por container', (tester) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    final (container, router) = await pumpApp(tester);

    expect(container.read(appRouterProvider), same(router));
  });

  testWidgets('splash enquanto restaura; sem sessão vai para o login', (
    tester,
  ) async {
    final restoring = Completer<User?>();
    when(() => repository.restoreSession()).thenAnswer((_) => restoring.future);
    final (_, router) = await pumpApp(tester);
    await tester.pump();

    expect(find.byType(SplashPage), findsOneWidget);

    restoring.complete(null);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, SessionRoutes.login);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('sessão restaurada abre direto na aba Início', (tester) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => _user);
    final (_, router) = await pumpApp(tester);
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppTab.dashboard.path);
    expect(find.byType(AppBottomNav), findsOneWidget);
  });

  testWidgets('login com erro continua no login (sem voltar ao splash)', (
    tester,
  ) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    final pending = Completer<User>();
    when(
      () => repository.login(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) => pending.future);
    final (container, router) = await pumpApp(tester);
    await tester.pumpAndSettle();

    final call = container
        .read(authControllerProvider.notifier)
        .login(email: 'ana@uni.br', password: 'secret123');
    await tester.pump();
    expect(router.state.uri.path, SessionRoutes.login);

    pending.complete(_user);
    await call;
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppTab.dashboard.path);
  });

  testWidgets('a aba Ajustes mostra a conta e permite sair', (tester) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => _user);
    when(() => repository.logout()).thenAnswer((_) async {});
    final (_, router) = await pumpApp(tester);
    await tester.pumpAndSettle();

    router.go(AppTab.settings.path);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-logout')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sair'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, SessionRoutes.login);
  });

  testWidgets('a aba Automações abre a lista de automações', (tester) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => _user);
    final (_, router) = await pumpApp(tester);
    await tester.pumpAndSettle();

    router.go(AppTab.automations.path);
    await tester.pumpAndSettle();

    expect(find.byType(AutomationsPage), findsOneWidget);
    expect(find.text('Nenhuma automação'), findsOneWidget);
  });

  testWidgets('a tela de energia abre por cima das abas', (tester) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => _user);
    final (_, router) = await pumpApp(tester);
    await tester.pumpAndSettle();

    router.push('/energy?level=building&id=b1&name=Bloco%20A');
    await tester.pumpAndSettle();

    expect(find.byType(EnergyPage), findsOneWidget);
    expect(find.text('Bloco A'), findsOneWidget);
    expect(find.byType(AppBottomNav), findsNothing);

    router.pop();
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppTab.dashboard.path);
  });

  testWidgets('sem sessão, link de energia passa pelo login', (tester) async {
    when(() => repository.restoreSession()).thenAnswer((_) async => null);
    final (_, router) = await pumpApp(tester);
    await tester.pumpAndSettle();

    router.go('/energy');
    await tester.pumpAndSettle();

    expect(router.state.uri.path, SessionRoutes.login);
    expect(
      router.state.uri.queryParameters[SessionRoutes.fromParam],
      '/energy',
    );
  });
}
