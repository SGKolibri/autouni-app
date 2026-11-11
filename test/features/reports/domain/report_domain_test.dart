import 'package:autouni_app/features/reports/domain/report_models.dart';
import 'package:autouni_app/features/reports/domain/report_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 11, 11, 15, 30);

  group('Report.fromJson', () {
    test('lê o relatório do backend', () {
      final report = Report.fromJson(const {
        'id': 'r1',
        'type': 'ENERGY_CONSUMPTION',
        'title': 'Consumo de Outubro',
        'format': 'XLSX',
        'filters': {'startDate': '2026-10-01', 'endDate': '2026-10-31'},
        'status': 'COMPLETED',
        'fileUrl': '/app/uploads/reports/r1.xlsx',
        'createdById': 'u1',
        'createdAt': '2026-11-01T10:00:00.000Z',
        'createdBy': {'id': 'u1', 'name': 'Ana'},
      });

      expect(report.type, ReportType.energyConsumption);
      expect(report.format, ReportFormat.xlsx);
      expect(report.status, ReportStatus.completed);
      expect(report.canDownload, isTrue);
      expect(report.filters['startDate'], '2026-10-01');
      expect(report.createdAt, DateTime.utc(2026, 11, 1, 10));
    });

    test('valores desconhecidos e campos ausentes têm fallback', () {
      final report = Report.fromJson(const {
        'id': 'r2',
        'type': 'NOVO',
        'title': 'Algo',
        'format': 'DOCX',
      });

      expect(report.type, ReportType.deviceStatus);
      expect(report.format, ReportFormat.pdf);
      expect(report.status, ReportStatus.pending);
      expect(report.filters, isEmpty);
      expect(report.canDownload, isFalse);
    });

    test('status em andamento', () {
      expect(ReportStatus.pending.inProgress, isTrue);
      expect(ReportStatus.processing.inProgress, isTrue);
      expect(ReportStatus.completed.inProgress, isFalse);
      expect(ReportStatus.failed.inProgress, isFalse);
    });

    test('nome de arquivo seguro com a extensão do formato', () {
      Report named(String title, ReportFormat format) => Report(
        id: 'r9',
        type: ReportType.incidents,
        title: title,
        format: format,
      );

      expect(
        named('Consumo · Outubro/2026: Bloco A', ReportFormat.csv).fileName,
        'Consumo_Outubro2026_Bloco_A.csv',
      );
      expect(named('???', ReportFormat.pdf).fileName, 'relatorio_r9.pdf');
    });
  });

  group('ReportPeriod', () {
    test('atalhos a partir de hoje (dias inteiros)', () {
      expect(
        ReportPeriod.of(ReportPeriodPreset.last7Days, today),
        ReportPeriod(DateTime(2026, 11, 5), DateTime(2026, 11, 11)),
      );
      expect(ReportPeriod.of(ReportPeriodPreset.last30Days, today)!.days, 30);
      expect(
        ReportPeriod.of(ReportPeriodPreset.thisMonth, today),
        ReportPeriod(DateTime(2026, 11), DateTime(2026, 11, 11)),
      );
      expect(
        ReportPeriod.of(ReportPeriodPreset.lastMonth, today),
        ReportPeriod(DateTime(2026, 10), DateTime(2026, 10, 31)),
      );
      expect(ReportPeriod.of(ReportPeriodPreset.custom, today), isNull);
    });

    test('mês passado em janeiro volta para dezembro do ano anterior', () {
      expect(
        ReportPeriod.of(ReportPeriodPreset.lastMonth, DateTime(2027, 1, 5)),
        ReportPeriod(DateTime(2026, 12), DateTime(2026, 12, 31)),
      );
    });

    test('rótulo e formato da API', () {
      final period = ReportPeriod(DateTime(2026, 10), DateTime(2026, 10, 31));

      expect(period.label, '01/10 a 31/10/2026');
      expect(ReportPeriod.apiDate(period.start), '2026-10-01');
    });
  });

  group('ReportRequest', () {
    final october = ReportPeriod(DateTime(2026, 10), DateTime(2026, 10, 31));

    ReportRequest request({
      ReportType type = ReportType.energyConsumption,
      String title = 'Consumo de outubro',
      ReportPeriod? period,
      String? buildingId,
    }) => ReportRequest(
      type: type,
      format: ReportFormat.pdf,
      title: title,
      period: period,
      buildingId: buildingId,
    );

    test('JSON de POST /reports com período e prédio', () {
      expect(
        request(period: october, buildingId: 'b1').toJson(createdById: 'u1'),
        {
          'type': 'ENERGY_CONSUMPTION',
          'format': 'PDF',
          'title': 'Consumo de outubro',
          'createdById': 'u1',
          'filters': {
            'startDate': '2026-10-01',
            'endDate': '2026-10-31',
            'buildingId': 'b1',
          },
        },
      );
    });

    test('tipos de retrato atual não mandam período', () {
      final json = request(
        type: ReportType.deviceStatus,
        period: october,
      ).toJson(createdById: 'u1');

      expect(json['filters'], isEmpty);
    });

    test('válido sem erros', () {
      expect(request(period: october).validate(today: today), isEmpty);
      expect(
        request(type: ReportType.roomUsage).validate(today: today),
        isEmpty,
      );
    });

    test('título curto', () {
      expect(
        request(title: ' abc ', period: october).validate(today: today),
        containsPair('title', isNotEmpty),
      );
    });

    for (final (label, period, message) in [
      ('sem período', null, 'Escolha o período.'),
      (
        'fim antes do início',
        ReportPeriod(DateTime(2026, 10, 10), DateTime(2026, 10, 1)),
        'A data final é anterior à inicial.',
      ),
      (
        'começa no futuro',
        ReportPeriod(DateTime(2026, 11, 12), DateTime(2026, 11, 20)),
        'O período não pode começar no futuro.',
      ),
      (
        'mais de um ano',
        ReportPeriod(DateTime(2025, 1), DateTime(2026, 10, 1)),
        'O período vai até 366 dias.',
      ),
    ]) {
      test('período inválido: $label', () {
        expect(
          request(period: period).validate(today: today)['period'],
          message,
        );
      });
    }

    test('título sugerido', () {
      expect(
        ReportRequest.suggestTitle(
          type: ReportType.energyConsumption,
          period: october,
          buildingName: 'Bloco A',
        ),
        'Consumo de energia · 01/10 a 31/10/2026 · Bloco A',
      );
      expect(
        ReportRequest.suggestTitle(type: ReportType.roomUsage, period: october),
        'Uso das salas · Campus',
      );
    });

    test('refaz o pedido de um relatório existente', () {
      final again = ReportRequest.fromReport(
        const Report(
          id: 'r1',
          type: ReportType.incidents,
          title: 'Incidentes de outubro',
          format: ReportFormat.csv,
          filters: {
            'startDate': '2026-10-01',
            'endDate': '2026-10-31',
            'buildingId': 'b1',
          },
        ),
      );

      expect(again.type, ReportType.incidents);
      expect(again.format, ReportFormat.csv);
      expect(again.period, october);
      expect(again.buildingId, 'b1');
    });
  });
}
