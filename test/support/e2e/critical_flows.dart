/// Fluxos críticos de ponta a ponta (S6-T6), escritos uma vez e rodados em
/// dois lugares: `test/e2e/` (CI, sem aparelho) e `integration_test/`
/// (emulador ou aparelho, `flutter test integration_test`).
library;

import 'package:autouni_app/bootstrap.dart';
import 'package:autouni_app/core/biometrics/biometric_authenticator.dart';
import 'package:autouni_app/core/biometrics/biometric_providers.dart';
import 'package:autouni_app/core/cache/local_cache.dart';
import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:autouni_app/core/network/network_providers.dart';
import 'package:autouni_app/core/preferences/app_preferences.dart';
import 'package:autouni_app/core/push/push_messaging.dart';
import 'package:autouni_app/core/realtime/realtime_providers.dart';
import 'package:autouni_app/features/auth/presentation/pages/login_page.dart';
import 'package:autouni_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:autouni_app/features/environments/presentation/pages/room_detail_page.dart';
import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:autouni_app/shared/devices/device_detail_sheet.dart';
import 'package:autouni_app/shared/push/push_registration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_backend.dart';

/// Biometria ausente (o login por senha é o fluxo testado).
class _NoBiometrics implements BiometricAuthenticator {
  const _NoBiometrics();

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<BiometricAuthResult> authenticate({required String reason}) async =>
      BiometricAuthResult.unavailable;
}

/// Um app novo contra [backend], como saído da instalação: sem sessão
/// guardada, cache vazio e preferências padrão.
class E2EApp {
  E2EApp() : backend = FakeBackend(), push = FakePushMessaging();

  final FakeBackend backend;
  final FakePushMessaging push;

  Widget build() => buildAppRoot(
    AppConfig.forFlavor(Flavor.prod),
    cache: InMemoryLocalCache(),
    push: push,
    preferences: InMemoryPreferencesStore(),
    overrides: [
      httpClientAdapterProvider.overrideWithValue(backend),
      socketFactoryProvider.overrideWithValue(backend.socketFactory),
      pushPlatformProvider.overrideWithValue(PushPlatform.android),
      biometricAuthenticatorProvider.overrideWithValue(const _NoBiometrics()),
    ],
  );

  /// Abre o app numa tela de celular.
  Future<void> launch(WidgetTester tester) async {
    // Armazenamento seguro em memória: o aparelho de teste não guarda
    // sessão de uma execução para a outra.
    FlutterSecureStorage.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(build());
    await pumpUntil(tester, find.byType(LoginPage));
  }

  /// Entra pela tela de login. Com [expectSuccess], espera o Início
  /// carregar; senão, a mensagem de erro.
  Future<void> login(
    WidgetTester tester, {
    String email = 'admin@autouni.edu.br',
    String password = 'Admin@123',
    bool expectSuccess = true,
  }) async {
    expect(find.byType(LoginPage), findsOneWidget);
    await tester.enterText(find.byKey(const Key('login-email')), email);
    await tester.enterText(find.byKey(const Key('login-password')), password);
    await tester.tap(find.byKey(const Key('login-submit')));
    await pumpUntil(
      tester,
      expectSuccess
          ? find.widgetWithText(KpiCard, 'Dispositivos ligados')
          : find.text('E-mail ou senha incorretos.'),
    );
  }

  /// Ambientes → Bloco A → 1º andar → Sala 101.
  Future<void> openRoom(WidgetTester tester) async {
    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text('Ambientes'),
      ),
    );
    await tester.pumpAndSettle();
    for (final label in ['Bloco A', '1º andar', 'Sala 101']) {
      await pumpUntil(tester, find.text(label));
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
    }
    await pumpUntil(tester, find.byKey(const ValueKey('device-row-d1')));
    expect(find.byType(RoomDetailPage), findsOneWidget);
  }

  void expectNoUnhandledRoutes() => expect(
    backend.unhandled,
    isEmpty,
    reason: 'rotas que o backend falso não conhece',
  );
}

/// Espera [finder] aparecer. No aparelho (binding "live"), `pumpAndSettle`
/// não espera as respostas assíncronas; aqui o teste avança aos poucos até a
/// tela chegar no estado esperado.
Future<void> pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 100,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isNotEmpty) break;
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
  expect(finder, findsWidgets);
}

String kpiValue(WidgetTester tester, String label) =>
    tester.widget<KpiCard>(find.widgetWithText(KpiCard, label)).value;

Switch switchOf(WidgetTester tester, String deviceId) => tester.widget<Switch>(
  find.descendant(
    of: find.byKey(ValueKey('device-row-$deviceId')),
    matching: find.byType(Switch),
  ),
);

/// Registra os fluxos críticos com [testWidgets] (o binding já foi escolhido
/// por quem chama).
void criticalFlows() {
  testWidgets('login: credenciais erradas, depois certas → Início com dados '
      'do backend e push registrado', (tester) async {
    final app = E2EApp();
    await app.launch(tester);

    await app.login(tester, password: 'errada123', expectSuccess: false);

    await app.login(tester);

    expect(find.byType(DashboardPage), findsOneWidget);
    expect(kpiValue(tester, 'Dispositivos ligados'), '1/3');
    expect(kpiValue(tester, 'Online'), '2/3');
    expect(kpiValue(tester, 'Alertas não lidos'), '1');
    expect(app.backend.pushTokens, {FakePushMessaging.token});
    app.expectNoUnhandledRoutes();
  });

  testWidgets('controlar dispositivo: toggle chega ao backend, a confirmação '
      'volta pelo WebSocket e o Início atualiza', (tester) async {
    final app = E2EApp();
    await app.launch(tester);
    await app.login(tester);
    await app.openRoom(tester);

    expect(switchOf(tester, 'd1').value, isFalse);
    expect(switchOf(tester, 'd3').onChanged, isNull, reason: 'offline');

    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('device-row-d1')),
        matching: find.byType(Switch),
      ),
    );
    await pumpUntil(tester, find.widgetWithText(KpiCard, '2/3'));

    expect(app.backend.log, contains('POST /devices/d1/control'));
    expect(app.backend.devices['d1']!['status'], 'ON');
    expect(switchOf(tester, 'd1').value, isTrue);
    expect(kpiValue(tester, 'Ligados'), '2/3');

    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text('Início'),
      ),
    );
    await pumpUntil(
      tester,
      find.widgetWithText(KpiCard, 'Dispositivos ligados'),
    );
    expect(kpiValue(tester, 'Dispositivos ligados'), '2/3');
    app.expectNoUnhandledRoutes();
  });

  testWidgets('push → deep link: tocar no alerta abre a sala com a ficha do '
      'dispositivo e marca o alerta como lido', (tester) async {
    final app = E2EApp();
    await app.launch(tester);
    await app.login(tester);

    app.push.tap(
      const PushMessage(
        title: 'Ar ligado fora do horário',
        notificationId: 'n1',
        link: '/devices/d2',
      ),
    );
    await pumpUntil(tester, find.byType(DeviceDetailSheet));

    expect(find.byType(RoomDetailPage), findsOneWidget);
    expect(find.byType(DeviceDetailSheet), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(DeviceDetailSheet),
        // nome do dispositivo (e o rótulo do tipo, que coincide aqui)
        matching: find.text('Ar-condicionado'),
      ),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byType(DeviceDetailSheet),
        matching: find.text('23 °C'),
      ),
      findsOneWidget,
    );
    expect(app.backend.log, contains('PATCH /notifications/n1/read'));
    expect(app.backend.notifications.single['read'], isTrue);
    app.expectNoUnhandledRoutes();
  });

  testWidgets('VIEWER: navega e vê o estado, mas as ações não aparecem', (
    tester,
  ) async {
    final app = E2EApp();
    await app.launch(tester);
    await app.login(
      tester,
      email: 'viewer@autouni.edu.br',
      password: 'View@123',
    );
    await app.openRoom(tester);

    expect(find.byKey(const Key('room-turn-off-all')), findsNothing);
    expect(switchOf(tester, 'd2').value, isTrue);
    expect(switchOf(tester, 'd2').onChanged, isNull);
    expect(app.backend.log.where((r) => r.contains('/control')), isEmpty);
  });

  testWidgets('logout: volta ao login e remove o token de push', (
    tester,
  ) async {
    final app = E2EApp();
    await app.launch(tester);
    await app.login(tester);
    expect(app.backend.pushTokens, isNotEmpty);

    await tester.tap(
      find.descendant(
        of: find.byType(AppBottomNav),
        matching: find.text('Ajustes'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('settings-logout')),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.byKey(const Key('settings-logout')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sair'));
    await pumpUntil(tester, find.byType(LoginPage));
    expect(app.backend.pushTokens, isEmpty);
    expect(app.backend.log, contains('POST /auth/logout'));
  });
}
