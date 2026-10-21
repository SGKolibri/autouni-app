import 'package:autouni_app/core/cache/local_cache.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/features/energy/data/energy_repository.dart';
import 'package:autouni_app/features/energy/domain/energy_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/fake_http_adapter.dart';

void main() {
  late InMemoryLocalCache cache;
  late Map<String, FakeResponse> responses;
  late FakeHttpAdapter adapter;
  late HttpEnergyRepository repository;
  final now = DateTime(2026, 10, 21, 14, 30);

  const building = EnergyScope(
    level: EnergyLevel.building,
    id: 'b1',
    name: 'Bloco A',
  );

  Map<String, dynamic> historyBody() => {
    'history': [
      {'bucket': '2026-10-21T12:00:00.000Z', 'totalKwh': 2.0, 'count': 4},
      {'bucket': '2026-10-21T13:00:00.000Z', 'totalKwh': 3.5, 'count': 6},
    ],
    'period': {'label': 'today'},
    'level': 'general',
  };

  setUp(() {
    cache = InMemoryLocalCache();
    responses = {
      '/energy/stats': FakeResponse(
        200,
        body: {
          'totalKwh': 48.5,
          'count': 120,
          'avgWh': 250.0,
          'maxWh': 1500.0,
          'totalDevices': 40,
          'activeDevices': 12,
          'hasData': true,
        },
      ),
      '/energy/buildings/b1/stats': FakeResponse(
        200,
        body: {'totalKwh': 12.0, 'count': 30, 'avgWh': 400.0},
      ),
      '/energy/history': FakeResponse(200, body: historyBody()),
      '/energy/comparison': FakeResponse(
        200,
        body: {
          'comparison': [
            {'id': 'b1', 'name': 'Bloco A', 'totalKwh': 12.0, 'count': 30},
            {'id': 'b2', 'name': 'Bloco B', 'totalKwh': 20.0, 'count': 50},
          ],
          'level': 'general',
        },
      ),
    };
    adapter = FakeHttpAdapter(
      (options) => responses[options.path] ?? FakeResponse(404),
    );
    repository = HttpEnergyRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
      cache: cache,
      now: () => now,
    );
  });

  RequestOptions request(String path) =>
      adapter.requests.firstWhere((r) => r.path == path);

  test('campus: stats por período, histórico e ranking de prédios', () async {
    final overview =
        (await repository
                .watchOverview(const EnergyScope.campus(), EnergyPeriod.today)
                .last)
            .data;

    expect(overview.stats.totalKwh, 48.5);
    expect(overview.stats.activeDevices, 12);
    expect(overview.history, hasLength(2));
    expect(overview.history.last.totalKwh, 3.5);
    expect(overview.sortedRanking.map((i) => i.id), ['b2', 'b1']);
    expect(overview.period, EnergyPeriod.today);

    expect(request('/energy/stats').queryParameters, {'period': 'today'});
    expect(request('/energy/history').queryParameters, {
      'period': 'today',
      'level': 'general',
    });
    expect(request('/energy/comparison').queryParameters, {
      'period': 'today',
      'level': 'general',
    });
  });

  test('prédio: stats da rota do nível com o intervalo do período', () async {
    final overview =
        (await repository.watchOverview(building, EnergyPeriod.week).last).data;

    expect(overview.stats.totalKwh, 12);
    expect(overview.stats.totalDevices, isNull);
    expect(request('/energy/buildings/b1/stats').queryParameters, {
      'from': DateTime(2026, 10, 15).toUtc().toIso8601String(),
      'to': now.toUtc().toIso8601String(),
    });
    expect(request('/energy/history').queryParameters, {
      'period': 'week',
      'level': 'building',
      'id': 'b1',
    });
    expect(request('/energy/comparison').queryParameters, {
      'period': 'week',
      'level': 'building',
      'id': 'b1',
    });
  });

  for (final (level, path) in [
    (EnergyLevel.floor, '/energy/floors/x/stats'),
    (EnergyLevel.room, '/energy/rooms/x/stats'),
    (EnergyLevel.device, '/energy/devices/x/stats'),
  ]) {
    test('${level.apiValue}: stats em $path', () async {
      responses[path] = FakeResponse(200, body: {'totalKwh': 1, 'count': 1});

      await repository
          .watchOverview(
            EnergyScope(level: level, id: 'x', name: 'X'),
            EnergyPeriod.month,
          )
          .last;

      expect(adapter.requests.map((r) => r.path), contains(path));
    });
  }

  test('dispositivo não tem ranking (folha)', () async {
    responses['/energy/devices/d1/stats'] = FakeResponse(
      200,
      body: {'totalKwh': 1, 'count': 2},
    );

    final overview =
        (await repository
                .watchOverview(
                  const EnergyScope(
                    level: EnergyLevel.device,
                    id: 'd1',
                    name: 'Ar',
                  ),
                  EnergyPeriod.today,
                )
                .last)
            .data;

    expect(overview.ranking, isNull);
    expect(
      adapter.requests.map((r) => r.path),
      isNot(contains('/energy/comparison')),
    );
  });

  test('ranking é opcional: falha vira null', () async {
    responses['/energy/comparison'] = FakeResponse(500);

    final overview =
        (await repository
                .watchOverview(const EnergyScope.campus(), EnergyPeriod.today)
                .last)
            .data;

    expect(overview.stats.totalKwh, 48.5);
    expect(overview.ranking, isNull);
  });

  test('sem stats ou histórico, a tela falha', () async {
    responses['/energy/history'] = FakeResponse(503);

    await expectLater(
      repository.watchOverview(const EnergyScope.campus(), EnergyPeriod.today),
      emitsError(isA<ServerException>()),
    );
  });

  test('abre do cache sem rede, por escopo e período', () async {
    await repository.watchOverview(building, EnergyPeriod.today).last;
    responses.clear();

    final values = await repository
        .watchOverview(building, EnergyPeriod.today)
        .toList();

    expect(values.last.offline, isTrue);
    expect(values.last.data.stats.totalKwh, 12);

    await expectLater(
      repository.watchOverview(building, EnergyPeriod.month),
      emitsError(isA<NotFoundException>()),
    );
  });
}
