import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_role.dart';
import 'app_permission.dart';

/// Papel do usuário logado, ou `null` sem sessão.
///
/// `shared/` não conhece a feature de autenticação: o bootstrap
/// (`buildAppRoot`) sobrescreve este provider com o papel vindo da sessão.
/// Sem override, ninguém tem permissão — na dúvida, somente leitura.
final currentUserRoleProvider = Provider<UserRole?>(
  (ref) => null,
  name: 'currentUserRoleProvider',
);

/// O usuário logado pode executar a permissão?
final hasPermissionProvider = Provider.family<bool, AppPermission>(
  (ref, permission) =>
      ref.watch(currentUserRoleProvider)?.can(permission) ?? false,
  name: 'hasPermissionProvider',
);
