import 'dart:async';

import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/features/automations/data/automations_repository.dart';
import 'package:autouni_app/features/automations/domain/automation_models.dart';
import 'package:autouni_app/features/automations/presentation/pages/automations_page.dart';
import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:autouni_app/shared/models/user_role.dart';
import 'package:autouni_app/shared/rbac/rbac_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/automation_fixtures.dart';
import '../../../support/pump_router_app.dart';

class _MockRepository extends Mock implements AutomationsRepository {}

void main() {
  late _MockRepository repository;

  final nightly = Automation.fromJson(
    automationJson(id: 'a1', cron: '30 7 * * 1-5'),
  );
  final manual = Automation.fromJson(
    automationJson(
      id: 'a2',
      triggerType: 'MANUAL',
      cron: null,
      enabled: false,
      lastRunAt: '2026-10-20T22:00:00.000Z',
    ),
  );

  setUp(() {
    repository = _MockRepository();
    when(() => repository.watchAll())
        .thenAnswer((_) => Stream.value(Cached([nightly, manual])));
  });

  Future<GoRouter> pumpPage(
    WidgetTester tester, {
    UserRole role = UserRole.technician,
  }) async {
    final (_, router) = await tester.pumpRouterApp(
      initialLocation: '/automations',
      routes: [
        GoRoute(
          path: '/automations',
          builder: (_, _) => const AutomationsPage(),
        ),
        stubRoute(AppPaths.newAutomation),
        stubRoute(AppPaths.automation('a1')),
      ],
      overrides: [
        automationsRepositoryProvider.overrideWithValue(repository),
        currentUserRoleProvider.overrideWithValue(role),
      ],
    );
    await tester.pumpAndSettle();
    return router;
  }

  Switch switchOf(WidgetTester tester, String id) =>
      tester.widget<Switch>(find.byKey(ValueKey('automation-switch-$id')));

  testWidgets('lista com quando roda, o que faz e se está ativa', (
    tester,
  ) async {
    await pumpPage(tester);

    expect(find.text('Seg a Sex às 07:30'), findsOneWidget);
    expect(find.text('Execução manual'), findsOneWidget);
    expect(find.text('Desligar Luminária 1'), findsNWidgets(2));
    expect(find.textContaining('Última execução'), findsOneWidget);
    expect(switchOf(tester, 'a1').value, isTrue);
    expect(switchOf(tester, 'a2').value, isFalse);
  });

  testWidgets('toggle muda na hora e chama PATCH /toggle (S5-T3)', (
    tester,
  ) async {
    final response = Completer<Automation>();
    when(() => repository.setEnabled('a1', enabled: false))
        .thenAnswer((_) => response.future);
    await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('automation-switch-a1')));
    await tester.pump();

    expect(switchOf(tester, 'a1').value, isFalse);
    expect(switchOf(tester, 'a1').onChanged, isNull);

    response.complete(nightly.copyWith(enabled: false));
    await tester.pumpAndSettle();

    expect(switchOf(tester, 'a1').value, isFalse);
    verify(() => repository.setEnabled('a1', enabled: false)).called(1);
  });

  testWidgets('toggle com erro volta e avisa', (tester) async {
    when(() => repository.setEnabled('a1', enabled: false))
        .thenThrow(const NetworkException());
    await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('automation-switch-a1')));
    await tester.pumpAndSettle();

    expect(switchOf(tester, 'a1').value, isTrue);
    expect(find.text('Sem conexão com a internet.'), findsOneWidget);
  });

  testWidgets('tocar abre o detalhe; FAB abre a criação', (tester) async {
    final router = await pumpPage(tester);

    await tester.tap(find.byKey(const ValueKey('automation-a1')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppPaths.automation('a1'));

    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('automation-new')));
    await tester.pumpAndSettle();
    expect(router.state.uri.path, AppPaths.newAutomation);
  });

  testWidgets('VIEWER: sem chave, sem criar — só o selo de status', (
    tester,
  ) async {
    await pumpPage(tester, role: UserRole.viewer);

    expect(find.byType(Switch), findsNothing);
    expect(find.byKey(const Key('automation-new')), findsNothing);
    expect(
      tester
          .widget<StatusBadge>(
            find.byKey(const ValueKey('automation-status-a1')),
          )
          .label,
      'Ativa',
    );
    expect(
      tester
          .widget<StatusBadge>(
            find.byKey(const ValueKey('automation-status-a2')),
          )
          .label,
      'Pausada',
    );
  });

  testWidgets('vazio: convida a criar (quem pode)', (tester) async {
    when(() => repository.watchAll())
        .thenAnswer((_) => Stream.value(const Cached(<Automation>[])));
    final router = await pumpPage(tester);

    expect(find.text('Nenhuma automação'), findsOneWidget);
    await tester.tap(find.text('Criar automação'));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppPaths.newAutomation);
  });

  testWidgets('vazio para VIEWER não oferece criar', (tester) async {
    when(() => repository.watchAll())
        .thenAnswer((_) => Stream.value(const Cached(<Automation>[])));
    await pumpPage(tester, role: UserRole.viewer);

    expect(find.text('Ainda não há rotinas cadastradas.'), findsOneWidget);
    expect(find.text('Criar automação'), findsNothing);
  });

  testWidgets('erro sem cache: tentar de novo', (tester) async {
    var calls = 0;
    when(() => repository.watchAll()).thenAnswer((_) {
      calls++;
      return calls == 1
          ? Stream.error(const ServerException(message: 'Fora do ar'))
          : Stream.value(Cached([nightly]));
    });
    await pumpPage(tester);

    expect(find.text('Fora do ar'), findsOneWidget);
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('automation-a1')), findsOneWidget);
  });
}
