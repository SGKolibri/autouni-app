import 'package:go_router/go_router.dart';

import '../../../core/router/app_paths.dart';
import 'pages/new_report_page.dart';
import 'pages/report_detail_page.dart';
import 'pages/reports_page.dart';

/// Relatórios, fora do shell de abas (`AppPaths.reportsRoot`).
List<RouteBase> reportsRoutes() => [
  GoRoute(
    path: AppPaths.reportsRoot,
    builder: (context, state) => const ReportsPage(),
    routes: [
      // `new` antes de `:reportId`, senão vira um id.
      GoRoute(path: 'new', builder: (context, state) => const NewReportPage()),
      GoRoute(
        path: ':reportId',
        builder: (context, state) =>
            ReportDetailPage(reportId: state.pathParameters['reportId']!),
      ),
    ],
  ),
];
