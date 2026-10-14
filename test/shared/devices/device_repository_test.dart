import 'package:autouni_app/core/cache/local_cache.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/shared/devices/device_commands.dart';
import 'package:autouni_app/shared/devices/device_repository.dart';
import 'package:autouni_app/shared/models/campus/campus_enums.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/campus_fixtures.dart';
import '../../support/fake_http_adapter.dart';

void main() {
  late InMemoryLocalCache cache;

  (HttpDeviceRepository, FakeHttpAdapter) build(
    FakeResponse Function(RequestOptions) handler,
  ) {
    final adapter = FakeHttpAdapter(handler);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
    return (HttpDeviceRepository(dio: dio, cache: cache), adapter);
  }

  setUp(() => cache = InMemoryLocalCache());

  group('watchAll', () {
    test('GET /devices, grava no cache e devolve os dispositivos', () async {
      final (repository, adapter) = build(
        (_) => FakeResponse(
          200,
          body: [
            deviceJson(),
            deviceJson(id: 'd2'),
          ],
        ),
      );

      final values = await repository.watchAll().toList();

      expect(adapter.requests.single.path, '/devices');
      expect(values.single.data.map((d) => d.id), ['d1', 'd2']);
      expect(
        await cache.read(HttpDeviceRepository.allDevicesCacheKey),
        isNotNull,
      );
    });

    test('sem rede, lê a lista do cache', () async {
      await cache.write(HttpDeviceRepository.allDevicesCacheKey, [
        deviceJson(),
      ]);
      final (repository, _) = build(
        (options) => throw DioException.connectionError(
          requestOptions: options,
          reason: 'sem rede',
        ),
      );

      final values = await repository.watchAll().toList();

      expect(values.last.offline, isTrue);
      expect(values.last.data.single.id, 'd1');
    });
  });

  group('control', () {
    test('POST /devices/:id/control com comando e ajustes', () async {
      final (repository, adapter) = build(
        (_) => FakeResponse(
          200,
          body: {
            ...deviceJson(status: 'ON'),
            'pending': true,
          },
        ),
      );

      final result = await repository.control(
        'd1',
        command: DeviceCommand.on,
        intensity: 60,
      );

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.path, '/devices/d1/control');
      expect(request.data, {'command': 'on', 'intensity': 60});
      expect(result.device.status, DeviceStatus.on);
      expect(result.pending, isTrue);
    });

    test('sem ajustes, envia só o comando', () async {
      final (repository, adapter) = build(
        (_) => FakeResponse(200, body: deviceJson()),
      );

      final result = await repository.control('d1', command: DeviceCommand.off);

      expect(adapter.requests.single.data, {'command': 'off'});
      expect(result.pending, isFalse);
    });

    test('falha vira ApiException', () async {
      final (repository, _) = build((_) => FakeResponse(404));

      await expectLater(
        repository.control('d1', command: DeviceCommand.off),
        throwsA(isA<NotFoundException>()),
      );
    });
  });

  test('bulkControl envia os ids e lê o resultado', () async {
    final (repository, adapter) = build(
      (_) => FakeResponse(
        200,
        body: {
          'message': "Command 'off' applied to 1 of 2 device(s)",
          'successCount': 1,
          'failedCount': 1,
          'failedDevices': ['d2'],
        },
      ),
    );

    final result = await repository.bulkControl([
      'd1',
      'd2',
    ], command: DeviceCommand.off);

    expect(adapter.requests.single.path, '/devices/bulk-control');
    expect(adapter.requests.single.data, {
      'deviceIds': ['d1', 'd2'],
      'command': 'off',
    });
    expect(result.successCount, 1);
    expect(result.failedDevices, ['d2']);
  });
}
