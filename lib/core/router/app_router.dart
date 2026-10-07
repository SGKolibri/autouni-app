import 'package:go_router/go_router.dart';

import 'app_shell.dart';
import 'app_tab.dart';
import 'placeholder_pages.dart';

abstract final class AppRoutes {
  static const String root = '/';

  /// Rota de entrada do app. O guard de autenticação (S2-T6) passa a
  /// redirecionar para o login antes daqui.
  static final String initial = AppTab.dashboard.path;
}

/// Monta a árvore de rotas: um `StatefulShellRoute` com um branch por
/// [AppTab], cada um com a própria pilha de navegação preservada.
GoRouter createAppRouter({String? initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation ?? AppRoutes.initial,
    redirect: (context, state) =>
        state.uri.path == AppRoutes.root ? AppRoutes.initial : null,
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          for (final tab in AppTab.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: tab.path,
                  name: tab.name,
                  builder: (context, state) => TabPlaceholderPage(tab: tab),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
