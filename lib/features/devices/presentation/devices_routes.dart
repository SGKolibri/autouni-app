import 'package:go_router/go_router.dart';

import 'pages/all_devices_page.dart';

/// Lista global, sob a aba Ambientes (`AppPaths.allDevices`).
List<RouteBase> devicesRoutes() => [
  GoRoute(path: 'devices', builder: (context, state) => const AllDevicesPage()),
];
