import 'package:autouni_app/core/cache/local_cache.dart';
import 'package:autouni_app/features/environments/data/environments_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/campus_fixtures.dart';
import '../../../support/fake_http_adapter.dart';

void main() {
  late InMemoryLocalCache cache;
  late FakeHttpAdapter adapter;
  late HttpEnvironmentsRepository repository;
  var offline = false;

  setUp(() {
    offline = false;
    cache = InMemoryLocalCache();
    adapter = FakeHttpAdapter((options) {
      if (offline) {
        throw DioException.connectionError(
          requestOptions: options,
          reason: 'sem rede',
        );
      }
      return switch (options.path) {
        '/buildings' => FakeResponse(200, body: [buildingJson()]),
        '/buildings/b1' => FakeResponse(200, body: buildingJson()),
        '/floors/building/b1' => FakeResponse(200, body: [floorJson()]),
        '/floors/f1' => FakeResponse(200, body: floorJson()),
        '/rooms/floor/f1' => FakeResponse(200, body: [roomJson()]),
        '/rooms/r1/details' => FakeResponse(
          200,
          body: roomJson(devices: [deviceJson()]),
        ),
        _ => FakeResponse(404),
      };
    });
    repository = HttpEnvironmentsRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
      cache: cache,
    );
  });

  test('cada nível usa o endpoint do contrato', () async {
    expect((await repository.watchBuildings().last).data.single.id, 'b1');
    expect((await repository.watchBuilding('b1').last).data.name, 'Bloco A');
    expect((await repository.watchFloors('b1').last).data.single.id, 'f1');
    expect((await repository.watchFloor('f1').last).data.number, 1);
    expect((await repository.watchRooms('f1').last).data.single.id, 'r1');
    expect(
      (await repository.watchRoom('r1').last).data.devices.single.id,
      'd1',
    );

    expect(adapter.requests.map((r) => r.path), [
      '/buildings',
      '/buildings/b1',
      '/floors/building/b1',
      '/floors/f1',
      '/rooms/floor/f1',
      '/rooms/r1/details',
    ]);
  });

  test('abre sem rede com o último estado salvo (S3-T5)', () async {
    await repository.watchBuildings().last;
    await repository.watchRoom('r1').last;
    offline = true;

    final buildings = await repository.watchBuildings().last;
    final room = await repository.watchRoom('r1').last;

    expect(buildings.offline, isTrue);
    expect(buildings.data.single.name, 'Bloco A');
    expect(room.data.devices.single.id, 'd1');
  });

  test('cada recurso tem a própria entrada de cache', () async {
    await repository.watchRoom('r1').last;
    offline = true;

    await expectLater(repository.watchFloors('b1'), emitsError(anything));
  });
}
