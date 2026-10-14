import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric_authenticator.dart';
import 'local_auth_biometric_authenticator.dart';

/// Biometria do aparelho (`local_auth`).
final biometricAuthenticatorProvider = Provider<BiometricAuthenticator>(
  (ref) => LocalAuthBiometricAuthenticator(),
  name: 'biometricAuthenticatorProvider',
);
