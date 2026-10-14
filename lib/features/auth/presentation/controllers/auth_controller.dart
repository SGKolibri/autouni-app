import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/biometrics/biometric_authenticator.dart';
import '../../../../core/biometrics/biometric_providers.dart';
import '../../../../core/cache/cache_providers.dart';
import '../../../../core/session/session_events.dart';
import '../../../../shared/devices/device_live_state.dart';
import '../../data/auth_data_providers.dart';
import '../../data/biometrics/biometric_login_settings.dart';
import '../../domain/models/user.dart';

/// Estado da sessão: o usuário autenticado, ou `null` quando deslogado.
///
/// - `AsyncLoading` enquanto restaura a sessão guardada (abertura do app) ou
///   enquanto um login está em andamento;
/// - `AsyncError` com a `ApiException` da tentativa de login que falhou;
/// - `AsyncData(user)` com a sessão restaurada ou depois de um login.
///
/// Com o login por biometria ligado, a sessão guardada não entra sozinha: o
/// estado fica `null` até [loginWithBiometrics] (ou o login por senha).
class AuthController extends AsyncNotifier<User?> {
  bool _loginInFlight = false;

  @override
  FutureOr<User?> build() async {
    // O refresh token foi recusado em alguma request: a sessão acabou.
    final expiry = ref.watch(sessionEventsProvider).expired.listen((_) {
      if (!ref.mounted || state.value == null) return;
      ref.read(sessionExpiredNoticeProvider.notifier).show();
      unawaited(ref.read(localCacheProvider).clear());
      ref.invalidate(deviceLiveStateProvider);
      state = const AsyncData(null);
    });
    ref.onDispose(expiry.cancel);

    final user = await ref.watch(authRepositoryProvider).restoreSession();
    if (user == null) return null;
    final locked = await ref.watch(biometricLoginSettingsProvider).isEnabled();
    return locked ? null : user;
  }

  /// Autentica com e-mail e senha. Chamadas feitas enquanto outra tentativa
  /// está em andamento são ignoradas (ex.: toque duplo no botão "Entrar").
  Future<void> login({required String email, required String password}) async {
    if (_loginInFlight) return;
    _loginInFlight = true;
    try {
      // Deixa a restauração terminar antes, para ela não sobrescrever o login.
      if (state.isLoading) {
        await future.then<void>((_) {}, onError: (_) {});
        if (!ref.mounted) return;
      }

      state = const AsyncLoading<User?>();
      final result = await AsyncValue.guard<User?>(
        () => ref
            .read(authRepositoryProvider)
            .login(email: email, password: password),
      );
      if (!ref.mounted) return;
      if (result.hasValue) {
        ref.read(sessionExpiredNoticeProvider.notifier).hide();
      }
      state = result;
    } finally {
      _loginInFlight = false;
    }
  }

  /// Libera a sessão guardada depois de confirmar a biometria.
  ///
  /// Qualquer desfecho diferente de sucesso deixa o estado como estava
  /// (deslogado, sem erro) — quem chama decide o que mostrar a partir do
  /// [BiometricAuthResult]. Sem sessão aproveitável, sem biometria no
  /// aparelho ou com a opção desligada, devolve `unavailable` sem abrir o
  /// prompt.
  Future<BiometricAuthResult> loginWithBiometrics() async {
    if (_loginInFlight) return BiometricAuthResult.failed;
    _loginInFlight = true;
    try {
      if (state.isLoading) {
        await future.then<void>((_) {}, onError: (_) {});
        if (!ref.mounted) return BiometricAuthResult.failed;
      }

      final repository = ref.read(authRepositoryProvider);
      final biometrics = ref.read(biometricAuthenticatorProvider);
      final enabled = await ref
          .read(biometricLoginSettingsProvider)
          .isEnabled();
      if (!enabled ||
          !await biometrics.isAvailable() ||
          await repository.restoreSession() == null) {
        return BiometricAuthResult.unavailable;
      }

      final previous = state;
      state = const AsyncLoading<User?>();
      final result = await biometrics.authenticate(
        reason: 'Confirme sua biometria para entrar no AutoUni',
      );
      if (!ref.mounted) return result;
      if (result != BiometricAuthResult.success) {
        state = previous;
        return result;
      }

      // Relê a sessão: ela pode ter expirado enquanto o prompt estava aberto.
      final user = await repository.restoreSession();
      if (ref.mounted) state = AsyncData(user);
      return user == null
          ? BiometricAuthResult.unavailable
          : BiometricAuthResult.success;
    } finally {
      _loginInFlight = false;
    }
  }

  /// Sai da conta: avisa o backend, apaga tokens, o cache local (que tem
  /// dados do usuário) e o estado ao vivo dos dispositivos. A preferência de biometria fica — sem sessão
  /// guardada, ela só volta a valer depois do próximo login por senha.
  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    await ref.read(localCacheProvider).clear();
    if (!ref.mounted) return;
    ref.invalidate(deviceLiveStateProvider);
    state = const AsyncData(null);
  }
}

/// Aviso de "sessão expirada" para a tela de login, ligado quando o refresh
/// token é recusado e desligado no próximo login.
class SessionExpiredNotice extends Notifier<bool> {
  @override
  bool build() => false;

  void show() => state = true;
  void hide() => state = false;
}

final sessionExpiredNoticeProvider =
    NotifierProvider<SessionExpiredNotice, bool>(
      SessionExpiredNotice.new,
      name: 'sessionExpiredNoticeProvider',
    );

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
  name: 'authControllerProvider',
);
