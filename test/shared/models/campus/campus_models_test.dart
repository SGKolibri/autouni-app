import 'package:autouni_app/shared/models/campus/campus_enums.dart';
import 'package:autouni_app/shared/models/campus/campus_models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dispositivo como em `GET /devices` (com a localização aninhada).
const _deviceJson = <String, dynamic>{
  'id': 'd1',
  'name': 'Luminária 1',
  'roomId': 'r1',
  'type': 'LIGHT',
  'status': 'ON',
  'online': true,
  'mqttTopic': 'bloco-a/1/101/lum-1',
  'metadata': {'brand': 'Philips', 'power': 40, 'intensity': 75},
  'lastSeen': '2026-10-14T10:00:00.000Z',
  'createdAt': '2026-01-01T00:00:00.000Z',
  'updatedAt': '2026-10-14T10:00:00.000Z',
  'room': {
    'id': 'r1',
    'floorId': 'f1',
    'name': 'Sala 101',
    'type': 'CLASSROOM',
    'floor': {
      'id': 'f1',
      'buildingId': 'b1',
      'number': 1,
      'name': null,
      'building': {'id': 'b1', 'name': 'Bloco A', 'location': 'Campus I'},
    },
  },
};

/// Prédio como em `GET /buildings` (árvore + resumo de consumo).
const _buildingJson = <String, dynamic>{
  'id': 'b1',
  'name': 'Bloco A',
  'description': null,
  'location': 'Campus I',
  'totalEnergy': 12.5,
  'activeDevices': 3,
  'totalDevices': 8,
  'todayEnergyKwh': 12,
  'dailyConsumptionKwh': 12,
  'energyPeriod': 'today',
  'lastReadingAt': null,
  'floors': [
    {
      'id': 'f1',
      'buildingId': 'b1',
      'number': 0,
      'rooms': [
        {
          'id': 'r1',
          'floorId': 'f1',
          'name': 'Sala 101',
          'type': 'LAB',
          'devices': [_deviceJson],
        },
      ],
    },
  ],
};

void main() {
  group('enums', () {
    test('lêem os valores da API e têm rótulo', () {
      expect(DeviceType.fromApi('AC'), DeviceType.ac);
      expect(DeviceStatus.fromApi('STANDBY'), DeviceStatus.standby);
      expect(DeviceStatus.on.label, 'Ligado');
      expect(RoomType.lab.label, 'Laboratório');
    });

    test('valores desconhecidos caem no fallback seguro', () {
      expect(DeviceType.fromApi('DRONE'), DeviceType.other);
      expect(DeviceStatus.fromApi('BROKEN'), DeviceStatus.off);
      expect(DeviceStatus.fromApi(null), DeviceStatus.off);
    });
  });

  group('Device.fromJson', () {
    test('lê o dispositivo completo com a localização', () {
      final device = Device.fromJson(_deviceJson);

      expect(device.id, 'd1');
      expect(device.type, DeviceType.light);
      expect(device.status, DeviceStatus.on);
      expect(device.isOn, isTrue);
      expect(device.online, isTrue);
      expect(device.mqttTopic, 'bloco-a/1/101/lum-1');
      expect(device.lastSeen, DateTime.utc(2026, 10, 14, 10));
      expect(device.locationLabel, 'Sala 101 · 1º andar · Bloco A');
    });

    test('extrai intensidade, temperatura e potência do metadata', () {
      final light = Device.fromJson(_deviceJson);
      expect(light.intensity, 75);
      expect(light.powerWatts, 40);
      expect(light.temperature, isNull);

      final ac = Device.fromJson({
        ..._deviceJson,
        'type': 'AC',
        'metadata': {'temperature': 22, 'powerRating': 1500},
      });
      expect(ac.temperature, 22.0);
      expect(ac.powerWatts, 1500);
      expect(ac.intensity, isNull);
    });

    test('limita a intensidade a 0–100', () {
      final device = Device.fromJson({
        ..._deviceJson,
        'metadata': {'intensity': 180},
      });

      expect(device.intensity, 100);
    });

    test('aceita o mínimo: sem metadata, sem sala, enums desconhecidos', () {
      final device = Device.fromJson(const {
        'id': 'd2',
        'name': 'Sensor',
        'roomId': 'r1',
        'type': 'DRONE',
        'status': 'BROKEN',
      });

      expect(device.type, DeviceType.other);
      expect(device.status, DeviceStatus.off);
      expect(device.online, isFalse);
      expect(device.metadata, isNull);
      expect(device.intensity, isNull);
      expect(device.locationLabel, isNull);
    });
  });

  group('Building.fromJson', () {
    test('lê o prédio com a árvore e o resumo de consumo', () {
      final building = Building.fromJson(_buildingJson);

      expect(building.name, 'Bloco A');
      expect(building.location, 'Campus I');
      expect(building.totalDevices, 8);
      expect(building.activeDevices, 3);
      expect(building.todayEnergyKwh, 12.0);
      expect(building.floors.single.rooms.single.type, RoomType.lab);
      expect(
        building.floors.single.rooms.single.devices.single.name,
        'Luminária 1',
      );
    });

    test('GET /buildings/:id sem relações nem resumo usa os defaults', () {
      final building = Building.fromJson(const {'id': 'b1', 'name': 'A'});

      expect(building.floors, isEmpty);
      expect(building.totalDevices, 0);
      expect(building.location, '');
    });
  });

  group('Floor.displayName', () {
    Floor floor(int number, [String? name]) =>
        Floor(id: 'f', buildingId: 'b', number: number, name: name);

    test('usa o nome cadastrado', () {
      expect(floor(2, 'Mezanino').displayName, 'Mezanino');
    });

    test('sem nome, deriva do número', () {
      expect(floor(0).displayName, 'Térreo');
      expect(floor(3).displayName, '3º andar');
      expect(floor(1, '  ').displayName, '1º andar');
    });
  });

  test('Room.fromJson aceita tipo desconhecido', () {
    final room = Room.fromJson(const {
      'id': 'r',
      'floorId': 'f',
      'name': 'Copa',
      'type': 'KITCHEN',
    });

    expect(room.type, RoomType.other);
  });
}
