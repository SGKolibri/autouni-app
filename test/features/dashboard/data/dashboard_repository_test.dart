import 'package:autouni_app/core/cache/local_cache.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/features/dashboard/data/dashboard_repository.dart';
import 'package:autouni_app/shared/models/notification_type.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/campus_fixtures.dart';
import '../../../support/fake_http_adapter.dart';

void main() {
  late InMemoryLocalCache cache;
  late Map<String, FakeResponse> responses;
  late FakeHttpAdapter adapter;
  late HttpDashboardRepository repository;

  setUp(() {
    cache = InMemoryLocalCache();
    responses = {
      '/buildings': FakeResponse(
        200,
        body: [
          buildingJson(
            floors: [
              floorJson(
                rooms: [
                  roomJson(devices: [deviceJson(status: 'ON')]),
                ],
              ),
            ],
          ),
        ],
      ),
      '/energy/stats': FakeResponse(
        200,
        body: {'todayEnergyKwh': 42.5, 'hasData': true, 'count': 10},
      ),
      '/notifications/me': FakeResponse(
        200,
        body: [
          {
            'id': 'n1',
            'type': 'WARNING',
            'title': 'Ar ligado fora do horário',
            'message': 'Sala 101',
            'read': false,
            'createdAt': '2026-10-14T08:00:00.000Z',
          },
          {
            'id': 'n2',
            'type': 'SUCCESS',
            'title': 'Automação executada',
            'message': '',
            'read': true,
            'createdAt': '2026-10-14T09:00:00.000Z',
          },
        ],
      ),
    };
    adapter = FakeHttpAdapter(
      (options) => responses[options.path] ?? FakeResponse(404),
    );
    repository = HttpDashboardRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
      cache: cache,
    );
  });

  test('junta prédios, consumo de hoje e alertas', () async {
    final overview = (await repository.watchOverview().last).data;

    expect(overview.buildings.single.name, 'Bloco A');
    expect(overview.allDevices.single.isOn, isTrue);
    expect(overview.energy?.todayEnergyKwh, 42.5);
    expect(overview.alerts.map((a) => a.id), ['n2', 'n1']);
    expect(overview.alerts.last.type, NotificationType.warning);
    expect(overview.unreadAlerts, 1);

    final energyRequest = adapter.requests.firstWhere(
      (r) => r.path == '/energy/stats',
    );
    expect(energyRequest.queryParameters, {'period': 'today'});
  });

  test('consumo e alertas são opcionais', () async {
    responses['/energy/stats'] = FakeResponse(500);
    responses['/notifications/me'] = FakeResponse(403);

    final overview = (await repository.watchOverview().last).data;

    expect(overview.buildings, hasLength(1));
    expect(overview.energy, isNull);
    expect(overview.alerts, isEmpty);
  });

  test('sem os prédios, o dashboard falha', () async {
    responses['/buildings'] = FakeResponse(500);

    await expectLater(
      repository.watchOverview(),
      emitsError(isA<ServerException>()),
    );
  });

  test('abre do cache sem rede', () async {
    await repository.watchOverview().last;
    responses.clear();
    responses['/buildings'] = FakeResponse(503);

    final values = await repository.watchOverview().toList();

    expect(values.last.offline, isTrue);
    expect(values.last.data.energy?.todayEnergyKwh, 42.5);
  });
}
