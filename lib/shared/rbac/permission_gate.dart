import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_permission.dart';
import 'rbac_providers.dart';

/// Só renderiza [child] se o usuário logado tiver [permission]; caso
/// contrário mostra [fallback] (nada, por padrão). A ação some da tela em vez
/// de aparecer desabilitada.
class PermissionGate extends ConsumerWidget {
  const PermissionGate({
    required this.permission,
    required this.child,
    this.fallback = const SizedBox.shrink(),
    super.key,
  });

  final AppPermission permission;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(hasPermissionProvider(permission)) ? child : fallback;
}
