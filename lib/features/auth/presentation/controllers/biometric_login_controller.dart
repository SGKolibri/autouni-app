import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/biometrics/biometric_authenticator.dart';
import '../../../../core/biometrics/biometric_providers.dart';
import '../../data/auth_data_providers.dart';
import '../../data/biometrics/biometric_login_settings.dart';
import 'auth_controller.dart';

/// Liga/desliga o login por biometria neste aparelho. O estado é a escolha
/// atual do usuário.
class BiometricLoginController extends AsyncNotifier<bool> {
  @override
  FutureOr<bool> build() =>
      ref.watch(biometricLoginSettingsProvider).isEnabled();

  /// Liga o login por biometria. Só vale depois do primeiro acesso (com
  /// usuário logado) e exige confirmar a biometria na hora, para o usuário
  /// não ligar algo que não consegue usar.
  Future<BiometricAuthResult> enable() async {
    final biometrics = ref.read(biometricAuthenticatorProvider);
    final loggedIn = ref.read(authControllerProvider).value != null;
    if (!loggedIn || !await biometrics.isAvailable()) {
      return BiometricAuthResult.unavailable;
    }

    final result = await biometrics.authenticate(
      reason: 'Confirme sua biometria para ativar o acesso rápido',
    );
    if (result == BiometricAuthResult.success && ref.mounted) {
      await ref.read(biometricLoginSettingsProvider).setEnabled(true);
      if (ref.mounted) state = const AsyncData(true);
    }
    return result;
  }

  Future<void> disable() async {
    await ref.read(biometricLoginSettingsProvider).setEnabled(false);
    if (ref.mounted) state = const AsyncData(false);
  }
}

final biometricLoginEnabledProvider =
    AsyncNotifierProvider<BiometricLoginController, bool>(
      BiometricLoginController.new,
      name: 'biometricLoginEnabledProvider',
    );

/// A tela de login deve oferecer "Entrar com biometria"? Só quando o usuário
/// ligou a opção, o aparelho tem biometria e ainda há uma sessão guardada
/// para liberar.
final biometricLoginAvailableProvider = FutureProvider<bool>((ref) async {
  if (!await ref.watch(biometricLoginEnabledProvider.future)) return false;
  if (!await ref.watch(biometricAuthenticatorProvider).isAvailable()) {
    return false;
  }
  return await ref.watch(authRepositoryProvider).restoreSession() != null;
}, name: 'biometricLoginAvailableProvider');
