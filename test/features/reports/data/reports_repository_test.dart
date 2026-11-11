import 'package:autouni_app/core/cache/local_cache.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/features/reports/data/reports_repository.dart';
import 'package:autouni_app/features/reports/domain/report_models.dart';
import 'package:autouni_app/features/reports/domain/report_request.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/campus_fixtures.dart';
import '../../../support/fake_http_adapter.dart';

Map<String, dynamic> reportJson({
  String id = 'r1',
  String status = 'PENDING',
  String createdAt = '2026-11-10T10:00:00.000Z',
}) => {
  'id': id,
  'type': 'ENERGY_CONSUMPTION',
  'title': 'Consumo de outubro',
  'format': 'PDF',
  'filters': {'startDate': '2026-10-01', 'endDate': '2026-10-31'},
  'status': status,
  'createdById': 'u1',
  'createdAt': createdAt,
};

void main() {
  late Map<String, FakeResponse> responses;
  late FakeHttpAdapter adapter;
  late InMemoryLocalCache cache;

  HttpReportsRepository repository({String? userId = 'u1'}) =>
      HttpReportsRepository(
        dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
          ..httpClientAdapter = adapter,
        cache: cache,
        userId: userId,
      );

  setUp(() {
    responses = {};
    cache = InMemoryLocalCache();
    adapter = FakeHttpAdapter(
      (options) =>
          responses['${options.method} ${options.path}'] ?? FakeResponse(404),
    );
  });

  test(
    'lista pela rota do criador (não usa /reports/me), mais novos primeiro',
    () async {
      responses['GET /reports/creator/u1'] = FakeResponse(
        200,
        body: [
          reportJson(id: 'velho', createdAt: '2026-11-01T10:00:00.000Z'),
          reportJson(id: 'novo'),
        ],
      );

      final list = (await repository().watchMine().last).data;

      expect(list.map((r) => r.id), ['novo', 'velho']);
      expect(adapter.requests.single.path, '/reports/creator/u1');
    },
  );

  test('sem rede, mostra os relatórios salvos', () async {
    responses['GET /reports/creator/u1'] = FakeResponse(
      200,
      body: [reportJson()],
    );
    await repository().watchMine().last;
    responses['GET /reports/creator/u1'] = FakeResponse(503);

    final values = await repository().watchMine().toList();

    expect(values.last.offline, isTrue);
    expect(values.last.data.single.id, 'r1');
  });

  test('fetchMine vai à rede e atualiza o cache', () async {
    responses['GET /reports/creator/u1'] = FakeResponse(
      200,
      body: [reportJson(status: 'COMPLETED')],
    );

    final list = await repository().fetchMine();

    expect(list.single.status, ReportStatus.completed);
    expect(
      await cache.read(HttpReportsRepository.cacheKeyFor('u1')),
      isNotNull,
    );
  });

  test('cria com POST /reports e o usuário da sessão', () async {
    responses['POST /reports'] = FakeResponse(201, body: reportJson());

    final report = await repository().create(
      ReportRequest(
        type: ReportType.energyConsumption,
        format: ReportFormat.pdf,
        title: 'Consumo de outubro',
        period: ReportPeriod(DateTime(2026, 10), DateTime(2026, 10, 31)),
        buildingId: 'b1',
      ),
    );

    expect(report.status, ReportStatus.pending);
    final body = adapter.requests.single.data as Map;
    expect(body['createdById'], 'u1');
    expect(body['filters'], {
      'startDate': '2026-10-01',
      'endDate': '2026-10-31',
      'buildingId': 'b1',
    });
  });

  test('sem sessão: lista vazia e criar falha sem request', () async {
    final anonymous = repository(userId: null);

    expect((await anonymous.watchMine().single).data, isEmpty);
    await expectLater(
      anonymous.create(
        const ReportRequest(
          type: ReportType.roomUsage,
          format: ReportFormat.csv,
          title: 'Uso das salas',
        ),
      ),
      throwsA(isA<UnauthorizedException>()),
    );
    expect(adapter.requests, isEmpty);
  });

  test('busca um relatório por id', () async {
    responses['GET /reports/r1'] = FakeResponse(
      200,
      body: reportJson(status: 'PROCESSING'),
    );

    expect((await repository().fetch('r1')).status, ReportStatus.processing);
  });

  test(
    'prédios ordenados por nome, reaproveitando o cache de Ambientes',
    () async {
      await cache.write(HttpReportsRepository.buildingsCacheKey, [
        buildingJson(id: 'b2', name: 'Bloco B'),
      ]);
      responses['GET /buildings'] = FakeResponse(
        200,
        body: [
          buildingJson(id: 'b2', name: 'Bloco B'),
          buildingJson(id: 'b1', name: 'Bloco A'),
        ],
      );

      final buildings = await repository().buildings();

      expect(buildings.map((b) => b.name), ['Bloco A', 'Bloco B']);
    },
  );

  test('download pela rota do relatório', () async {
    responses['GET /reports/r1/download'] = FakeResponse(
      200,
      body: '%PDF-1.4',
      headers: {
        'content-type': ['application/pdf'],
        'content-disposition': ['attachment; filename="r1.pdf"'],
      },
    );

    final file = await repository().download('r1');

    expect(file.fileName, 'r1.pdf');
    expect(String.fromCharCodes(file.bytes), '%PDF-1.4');
  });
}
