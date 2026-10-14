import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/router/app_router.dart';
import '../core/router/app_tab.dart';
import '../core/router/session_guard.dart';
import '../features/auth/domain/models/user.dart';
import '../features/auth/presentation/controllers/auth_controller.dart';
import '../features/auth/presentation/pages/account_settings_page.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/dashboard/presentation/pages/dashboard_page.dart';
import '../features/devices/presentation/devices_routes.dart';
import '../features/environments/presentation/environments_routes.dart';
import '../features/environments/presentation/pages/buildings_page.dart';

/// Instância única do [GoRouter] do app, já com as telas das features e o
/// guard de sessão ligado ao [authControllerProvider].
///
/// Fica fora de `core/` porque monta telas de `features/`.
final appRouterProvider = Provider<GoRouter>((ref) {
  final session = _SessionStatusNotifier(ref.read(authControllerProvider));
  ref.listen(authControllerProvider, (_, next) => session.update(next));

  final router = createAppRouter(
    sessionStatus: () => session.value,
    refreshListenable: session,
    outsideShellRoutes: [
      GoRoute(
        path: SessionRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: SessionRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
    ],
    tabPages: {
      AppTab.dashboard: (context, state) => const DashboardPage(),
      AppTab.environments: (context, state) => const BuildingsPage(),
      AppTab.settings: (context, state) => const AccountSettingsPage(),
    },
    tabRoutes: {
      AppTab.environments: [...environmentsRoutes(), ...devicesRoutes()],
    },
  );
  ref.onDispose(() {
    router.dispose();
    session.dispose();
  });
  return router;
}, name: 'appRouterProvider');

/// Traduz o estado de autenticação para o guard de rotas.
///
/// Só é `unknown` enquanto a sessão guardada é restaurada na abertura; um
/// login em andamento depois disso conta como deslogado (fica no login).
class _SessionStatusNotifier extends ValueNotifier<SessionStatus> {
  _SessionStatusNotifier(AsyncValue<User?> initial)
    : super(SessionStatus.unknown) {
    update(initial);
  }

  bool _restored = false;

  void update(AsyncValue<User?> auth) {
    if (!auth.isLoading) _restored = true;
    value = auth.value != null
        ? SessionStatus.signedIn
        : _restored
        ? SessionStatus.signedOut
        : SessionStatus.unknown;
  }
}
