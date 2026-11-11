import 'package:go_router/go_router.dart';

import 'pages/change_password_page.dart';
import 'pages/profile_page.dart';

/// Sub-rotas da aba Ajustes (`AppPaths.profile`, `AppPaths.changePassword`).
List<RouteBase> settingsRoutes() => [
  GoRoute(path: 'profile', builder: (context, state) => const ProfilePage()),
  GoRoute(
    path: 'password',
    builder: (context, state) => const ChangePasswordPage(),
  ),
];
