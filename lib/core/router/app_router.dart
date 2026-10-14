import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';
import 'app_tab.dart';
import 'placeholder_pages.dart';
import 'session_guard.dart';
import 'splash_page.dart';

abstract final class AppRoutes {
  static const String root = '/';

  /// Rota de entrada do app (depois do login).
  static final String initial = AppTab.dashboard.path;
}

/// Monta a árvore de rotas: um `StatefulShellRoute` com um branch por
/// [AppTab], cada um com a própria pilha de navegação preservada.
///
/// O core não conhece as features: quem monta o app injeta a tela raiz de
/// cada aba ([tabPages]), as sub-rotas de cada aba ([tabRoutes]) e as telas
/// fora do shell, como login ([outsideShellRoutes]). Abas sem tela própria
/// mostram um placeholder.
///
/// Com [sessionStatus], liga o guard de sessão ([sessionRedirect]);
/// [refreshListenable] deve notificar a cada mudança de sessão.
GoRouter createAppRouter({
  String? initialLocation,
  Map<AppTab, GoRouterWidgetBuilder> tabPages = const {},
  Map<AppTab, List<RouteBase>> tabRoutes = const {},
  List<RouteBase> outsideShellRoutes = const [],
  SessionStatus Function()? sessionStatus,
  Listenable? refreshListenable,
}) {
  return GoRouter(
    initialLocation: initialLocation ?? AppRoutes.initial,
    refreshListenable: refreshListenable,
    redirect: (context, state) {
      final status = sessionStatus?.call();
      if (status != null) {
        final guarded = sessionRedirect(
          uri: state.uri,
          status: status,
          home: AppRoutes.initial,
        );
        if (guarded != null) return guarded;
      }
      return state.uri.path == AppRoutes.root ? AppRoutes.initial : null;
    },
    errorBuilder: (context, state) => const NotFoundPage(),
    routes: [
      GoRoute(
        path: SessionRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      ...outsideShellRoutes,
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
                  builder:
                      tabPages[tab] ??
                      (context, state) => TabPlaceholderPage(tab: tab),
                  routes: tabRoutes[tab] ?? const [],
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
