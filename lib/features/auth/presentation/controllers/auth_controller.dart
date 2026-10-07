import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_data_providers.dart';
import '../../domain/models/user.dart';

/// Estado da sessão: o usuário autenticado, ou `null` quando deslogado.
///
/// - `AsyncLoading` enquanto restaura a sessão guardada (abertura do app) ou
///   enquanto o login está em andamento;
/// - `AsyncError` com a `ApiException` da tentativa de login que falhou;
/// - `AsyncData(user)` com a sessão restaurada ou depois de um login.
class AuthController extends AsyncNotifier<User?> {
  bool _loginInFlight = false;

  @override
  FutureOr<User?> build() => ref.watch(authRepositoryProvider).restoreSession();

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
      if (ref.mounted) state = result;
    } finally {
      _loginInFlight = false;
    }
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
  name: 'authControllerProvider',
);
