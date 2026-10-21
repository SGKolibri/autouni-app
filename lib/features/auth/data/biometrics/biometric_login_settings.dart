import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Escolha do usuário, neste aparelho, de entrar no app por biometria.
abstract interface class BiometricLoginSettings {
  Future<bool> isEnabled();
  Future<void> setEnabled(bool enabled);
}

/// Implementação volátil, usada em testes e como default do provider.
class InMemoryBiometricLoginSettings implements BiometricLoginSettings {
  bool _enabled = false;

  @override
  Future<bool> isEnabled() async => _enabled;

  @override
  Future<void> setEnabled(bool enabled) async => _enabled = enabled;
}

/// Implementação persistida no armazenamento seguro, ao lado dos tokens:
/// é ela que decide se a sessão guardada abre direto ou pede biometria, então
/// não pode ficar num arquivo de preferências editável.
class SecureBiometricLoginSettings implements BiometricLoginSettings {
  SecureBiometricLoginSettings([this._storage = const FlutterSecureStorage()]);

  static const String enabledKey = 'autouni.auth.biometric_login_enabled';

  final FlutterSecureStorage _storage;

  @override
  Future<bool> isEnabled() async {
    try {
      return await _storage.read(key: enabledKey) == 'true';
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> setEnabled(bool enabled) => enabled
      ? _storage.write(key: enabledKey, value: 'true')
      : _storage.delete(key: enabledKey);
}

/// Preferência de login por biometria.
///
/// Default volátil, seguro para testes; o bootstrap (`buildAppRoot`)
/// sobrescreve com o [SecureBiometricLoginSettings].
final biometricLoginSettingsProvider = Provider<BiometricLoginSettings>(
  (ref) => InMemoryBiometricLoginSettings(),
  name: 'biometricLoginSettingsProvider',
);
