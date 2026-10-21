import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/features/automations/data/automations_repository.dart';
import 'package:autouni_app/features/automations/domain/automation_models.dart';
import 'package:autouni_app/features/automations/presentation/pages/automation_detail_page.dart';
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

  final automation = Automation.fromJson(
    automationJson(id: 'a1', cron: '30 7 * * 1-5'),
  );
  final runs = [
    AutomationRun(
      id: 'h2',
      runAt: DateTime(2026, 10, 21, 7, 30),
      success: false,
      logs: 'Error: MQTT connection failed',
    ),
    AutomationRun(
      id: 'h1',
      runAt: DateTime(2026, 10, 20, 7, 30),
      success: true,
      logs: 'Executed successfully',
    ),
  ];

  setUp(() {
    repository = _MockRepository();
    when(() => repository.watchOne('a1'))
        .thenAnswer((_) => Stream.value(Cached(automation)));
    when(() => repository.watchHistory('a1'))
        .thenAnswer((_) => Stream.value(Cached(runs)));
    when(() => repository.watchAll())
        .thenAnswer((_) => Stream.value(Cached([automation])));
  });

  Future<GoRouter> pumpDetail(
    WidgetTester tester, {
    UserRole role = UserRole.technician,
    bool fromList = true,
  }) async {
    tester.view.physicalSize = const Size(800, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (_, router) = await tester.pumpRouterApp(
      initialLocation: '/automations',
      routes: [
        GoRoute(
          path: '/automations',
          builder: (_, _) => const Scaffold(body: Text('lista')),
          routes: [
            GoRoute(
              path: ':id',
              builder: (_, state) => AutomationDetailPage(
                automationId: state.pathParameters['id']!,
              ),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (_, _) => const Scaffold(body: Text('edição')),
                ),
              ],
            ),
          ],
        ),
      ],
      overrides: [
        automationsRepositoryProvider.overrideWithValue(repository),
        currentUserRoleProvider.overrideWithValue(role),
      ],
    );
    if (fromList) {
      router.push(AppPaths.automation('a1'));
    } else {
      router.go(AppPaths.automation('a1'));
    }
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('mostra quando roda, o que faz e o histórico (S5-T3)', (
    tester,
  ) async {
    await pumpDetail(tester);

    expect(find.text('Desligar luzes à noite'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('automation-trigger'))).data,
      'Seg a Sex às 07:30',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('automation-action'))).data,
      'Desligar Luminária 1',
    );
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Nunca executada'), findsOneWidget);
    expect(find.text('Falhou'), findsOneWidget);
    expect(find.textContaining('MQTT connection failed'), findsOneWidget);
    expect(find.text('Sucesso'), findsOneWidget);
    expect(find.textContaining('21/10/2026 07:30'), findsOneWidget);
    expect(find.text('20/10/2026 07:30'), findsOneWidget);
  });

  testWidgets('executar pede confirmação e chama POST /execute', (
    tester,
  ) async {
    when(() => repository.execute('a1')).thenAnswer((_) async {});
    await pumpDetail(tester);

    await tester.tap(find.byKey(const Key('automation-execute')));
    await tester.pumpAndSettle();
    expect(find.text('Executar agora?'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-execute')));
    await tester.pumpAndSettle();

    verify(() => repository.execute('a1')).called(1);
    expect(find.text('Automação executada.'), findsOneWidget);
    // recarrega o histórico
    verify(() => repository.watchHistory('a1')).called(2);
  });

  testWidgets('cancelar a execução não chama o backend', (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.byKey(const Key('automation-execute')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.execute(any()));
  });

  testWidgets('erro na execução vira aviso', (tester) async {
    when(
      () => repository.execute('a1'),
    ).thenThrow(const BadRequestException(message: 'Automation is disabled'));
    await pumpDetail(tester);

    await tester.tap(find.byKey(const Key('automation-execute')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-execute')));
    await tester.pumpAndSettle();

    expect(find.text('Automation is disabled'), findsOneWidget);
  });

  testWidgets('desativada: executar fica indisponível', (tester) async {
    when(() => repository.watchOne('a1')).thenAnswer(
      (_) => Stream.value(Cached(automation.copyWith(enabled: false))),
    );
    await pumpDetail(tester);

    final button = tester.widget<ButtonStyleButton>(
      find.byKey(const Key('automation-execute')),
    );
    expect(button.onPressed, isNull);
    expect(find.text('Ative para executar agora'), findsOneWidget);
  });

  testWidgets('excluir confirma, chama DELETE e volta para a lista (S5-T5)', (
    tester,
  ) async {
    when(() => repository.delete('a1')).thenAnswer((_) async {});
    final router = await pumpDetail(tester);

    await tester.tap(find.byKey(const Key('automation-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Excluir automação?'), findsOneWidget);
    expect(find.textContaining('não pode ser desfeita'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();

    verify(() => repository.delete('a1')).called(1);
    expect(router.state.uri.path, '/automations');
    expect(find.text('Automação excluída.'), findsOneWidget);
  });

  testWidgets('excluir vindo de deep link volta para a aba', (tester) async {
    when(() => repository.delete('a1')).thenAnswer((_) async {});
    final router = await pumpDetail(tester, fromList: false);

    await tester.tap(find.byKey(const Key('automation-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, '/automations');
  });

  testWidgets('cancelar a exclusão mantém a automação', (tester) async {
    await pumpDetail(tester);

    await tester.tap(find.byKey(const Key('automation-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(() => repository.delete(any()));
    expect(find.text('Desligar luzes à noite'), findsOneWidget);
  });

  testWidgets('falha ao excluir avisa e fica na tela', (tester) async {
    when(() => repository.delete('a1')).thenThrow(const NetworkException());
    final router = await pumpDetail(tester);

    await tester.tap(find.byKey(const Key('automation-delete')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();

    expect(find.text('Sem conexão com a internet.'), findsOneWidget);
    expect(router.state.uri.path, AppPaths.automation('a1'));
  });

  testWidgets('editar abre o formulário', (tester) async {
    final router = await pumpDetail(tester);

    await tester.tap(find.byKey(const Key('automation-edit')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppPaths.editAutomation('a1'));
  });

  testWidgets('VIEWER vê tudo, mas sem executar, editar ou excluir', (
    tester,
  ) async {
    await pumpDetail(tester, role: UserRole.viewer);

    expect(find.text('Seg a Sex às 07:30'), findsOneWidget);
    expect(find.byKey(const Key('automation-execute')), findsNothing);
    expect(find.byKey(const Key('automation-edit')), findsNothing);
    expect(find.byKey(const Key('automation-delete')), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('histórico vazio', (tester) async {
    when(() => repository.watchHistory('a1'))
        .thenAnswer((_) => Stream.value(const Cached(<AutomationRun>[])));
    await pumpDetail(tester);

    expect(find.text('Nenhuma execução ainda.'), findsOneWidget);
  });

  testWidgets('histórico com erro oferece tentar de novo', (tester) async {
    var calls = 0;
    when(() => repository.watchHistory('a1')).thenAnswer((_) {
      calls++;
      return calls == 1
          ? Stream.error(const ServerException(message: 'Histórico fora'))
          : Stream.value(Cached(runs));
    });
    await pumpDetail(tester);

    expect(find.text('Histórico fora'), findsOneWidget);
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('Sucesso'), findsOneWidget);
  });
}
