import 'dart:async';

import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/files/file_actions.dart';
import 'package:autouni_app/core/network/api_client.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/features/reports/data/reports_repository.dart';
import 'package:autouni_app/features/reports/domain/report_models.dart';
import 'package:autouni_app/features/reports/domain/report_request.dart';
import 'package:autouni_app/features/reports/presentation/providers/reports_providers.dart';
import 'package:autouni_app/shared/models/user_role.dart';
import 'package:autouni_app/shared/rbac/rbac_providers.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements ReportsRepository {}

class _MockFiles extends Mock implements FileActions {}

Report _report(String id, ReportStatus status) => Report(
  id: id,
  type: ReportType.energyConsumption,
  title: 'Consumo $id',
  format: ReportFormat.pdf,
  status: status,
  filters: const {'startDate': '2026-10-01', 'endDate': '2026-10-31'},
);

final _october = ReportPeriod(DateTime(2026, 10), DateTime(2026, 10, 31));

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

  ProviderContainer build({UserRole role = UserRole.coordinator}) {
    final container = ProviderContainer.test(
      overrides: [
        reportsRepositoryProvider.overrideWithValue(repository),
        fileActionsProvider.overrideWithValue(files),
        currentUserRoleProvider.overrideWithValue(role),
      ],
    );
    container.listen(myReportsProvider, (_, _) {});
    return container;
  }

  setUp(() {
    repository = _MockRepository();
    files = _MockFiles();
  });

  group('acompanhamento da geração (polling)', () {
    test('com relatório na fila, consulta até ficar pronto e para', () {
      fakeAsync((async) {
        when(() => repository.watchMine()).thenAnswer(
          (_) => Stream.value(Cached([_report('r1', ReportStatus.pending)])),
        );
        final answers = [
          [_report('r1', ReportStatus.processing)],
          [_report('r1', ReportStatus.completed)],
        ];
        when(() => repository.fetchMine())
            .thenAnswer((_) async => answers.removeAt(0));
        final container = build();
        async.flushMicrotasks();

        ReportStatus status() =>
            container.read(myReportsProvider).value!.data.single.status;

        expect(status(), ReportStatus.pending);
        async.elapse(MyReports.pollInterval);
        expect(status(), ReportStatus.processing);
        async.elapse(MyReports.pollInterval);
        expect(status(), ReportStatus.completed);

        async.elapse(MyReports.pollInterval * 5);
        verify(() => repository.fetchMine()).called(2);
      });
    });

    test('sem nada em andamento, não consulta', () {
      fakeAsync((async) {
        when(() => repository.watchMine()).thenAnswer(
          (_) => Stream.value(Cached([_report('r1', ReportStatus.failed)])),
        );
        build();
        async.flushMicrotasks();

        async.elapse(const Duration(minutes: 1));

        verifyNever(() => repository.fetchMine());
      });
    });

    test('sem rede, tenta de novo cada vez mais devagar (até o teto)', () {
      fakeAsync((async) {
        when(() => repository.watchMine()).thenAnswer(
          (_) => Stream.value(Cached([_report('r1', ReportStatus.pending)])),
        );
        when(() => repository.fetchMine()).thenThrow(const NetworkException());
        final container = build();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 4)); // 1ª: 4 s
        async.elapse(const Duration(seconds: 8)); // 2ª: 8 s
        async.elapse(const Duration(seconds: 16)); // 3ª: 16 s
        async.elapse(const Duration(seconds: 30)); // 4ª: teto de 30 s
        verify(() => repository.fetchMine()).called(4);
        expect(
          container.read(myReportsProvider).value!.data.single.status,
          ReportStatus.pending,
        );
      });
    });
  });

  group('gerar', () {
    final request = ReportRequest(
      type: ReportType.energyConsumption,
      format: ReportFormat.xlsx,
      title: 'Consumo de outubro',
      period: _october,
    );

    test('cria, põe no topo da lista e começa a acompanhar', () {
      fakeAsync((async) {
        when(() => repository.watchMine()).thenAnswer(
          (_) =>
              Stream.value(Cached([_report('antigo', ReportStatus.completed)])),
        );
        when(() => repository.create(any()))
            .thenAnswer((_) async => _report('novo', ReportStatus.pending));
        when(() => repository.fetchMine()).thenAnswer(
          (_) async => [
            _report('novo', ReportStatus.completed),
            _report('antigo', ReportStatus.completed),
          ],
        );
        final container = build();
        async.flushMicrotasks();

        late CreateReportOutcome outcome;
        container
            .read(reportsControllerProvider)
            .create(request)
            .then((value) => outcome = value);
        async.flushMicrotasks();

        expect(outcome.isCreated, isTrue);
        expect(container.read(myReportsProvider).value!.data.map((r) => r.id), [
          'novo',
          'antigo',
        ]);
        async.elapse(MyReports.pollInterval);
        verify(() => repository.fetchMine()).called(1);
      });
    });

    test('pedido inválido não chama o backend', () async {
      when(() => repository.watchMine())
          .thenAnswer((_) => const Stream.empty());
      final container = build();

      final outcome = await container
          .read(reportsControllerProvider)
          .create(
            const ReportRequest(
              type: ReportType.incidents,
              format: ReportFormat.pdf,
              title: 'abc',
            ),
          );

      expect(outcome.errors.keys, containsAll(['title', 'period']));
      verifyNever(() => repository.create(any()));
    });

    test('VIEWER não gera relatórios', () async {
      when(() => repository.watchMine())
          .thenAnswer((_) => const Stream.empty());
      final container = build(role: UserRole.viewer);

      final outcome = await container
          .read(reportsControllerProvider)
          .create(request);

      expect(outcome.message, 'Seu perfil não permite gerar relatórios.');
      verifyNever(() => repository.create(any()));
    });

    test('erro do backend volta como mensagem', () async {
      when(() => repository.watchMine())
          .thenAnswer((_) => const Stream.empty());
      when(() => repository.create(any()))
          .thenThrow(const BadRequestException(message: 'title too short'));
      final container = build();

      final outcome = await container
          .read(reportsControllerProvider)
          .create(request);

      expect(outcome.message, 'title too short');
    });

    test('"Gerar de novo" repete os parâmetros do que falhou', () async {
      when(() => repository.watchMine())
          .thenAnswer((_) => const Stream.empty());
      when(() => repository.create(any()))
          .thenAnswer((_) async => _report('r2', ReportStatus.pending));
      final container = build();

      await container
          .read(reportsControllerProvider)
          .retry(_report('r1', ReportStatus.failed));

      final sent =
          verify(() => repository.create(captureAny())).captured.single
              as ReportRequest;
      expect(sent.period, _october);
      expect(sent.title, 'Consumo r1');
    });
  });

  group('abrir e compartilhar (S6-T4)', () {
    final ready = _report('r1', ReportStatus.completed);

    setUp(() {
      when(() => repository.watchMine())
          .thenAnswer((_) => const Stream.empty());
      when(() => repository.download('r1')).thenAnswer(
        (_) async => const DownloadedFile(bytes: [1, 2, 3], fileName: 'r1.pdf'),
      );
      when(() => files.saveTemporary(any(), any()))
          .thenAnswer((_) async => '/tmp/reports/Consumo_r1.pdf');
      when(() => files.exists(any())).thenAnswer((_) async => true);
      when(() => files.open(any(), mimeType: any(named: 'mimeType')))
          .thenAnswer((_) async => FileOpenResult.opened);
      when(
        () => files.share(
          any(),
          mimeType: any(named: 'mimeType'),
          subject: any(named: 'subject'),
        ),
      ).thenAnswer((_) async {});
    });

    test(
      'abrir baixa, salva com o nome do relatório e abre com o MIME certo',
      () async {
        final container = build();

        final error = await container
            .read(reportsControllerProvider)
            .open(ready);

        expect(error, isNull);
        verify(() => files.saveTemporary('Consumo_r1.pdf', [1, 2, 3]))
            .called(1);
        verify(
          () => files.open(
            '/tmp/reports/Consumo_r1.pdf',
            mimeType: 'application/pdf',
          ),
        ).called(1);
      },
    );

    test('segunda vez reaproveita o arquivo baixado', () async {
      final container = build();
      final controller = container.read(reportsControllerProvider);

      await controller.open(ready);
      await controller.share(ready);

      verify(() => repository.download('r1')).called(1);
      verify(
        () => files.share(
          '/tmp/reports/Consumo_r1.pdf',
          mimeType: 'application/pdf',
          subject: 'Consumo r1',
        ),
      ).called(1);
    });

    test('arquivo apagado pelo sistema é baixado de novo', () async {
      final container = build();
      final controller = container.read(reportsControllerProvider);
      await controller.open(ready);
      when(() => files.exists(any())).thenAnswer((_) async => false);

      await controller.open(ready);

      verify(() => repository.download('r1')).called(2);
    });

    test('sem app para o formato, sugere compartilhar', () async {
      when(() => files.open(any(), mimeType: any(named: 'mimeType')))
          .thenAnswer((_) async => FileOpenResult.noApp);
      final container = build();

      final error = await container
          .read(reportsControllerProvider)
          .open(ready.copyWith(format: ReportFormat.xlsx));

      expect(error, contains('Nenhum app instalado abre arquivos XLSX'));
    });

    test('relatório não pronto não baixa', () async {
      final container = build();

      final error = await container
          .read(reportsControllerProvider)
          .share(_report('r1', ReportStatus.processing));

      expect(error, 'O relatório ainda não está pronto.');
      verifyNever(() => repository.download(any()));
    });

    test('falha no download avisa e não marca como baixado', () async {
      when(() => repository.download('r1'))
          .thenThrow(const NotFoundException(message: 'Report file not found'));
      final container = build();

      final error = await container.read(reportsControllerProvider).open(ready);

      expect(error, 'Não foi possível baixar: Report file not found');
      expect(container.read(reportFilesProvider).paths, isEmpty);
      expect(container.read(reportFilesProvider).downloading, isEmpty);
    });

    test('marca o download em andamento', () async {
      final pending = Completer<DownloadedFile>();
      when(() => repository.download('r1')).thenAnswer((_) => pending.future);
      final container = build();

      final call = container.read(reportsControllerProvider).open(ready);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(reportFilesProvider).isDownloading('r1'), isTrue);

      pending.complete(const DownloadedFile(bytes: [1]));
      await call;
      expect(container.read(reportFilesProvider).isDownloading('r1'), isFalse);
    });
  });

  group('reportProvider', () {
    test('usa a lista quando o relatório está nela', () async {
      when(() => repository.watchMine()).thenAnswer(
        (_) => Stream.value(Cached([_report('r1', ReportStatus.completed)])),
      );
      final container = build();
      await container.read(myReportsProvider.future);

      final report = await container.read(reportProvider('r1').future);

      expect(report.status, ReportStatus.completed);
      verifyNever(() => repository.fetch(any()));
    });

    test('fora da lista, busca por id (deep link)', () async {
      when(() => repository.watchMine())
          .thenAnswer((_) => Stream.value(const Cached(<Report>[])));
      when(() => repository.fetch('r9'))
          .thenAnswer((_) async => _report('r9', ReportStatus.failed));
      final container = build();
      await container.read(myReportsProvider.future);

      final report = await container.read(reportProvider('r9').future);

      expect(report.id, 'r9');
    });

    test('fora da lista e ainda gerando, consulta de novo sozinho', () {
      fakeAsync((async) {
        when(() => repository.watchMine())
            .thenAnswer((_) => Stream.value(const Cached(<Report>[])));
        final answers = [
          _report('r9', ReportStatus.processing),
          _report('r9', ReportStatus.completed),
        ];
        when(() => repository.fetch('r9'))
            .thenAnswer((_) async => answers.removeAt(0));
        final container = build();
        container.listen(reportProvider('r9'), (_, _) {});
        async.flushMicrotasks();
        expect(
          container.read(reportProvider('r9')).value?.status,
          ReportStatus.processing,
        );

        async.elapse(MyReports.pollInterval);

        expect(
          container.read(reportProvider('r9')).value?.status,
          ReportStatus.completed,
        );
        async.elapse(MyReports.pollInterval * 3);
        verify(() => repository.fetch('r9')).called(2);
      });
    });
  });
}
