import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/files/file_actions.dart';
import 'package:autouni_app/core/network/api_client.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/features/reports/data/reports_repository.dart';
import 'package:autouni_app/features/reports/domain/report_models.dart';
import 'package:autouni_app/features/reports/domain/report_request.dart';
import 'package:autouni_app/features/reports/presentation/pages/new_report_page.dart';
import 'package:autouni_app/features/reports/presentation/pages/report_detail_page.dart';
import 'package:autouni_app/features/reports/presentation/pages/reports_page.dart';
import 'package:autouni_app/shared/models/campus/campus_models.dart';
import 'package:autouni_app/shared/models/user_role.dart';
import 'package:autouni_app/shared/rbac/rbac_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/pump_router_app.dart';

class _MockRepository extends Mock implements ReportsRepository {}

class _MockFiles extends Mock implements FileActions {}

Report _report(
  String id,
  ReportStatus status, {
  ReportFormat format = ReportFormat.pdf,
  Map<String, dynamic> filters = const {
    'startDate': '2026-10-01',
    'endDate': '2026-10-31',
    'buildingId': 'b1',
  },
}) => Report(
  id: id,
  type: ReportType.energyConsumption,
  title: 'Relatório $id',
  format: format,
  status: status,
  filters: filters,
  createdAt: DateTime(2026, 11, 10, 9),
);

void main() {
  late _MockRepository repository;
  late _MockFiles files;

  setUpAll(() {
    registerFallbackValue(
      const ReportRequest(
        type: ReportType.roomUsage,
        format: ReportFormat.pdf,
        title: 'fallback',
      ),
    );
  });

  setUp(() {
    repository = _MockRepository();
    files = _MockFiles();
    when(() => repository.buildings()).thenAnswer(
      (_) async => const [
        Building(id: 'b1', name: 'Bloco A'),
        Building(id: 'b2', name: 'Bloco B'),
      ],
    );
    when(() => repository.fetchMine()).thenAnswer((_) async => []);
  });

  void listReturns(List<Report> reports) =>
      when(() => repository.watchMine())
          .thenAnswer((_) => Stream.value(Cached(reports)));

  late ProviderContainer container;

  Future<GoRouter> pump(
    WidgetTester tester, {
    required String location,
    UserRole role = UserRole.coordinator,
  }) async {
    tester.view.physicalSize = const Size(900, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (pumped, router) = await tester.pumpRouterApp(
      initialLocation: location,
      routes: [
        GoRoute(
          path: AppPaths.reportsRoot,
          builder: (_, _) => const ReportsPage(),
          routes: [
            GoRoute(
              path: 'new',
              builder: (_, _) =>
                  NewReportPage(now: () => DateTime(2026, 11, 11)),
            ),
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  ReportDetailPage(reportId: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
      overrides: [
        reportsRepositoryProvider.overrideWithValue(repository),
        fileActionsProvider.overrideWithValue(files),
        currentUserRoleProvider.overrideWithValue(role),
      ],
    );
    container = pumped;
    await tester.pumpAndSettle();
    return router;
  }

  /// Relatórios em andamento deixam o polling agendado: descarta antes do
  /// fim do teste.
  void stopPolling() => container.dispose();

  group('lista (S6-T3)', () {
    testWidgets('mostra o status de cada relatório', (tester) async {
      listReturns([
        _report('a', ReportStatus.pending),
        _report('b', ReportStatus.processing),
        _report('c', ReportStatus.completed),
        _report('d', ReportStatus.failed),
      ]);
      await pump(tester, location: AppPaths.reportsRoot);

      for (final label in ['Na fila', 'Gerando', 'Pronto', 'Falhou']) {
        expect(find.text(label), findsOneWidget, reason: label);
      }
      expect(find.byKey(const ValueKey('report-open-c')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-share-c')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-retry-d')), findsOneWidget);
      expect(find.byKey(const ValueKey('report-open-a')), findsNothing);
      expect(find.byKey(const ValueKey('report-open-b')), findsNothing);
      stopPolling();
    });

    testWidgets('vazio convida a gerar', (tester) async {
      listReturns([]);
      final router = await pump(tester, location: AppPaths.reportsRoot);

      expect(find.text('Nenhum relatório'), findsOneWidget);
      await tester.tap(find.byKey(const Key('reports-new')));
      await tester.pumpAndSettle();
      expect(router.state.uri.path, AppPaths.newReport);
    });

    testWidgets('VIEWER baixa, mas não gera nem refaz', (tester) async {
      listReturns([
        _report('c', ReportStatus.completed),
        _report('d', ReportStatus.failed),
      ]);
      await pump(tester, location: AppPaths.reportsRoot, role: UserRole.viewer);

      expect(find.byKey(const Key('reports-new')), findsNothing);
      expect(find.byKey(const ValueKey('report-retry-d')), findsNothing);
      expect(find.byKey(const ValueKey('report-open-c')), findsOneWidget);
    });

    testWidgets('erro sem cache mostra o estado de erro', (tester) async {
      when(() => repository.watchMine())
          .thenAnswer((_) => Stream.error(const NetworkException()));
      await pump(tester, location: AppPaths.reportsRoot);

      expect(find.text('Sem conexão com a internet.'), findsOneWidget);
    });
  });

  group('abrir e compartilhar com arquivo mockado (S6-T4)', () {
    setUp(() {
      listReturns([_report('c', ReportStatus.completed)]);
      when(
        () => repository.download('c'),
      ).thenAnswer((_) async => const DownloadedFile(bytes: [37, 80, 68, 70]));
      when(() => files.saveTemporary(any(), any()))
          .thenAnswer((_) async => '/tmp/reports/Relatório_c.pdf');
      when(() => files.exists(any())).thenAnswer((_) async => true);
    });

    testWidgets('compartilhar baixa e abre a share sheet', (tester) async {
      when(
        () => files.share(
          any(),
          mimeType: any(named: 'mimeType'),
          subject: any(named: 'subject'),
        ),
      ).thenAnswer((_) async {});
      await pump(tester, location: AppPaths.reportsRoot);

      await tester.tap(find.byKey(const ValueKey('report-share-c')));
      await tester.pumpAndSettle();

      verify(() => files.saveTemporary('Relatório_c.pdf', [37, 80, 68, 70]))
          .called(1);
      verify(
        () => files.share(
          '/tmp/reports/Relatório_c.pdf',
          mimeType: 'application/pdf',
          subject: 'Relatório c',
        ),
      ).called(1);
    });

    testWidgets('abrir sem app para o formato avisa', (tester) async {
      when(() => files.open(any(), mimeType: any(named: 'mimeType')))
          .thenAnswer((_) async => FileOpenResult.noApp);
      await pump(tester, location: AppPaths.reportsRoot);

      await tester.tap(find.byKey(const ValueKey('report-open-c')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Nenhum app instalado'), findsOneWidget);
    });
  });

  group('detalhe', () {
    testWidgets('mostra parâmetros e ações do relatório pronto', (
      tester,
    ) async {
      listReturns([_report('c', ReportStatus.completed)]);
      await pump(tester, location: AppPaths.report('c'));

      expect(find.text('Relatório c'), findsWidgets);
      expect(find.text('Consumo de energia'), findsOneWidget);
      expect(find.text('01/10 a 31/10/2026'), findsOneWidget);
      expect(find.text('Bloco A'), findsOneWidget);
      expect(find.byKey(const Key('report-open')), findsOneWidget);
      expect(find.byKey(const Key('report-share')), findsOneWidget);
    });

    testWidgets('deep link de relatório fora da lista busca por id', (
      tester,
    ) async {
      listReturns([]);
      when(() => repository.fetch('x')).thenAnswer(
        (_) async => _report('x', ReportStatus.processing, filters: const {}),
      );
      await pump(tester, location: AppPaths.report('x'));

      expect(find.text('Gerando'), findsOneWidget);
      expect(find.text('Campus inteiro'), findsOneWidget);
      expect(find.textContaining('atualiza sozinha'), findsOneWidget);
      stopPolling();
    });

    testWidgets('falhou: gerar de novo', (tester) async {
      listReturns([_report('d', ReportStatus.failed)]);
      when(() => repository.create(any()))
          .thenAnswer((_) async => _report('e', ReportStatus.pending));
      await pump(tester, location: AppPaths.report('d'));

      await tester.tap(find.byKey(const Key('report-retry')));
      await tester.pumpAndSettle();

      verify(() => repository.create(any())).called(1);
      expect(find.text('Relatório na fila de novo.'), findsOneWidget);
      stopPolling();
    });
  });

  group('gerar (formulário)', () {
    setUp(() => listReturns([]));

    testWidgets('sugere o título e envia tipo, período, local e formato', (
      tester,
    ) async {
      when(() => repository.create(any()))
          .thenAnswer((_) async => _report('novo', ReportStatus.pending));
      final router = await pump(tester, location: AppPaths.newReport);

      expect(
        find.text('Consumo de energia · 01/11 a 11/11/2026 · Campus'),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('report-period-lastMonth')));
      await tester.tap(find.byKey(const Key('report-building')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bloco A').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('XLSX'));
      await tester.pumpAndSettle();
      expect(
        find.text('Consumo de energia · 01/10 a 31/10/2026 · Bloco A'),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const Key('report-submit')));
      await tester.pumpAndSettle();

      final sent =
          verify(() => repository.create(captureAny())).captured.single
              as ReportRequest;
      expect(sent.type, ReportType.energyConsumption);
      expect(sent.format, ReportFormat.xlsx);
      expect(sent.buildingId, 'b1');
      expect(
        sent.period,
        ReportPeriod(DateTime(2026, 10), DateTime(2026, 10, 31)),
      );
      expect(router.state.uri.path, AppPaths.reportsRoot);
      expect(find.textContaining('Relatório na fila'), findsOneWidget);
    });

    testWidgets('tipo de retrato atual esconde o período', (tester) async {
      await pump(tester, location: AppPaths.newReport);

      await tester.tap(find.byKey(const ValueKey('report-type-roomUsage')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('report-period-lastMonth')),
        findsNothing,
      );
      expect(find.textContaining('Retrato do momento'), findsOneWidget);
      expect(find.text('Uso das salas · Campus'), findsOneWidget);
    });

    testWidgets('título editado não é mais sobrescrito', (tester) async {
      await pump(tester, location: AppPaths.newReport);

      await tester.enterText(
        find.byKey(const Key('report-title')),
        'Meu título',
      );
      await tester.tap(find.byKey(const ValueKey('report-type-incidents')));
      await tester.pumpAndSettle();

      expect(find.text('Meu título'), findsOneWidget);
    });

    testWidgets('título curto mostra o erro e não envia', (tester) async {
      await pump(tester, location: AppPaths.newReport);

      await tester.enterText(find.byKey(const Key('report-title')), 'abc');
      await tester.tap(find.byKey(const Key('report-submit')));
      await tester.pumpAndSettle();

      expect(find.textContaining('pelo menos 5'), findsOneWidget);
      verifyNever(() => repository.create(any()));
    });

    testWidgets('erro do backend mantém o formulário e avisa', (tester) async {
      when(() => repository.create(any()))
          .thenThrow(const ServerException(message: 'Erro no servidor.'));
      final router = await pump(tester, location: AppPaths.newReport);

      await tester.tap(find.byKey(const Key('report-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Erro no servidor.'), findsOneWidget);
      expect(router.state.uri.path, AppPaths.newReport);
    });

    testWidgets('VIEWER não vê o formulário', (tester) async {
      await pump(tester, location: AppPaths.newReport, role: UserRole.viewer);

      expect(find.text('Somente leitura'), findsOneWidget);
      expect(find.byKey(const Key('report-submit')), findsNothing);
    });
  });
}
