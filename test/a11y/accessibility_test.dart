import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/core/router/app_router.dart';
import 'package:autouni_app/routing/app_router_provider.dart';
import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/e2e/critical_flows.dart';

/// Diretrizes de acessibilidade do Flutter nas telas principais (S6-T6):
/// alvo de toque mínimo (48 dp Android / 44 pt iOS), alvos tocáveis com
/// rótulo para leitores de tela e contraste de texto (WCAG AA).
Future<void> expectAccessible(WidgetTester tester) async {
  final handle = tester.ensureSemantics();
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  handle.dispose();
  // Requests disparadas durante a checagem terminam antes do fim do teste.
  await tester.pumpAndSettle();
}

Future<void> goTo(WidgetTester tester, String location) async {
  final element = tester.element(find.byType(MaterialApp));
  ProviderScope.containerOf(element).read(appRouterProvider).go(location);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login', (tester) async {
    final app = E2EApp();
    await app.launch(tester);

    await expectAccessible(tester);
  });

  final screens = <String, String>{
    'Início': AppRoutes.initial,
    'Ambientes': '/environments',
    'Sala (dispositivos)': AppPaths.room('b1', 'f1', 'r1'),
    'Lista global de dispositivos': AppPaths.allDevices,
    'Alertas': '/notifications',
    'Ajustes': '/settings',
    'Perfil': AppPaths.profile,
    'Trocar senha': AppPaths.changePassword,
    'Relatórios': AppPaths.reportsRoot,
    'Gerar relatório': AppPaths.newReport,
  };

  for (final MapEntry(key: name, value: location) in screens.entries) {
    testWidgets(name, (tester) async {
      final app = E2EApp();
      await app.launch(tester);
      await app.login(tester);

      await goTo(tester, location);
      expect(find.byType(AppTopBar), findsWidgets);

      await expectAccessible(tester);
    });
  }

  testWidgets('ficha do dispositivo (dimmer)', (tester) async {
    final app = E2EApp();
    await app.launch(tester);
    await app.login(tester);
    await goTo(tester, AppPaths.room('b1', 'f1', 'r1', deviceId: 'd1'));

    await expectAccessible(tester);
  });

  testWidgets('tema escuro: Início', (tester) async {
    final app = E2EApp();
    await app.launch(tester);
    await app.login(tester);
    await goTo(tester, '/settings');
    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();
    await goTo(tester, AppRoutes.initial);

    await expectAccessible(tester);
  });
}
