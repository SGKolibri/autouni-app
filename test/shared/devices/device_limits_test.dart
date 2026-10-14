import 'package:autouni_app/shared/devices/device_limits.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dimmer (0–100%)', () {
    test('aceita os limites e valores intermediários', () {
      for (final value in [0, 1, 50, 100]) {
        expect(DeviceLimits.validateIntensity(value), isNull, reason: '$value');
      }
    });

    for (final value in [-1, 101, 50.5]) {
      test('recusa $value', () {
        expect(DeviceLimits.validateIntensity(value), isNotNull);
      });
    }

    test('clamp arredonda e prende na faixa', () {
      expect(DeviceLimits.clampIntensity(-10), 0);
      expect(DeviceLimits.clampIntensity(42.6), 43);
      expect(DeviceLimits.clampIntensity(140), 100);
    });
  });

  group('termostato (16–30 °C)', () {
    test('aceita os limites', () {
      expect(DeviceLimits.validateTemperature(16), isNull);
      expect(DeviceLimits.validateTemperature(23.5), isNull);
      expect(DeviceLimits.validateTemperature(30), isNull);
    });

    for (final value in [15.9, 30.1, -50, 150, double.nan]) {
      test('recusa $value', () {
        expect(
          DeviceLimits.validateTemperature(value),
          'A temperatura vai de 16 °C a 30 °C.',
        );
      });
    }

    test('clamp prende na faixa no passo de 1 °C', () {
      expect(DeviceLimits.clampTemperature(10), 16);
      expect(DeviceLimits.clampTemperature(22.4), 22);
      expect(DeviceLimits.clampTemperature(22.6), 23);
      expect(DeviceLimits.clampTemperature(35), 30);
    });
  });
}
