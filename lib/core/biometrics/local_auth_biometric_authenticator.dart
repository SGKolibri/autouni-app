import 'package:local_auth/local_auth.dart';

import 'biometric_authenticator.dart';

/// [BiometricAuthenticator] sobre o plugin `local_auth` (Face ID / Touch ID /
/// BiometricPrompt).
class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  LocalAuthBiometricAuthenticator([LocalAuthentication? localAuth])
    : _localAuth = localAuth ?? LocalAuthentication();

  final LocalAuthentication _localAuth;

  @override
  Future<bool> isAvailable() async {
    try {
      if (!await _localAuth.isDeviceSupported()) return false;
      return (await _localAuth.getAvailableBiometrics()).isNotEmpty;
    } on Exception {
      return false;
    }
  }

  @override
  Future<BiometricAuthResult> authenticate({required String reason}) async {
    try {
      final confirmed = await _localAuth.authenticate(
        localizedReason: reason,
        // Sem cair para PIN/padrão: a alternativa do app é a senha da conta.
        biometricOnly: true,
        // Retoma o prompt se o app for para segundo plano no meio.
        persistAcrossBackgrounding: true,
      );
      return confirmed
          ? BiometricAuthResult.success
          : BiometricAuthResult.failed;
    } on LocalAuthException catch (error) {
      return switch (error.code) {
        LocalAuthExceptionCode.temporaryLockout ||
        LocalAuthExceptionCode.biometricLockout =>
          BiometricAuthResult.lockedOut,
        LocalAuthExceptionCode.userCanceled ||
        LocalAuthExceptionCode.systemCanceled ||
        LocalAuthExceptionCode.timeout ||
        LocalAuthExceptionCode.authInProgress ||
        LocalAuthExceptionCode.userRequestedFallback =>
          BiometricAuthResult.failed,
        _ => BiometricAuthResult.unavailable,
      };
    } on Exception {
      return BiometricAuthResult.unavailable;
    }
  }
}
