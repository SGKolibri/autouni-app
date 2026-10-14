import 'package:go_router/go_router.dart';

import 'pages/floors_page.dart';
import 'pages/room_detail_page.dart';
import 'pages/rooms_page.dart';

/// Sub-rotas da aba Ambientes, aninhadas para o go_router montar a pilha
/// completa a partir da URL (ver `AppPaths`).
List<RouteBase> environmentsRoutes() => [
  GoRoute(
    path: 'buildings/:buildingId',
    builder: (context, state) =>
        FloorsPage(buildingId: state.pathParameters['buildingId']!),
    routes: [
      GoRoute(
        path: 'floors/:floorId',
        builder: (context, state) => RoomsPage(
          buildingId: state.pathParameters['buildingId']!,
          floorId: state.pathParameters['floorId']!,
        ),
        routes: [
          GoRoute(
            path: 'rooms/:roomId',
            builder: (context, state) => RoomDetailPage(
              buildingId: state.pathParameters['buildingId']!,
              floorId: state.pathParameters['floorId']!,
              roomId: state.pathParameters['roomId']!,
            ),
          ),
        ],
      ),
    ],
  ),
];
