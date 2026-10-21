import 'package:autouni_app/core/biometrics/biometric_authenticator.dart';
import 'package:autouni_app/core/biometrics/local_auth_biometric_authenticator.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class _MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late _MockLocalAuthentication localAuth;
  late LocalAuthBiometricAuthenticator authenticator;

  When<Future<bool>> whenAuthenticate() => when(
    () => localAuth.authenticate(
      localizedReason: any(named: 'localizedReason'),
      biometricOnly: any(named: 'biometricOnly'),
      persistAcrossBackgrounding: any(named: 'persistAcrossBackgrounding'),
    ),
  );

  setUp(() {
    localAuth = _MockLocalAuthentication();
    authenticator = LocalAuthBiometricAuthenticator(localAuth);
  });

  group('isAvailable', () {
    test('true com hardware suportado e biometria cadastrada', () async {
      when(() => localAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => localAuth.getAvailableBiometrics())
          .thenAnswer((_) async => [BiometricType.fingerprint]);

      expect(await authenticator.isAvailable(), isTrue);
    });

    test('false quando o aparelho não suporta', () async {
      when(() => localAuth.isDeviceSupported()).thenAnswer((_) async => false);

      expect(await authenticator.isAvailable(), isFalse);
      verifyNever(() => localAuth.getAvailableBiometrics());
    });

    test('false sem nenhuma biometria cadastrada', () async {
      when(() => localAuth.isDeviceSupported()).thenAnswer((_) async => true);
      when(() => localAuth.getAvailableBiometrics())
          .thenAnswer((_) async => []);

      expect(await authenticator.isAvailable(), isFalse);
    });

    test('false quando o plugin falha (plataforma sem suporte)', () async {
      when(() => localAuth.isDeviceSupported())
          .thenThrow(MissingPluginException());

      expect(await authenticator.isAvailable(), isFalse);
    });
  });

  group('authenticate', () {
    test('pede só biometria, com o motivo informado', () async {
      whenAuthenticate().thenAnswer((_) async => true);

      final result = await authenticator.authenticate(reason: 'Entrar');

      expect(result, BiometricAuthResult.success);
      verify(
        () => localAuth.authenticate(
          localizedReason: 'Entrar',
          biometricOnly: true,
          persistAcrossBackgrounding: true,
        ),
      ).called(1);
    });

    test('biometria não reconhecida vira failed', () async {
      whenAuthenticate().thenAnswer((_) async => false);

      expect(
        await authenticator.authenticate(reason: 'Entrar'),
        BiometricAuthResult.failed,
      );
    });

    for (final (code, expected) in [
      (LocalAuthExceptionCode.userCanceled, BiometricAuthResult.failed),
      (LocalAuthExceptionCode.systemCanceled, BiometricAuthResult.failed),
      (LocalAuthExceptionCode.timeout, BiometricAuthResult.failed),
      (LocalAuthExceptionCode.temporaryLockout, BiometricAuthResult.lockedOut),
      (LocalAuthExceptionCode.biometricLockout, BiometricAuthResult.lockedOut),
      (
        LocalAuthExceptionCode.noBiometricsEnrolled,
        BiometricAuthResult.unavailable,
      ),
      (
        LocalAuthExceptionCode.noBiometricHardware,
        BiometricAuthResult.unavailable,
      ),
      (LocalAuthExceptionCode.deviceError, BiometricAuthResult.unavailable),
    ]) {
      test('LocalAuthException ${code.name} vira ${expected.name}', () async {
        whenAuthenticate().thenThrow(LocalAuthException(code: code));

        expect(await authenticator.authenticate(reason: 'Entrar'), expected);
      });
    }

    test('falha do plugin vira unavailable', () async {
      whenAuthenticate().thenThrow(PlatformException(code: 'boom'));

      expect(
        await authenticator.authenticate(reason: 'Entrar'),
        BiometricAuthResult.unavailable,
      );
    });
  });
}
