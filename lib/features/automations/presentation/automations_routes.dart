import 'package:go_router/go_router.dart';

import 'pages/automation_detail_page.dart';
import 'pages/automation_form_page.dart';

/// Sub-rotas da aba Automações (ver `AppPaths`). `new` vem antes de
/// `:automationId` para não ser lido como id.
List<RouteBase> automationsRoutes() => [
  GoRoute(path: 'new', builder: (context, state) => const AutomationFormPage()),
  GoRoute(
    path: ':automationId',
    builder: (context, state) => AutomationDetailPage(
      automationId: state.pathParameters['automationId']!,
    ),
    routes: [
      GoRoute(
        path: 'edit',
        builder: (context, state) => AutomationFormPage(
          automationId: state.pathParameters['automationId']!,
        ),
      ),
    ],
  ),
];
