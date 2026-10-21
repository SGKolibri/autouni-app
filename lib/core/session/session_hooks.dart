import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Id do usuário logado, ou `null` sem sessão.
///
/// O core não conhece a autenticação: o bootstrap sobrescreve com o usuário
/// da sessão (como o papel do RBAC).
final sessionUserIdProvider = Provider<String?>(
  (ref) => null,
  name: 'sessionUserIdProvider',
);

/// Tarefas que precisam rodar **antes** do logout, enquanto a sessão ainda
/// vale (ex.: remover o token de push no backend com o JWT atual).
class LogoutHooks {
  /// Quanto o logout espera cada gancho antes de seguir sem ele.
  static const Duration timeout = Duration(seconds: 5);

  final List<Future<void> Function()> _hooks = [];

  /// Registra [hook]; devolve a função que o remove.
  VoidCallback add(Future<void> Function() hook) {
    _hooks.add(hook);
    return () => _hooks.remove(hook);
  }

  /// Roda todos, na ordem. Falha ou demora de um gancho nunca impede o
  /// logout.
  Future<void> run() async {
    for (final hook in List.of(_hooks)) {
      try {
        await hook().timeout(timeout);
      } on Object catch (error) {
        debugPrint('Gancho de logout falhou: $error');
      }
    }
  }
}

final logoutHooksProvider = Provider<LogoutHooks>(
  (ref) => LogoutHooks(),
  name: 'logoutHooksProvider',
);
