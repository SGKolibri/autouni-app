import 'package:autouni_app/shared/realtime/telemetry_events.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const empty = LiveTelemetry();

  test('energy:update keeps voltage, current and power per device', () {
    final s = reduceTelemetry(empty, TelemetryEventNames.energy, {
      'deviceId': 'd1',
      'power': 150,
      'energy': 0.4,
      'voltage': 220.5,
      'current': 0.68,
      'timestamp': '2026-11-17T12:00:00Z',
    });
    expect(s.energy['d1']!.voltage, 220.5);
    expect(s.energy['d1']!.current, 0.68);
    expect(s.energy['d1']!.powerW, 150);
  });

  test('sensor:alarm opens and clears', () {
    final alarm = {
      'id': 'a1',
      'level': 'CRITICAL',
      'value': 1900,
      'threshold': 1800,
    };
    var s = reduceTelemetry(empty, TelemetryEventNames.alarm, {
      'deviceId': 'g1',
      'state': 'opened',
      'alarm': alarm,
    });
    expect(s.alarms['g1']!.isCritical, isTrue);
    s = reduceTelemetry(s, TelemetryEventNames.alarm, {
      'deviceId': 'g1',
      'state': 'cleared',
      'alarm': {...alarm, 'clearedAt': '2026-11-17T12:05:00Z'},
    });
    expect(s.alarms.containsKey('g1'), isFalse);
  });

  test('sensor:update and room:occupancy', () {
    var s = reduceTelemetry(empty, TelemetryEventNames.sensor, {
      'deviceId': 'g1',
      'kind': 'GAS_MQ135',
      'value': 640,
      'unit': 'adc',
    });
    s = reduceTelemetry(s, TelemetryEventNames.occupancy, {
      'roomId': 'r1',
      'occupied': true,
    });
    expect(s.sensors['g1']!.value, 640);
    expect(s.occupancy['r1'], isTrue);
  });

  test('ignores malformed payloads', () {
    expect(
      reduceTelemetry(empty, TelemetryEventNames.energy, 'x'),
      same(empty),
    );
    expect(
      reduceTelemetry(empty, TelemetryEventNames.sensor, {'deviceId': 'd'}),
      same(empty),
    );
  });
}
