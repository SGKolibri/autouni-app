import 'package:autouni_app/features/devices/domain/device_filter.dart';
import 'package:autouni_app/shared/models/campus/campus_enums.dart';
import 'package:autouni_app/shared/models/campus/campus_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/campus_fixtures.dart';

void main() {
  const sala101 = Room(
    id: 'r1',
    floorId: 'f1',
    name: 'Sala 101',
    floor: Floor(
      id: 'f1',
      buildingId: 'b1',
      number: 1,
      building: Building(id: 'b1', name: 'Bloco Ácido'),
    ),
  );
  final devices = [
    device(id: 'a', name: 'Projetor', type: DeviceType.projector),
    device(
      id: 'b',
      name: 'Ar-condicionado',
      type: DeviceType.ac,
      status: DeviceStatus.on,
      room: sala101,
    ),
    device(id: 'c', name: 'luminária', status: DeviceStatus.on, online: false),
    device(
      id: 'd',
      name: 'Sensor',
      type: DeviceType.sensor,
      status: DeviceStatus.error,
    ),
  ];

  List<String> ids(DeviceFilter filter) =>
      filterDevices(devices, filter).map((d) => d.id).toList();

  test('sem filtro devolve tudo, ordenado por nome (sem acento/caixa)', () {
    expect(ids(const DeviceFilter()), ['b', 'c', 'a', 'd']);
  });

  group('busca', () {
    test('ignora maiúsculas e acentos', () {
      expect(ids(const DeviceFilter(query: 'LUMINARIA')), ['c']);
    });

    test('procura na localização e combina termos', () {
      expect(ids(const DeviceFilter(query: 'sala 101')), ['b']);
      expect(ids(const DeviceFilter(query: 'acido ar')), ['b']);
      expect(ids(const DeviceFilter(query: 'acido projetor')), isEmpty);
    });

    test('procura pelo rótulo do tipo', () {
      expect(ids(const DeviceFilter(query: 'iluminação')), ['c']);
    });
  });

  group('filtros', () {
    test('status (vários = qualquer um deles)', () {
      expect(ids(const DeviceFilter(statuses: {DeviceStatus.on})), ['b', 'c']);
      expect(
        ids(
          const DeviceFilter(statuses: {DeviceStatus.on, DeviceStatus.error}),
        ),
        ['b', 'c', 'd'],
      );
    });

    test('tipo', () {
      expect(ids(const DeviceFilter(types: {DeviceType.ac})), ['b']);
    });

    test('disponibilidade', () {
      expect(
        ids(const DeviceFilter(availability: AvailabilityFilter.offline)),
        ['c'],
      );
      expect(ids(const DeviceFilter(availability: AvailabilityFilter.online)), [
        'b',
        'a',
        'd',
      ]);
    });

    test('combinados com a busca', () {
      expect(
        ids(
          const DeviceFilter(
            query: 'ar',
            statuses: {DeviceStatus.on},
            availability: AvailabilityFilter.online,
          ),
        ),
        ['b'],
      );
    });
  });

  test('activeCount e isEmpty', () {
    const filter = DeviceFilter(
      query: 'x',
      statuses: {DeviceStatus.on},
      types: {DeviceType.ac, DeviceType.light},
      availability: AvailabilityFilter.online,
    );
    expect(filter.activeCount, 4);
    expect(filter.isEmpty, isFalse);
    expect(const DeviceFilter(query: '  ').isEmpty, isTrue);
  });

  group('DevicePage', () {
    final many = [for (var i = 0; i < 977; i++) device(id: '$i')];

    test('primeira página com 30 e indica que há mais', () {
      final page = DevicePage.of(many, 30);
      expect(page.items, hasLength(30));
      expect(page.total, 977);
      expect(page.hasMore, isTrue);
    });

    test('última página não tem mais', () {
      final page = DevicePage.of(many, 990);
      expect(page.items, hasLength(977));
      expect(page.hasMore, isFalse);
    });
  });
}
