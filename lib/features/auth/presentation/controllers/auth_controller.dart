import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_data_providers.dart';
import '../../domain/models/user.dart';

/// Estado da sessão: o usuário autenticado, ou `null` quando deslogado.
///
/// - `AsyncLoading` enquanto o login está em andamento;
/// - `AsyncError` com a `ApiException` da tentativa que falhou;
/// - `AsyncData(user)` depois de um login bem-sucedido.
class AuthController extends AsyncNotifier<User?> {
  @override
  FutureOr<User?> build() => null;

  /// Autentica com e-mail e senha. Chamadas feitas enquanto outra tentativa
  /// está em andamento são ignoradas (ex.: toque duplo no botão "Entrar").
  Future<void> login({required String email, required String password}) async {
    if (state.isLoading) return;

    state = const AsyncLoading<User?>();
    final result = await AsyncValue.guard<User?>(
      () => ref
          .read(authRepositoryProvider)
          .login(email: email, password: password),
    );
    if (ref.mounted) state = result;
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
  name: 'authControllerProvider',
);
