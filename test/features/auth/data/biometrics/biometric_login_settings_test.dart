import 'package:autouni_app/features/auth/data/biometrics/biometric_login_settings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('InMemoryBiometricLoginSettings', () {
    test('começa desligado e guarda a escolha', () async {
      final settings = InMemoryBiometricLoginSettings();
      expect(await settings.isEnabled(), isFalse);

      await settings.setEnabled(true);
      expect(await settings.isEnabled(), isTrue);

      await settings.setEnabled(false);
      expect(await settings.isEnabled(), isFalse);
    });
  });

  group('SecureBiometricLoginSettings', () {
    setUp(() => FlutterSecureStorage.setMockInitialValues({}));

    test('começa desligado', () async {
      expect(await SecureBiometricLoginSettings().isEnabled(), isFalse);
    });

    test('a escolha sobrevive a um restart', () async {
      await SecureBiometricLoginSettings().setEnabled(true);

      expect(await SecureBiometricLoginSettings().isEnabled(), isTrue);
    });

    test('desligar apaga a chave', () async {
      final settings = SecureBiometricLoginSettings();
      await settings.setEnabled(true);

      await settings.setEnabled(false);

      expect(await settings.isEnabled(), isFalse);
      expect(await const FlutterSecureStorage().readAll(), isEmpty);
    });

    test('falha de leitura do armazenamento conta como desligado', () async {
      final storage = _MockSecureStorage();
      when(() => storage.read(key: any(named: 'key')))
          .thenThrow(PlatformException(code: 'keystore'));

      expect(await SecureBiometricLoginSettings(storage).isEnabled(), isFalse);
    });
  });
}
