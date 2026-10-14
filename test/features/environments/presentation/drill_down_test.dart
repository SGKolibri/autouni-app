import 'dart:async';

import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/app_config_provider.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/realtime/realtime_client.dart';
import 'package:autouni_app/core/realtime/realtime_providers.dart';
import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/core/router/app_router.dart';
import 'package:autouni_app/core/router/app_tab.dart';
import 'package:autouni_app/features/environments/data/environments_repository.dart';
import 'package:autouni_app/features/environments/presentation/environments_routes.dart';
import 'package:autouni_app/features/environments/presentation/pages/buildings_page.dart';
import 'package:autouni_app/features/environments/presentation/pages/floors_page.dart';
import 'package:autouni_app/features/environments/presentation/pages/room_detail_page.dart';
import 'package:autouni_app/features/environments/presentation/pages/rooms_page.dart';
import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:autouni_app/shared/models/campus/campus_enums.dart';
import 'package:autouni_app/shared/models/campus/campus_models.dart';
import 'package:autouni_app/shared/models/user_role.dart';
import 'package:autouni_app/shared/rbac/rbac_providers.dart';
import 'package:autouni_app/shared/realtime/device_events.dart';
import 'package:autouni_app/shared/widgets/cached_async_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/campus_fixtures.dart';

class _MockRepository extends Mock implements EnvironmentsRepository {}

final _light = deviceJson(id: 'd1', name: 'Luminária', status: 'ON');
final _ac = deviceJson(id: 'd2', name: 'Ar', type: 'AC', online: false);

final _building = Building.fromJson(
  buildingJson(
    id: 'b1',
    name: 'Bloco A',
    floors: [
      floorJson(
        id: 'f1',
        rooms: [
          roomJson(id: 'r1', devices: [_light, _ac]),
        ],
      ),
    ],
    todayEnergyKwh: 12.5,
  ),
);
final _floor = Floor.fromJson(
  floorJson(
    id: 'f1',
    rooms: [
      roomJson(id: 'r1', devices: [_light, _ac]),
    ],
    building: buildingJson(id: 'b1', name: 'Bloco A'),
  ),
);
final _room = Room.fromJson(
  roomJson(
    id: 'r1',
    name: 'Sala 101',
    devices: [_light, _ac],
    floor: floorJson(
      id: 'f1',
      building: buildingJson(id: 'b1', name: 'Bloco A'),
    ),
    todayEnergyKwh: 1.5,
  ),
);

Stream<Cached<T>> _fresh<T>(T data) => Stream.value(Cached(data));

void main() {
  late _MockRepository repository;
  late StreamController<DeviceEvent> events;

  setUp(() {
    repository = _MockRepository();
    events = StreamController<DeviceEvent>.broadcast(sync: true);
    when(() => repository.watchBuildings())
        .thenAnswer((_) => _fresh([_building]));
    when(() => repository.watchBuilding('b1'))
        .thenAnswer((_) => _fresh(_building));
    when(() => repository.watchFloors('b1'))
        .thenAnswer((_) => _fresh([_floor]));
    when(() => repository.watchFloor('f1')).thenAnswer((_) => _fresh(_floor));
    when(() => repository.watchRooms('f1')).thenAnswer((_) => _fresh([_room]));
    when(() => repository.watchRoom('r1')).thenAnswer((_) => _fresh(_room));
  });

  tearDown(() => events.close());

  Future<GoRouter> pumpEnvironments(
    WidgetTester tester, {
    String? initialLocation,
    UserRole role = UserRole.technician,
  }) async {
    final router = createAppRouter(
      initialLocation: initialLocation ?? AppTab.environments.path,
      tabPages: {
        AppTab.environments: (context, state) => const BuildingsPage(),
      },
      tabRoutes: {AppTab.environments: environmentsRoutes()},
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.forFlavor(Flavor.dev)),
          environmentsRepositoryProvider.overrideWithValue(repository),
          deviceEventsProvider.overrideWithValue(events.stream),
          realtimeStatusProvider.overrideWithValue(
            RealtimeConnectionStatus.connected,
          ),
          currentUserRoleProvider.overrideWithValue(role),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('navega Prédios → Andares → Salas → Sala tocando nos cards', (
    tester,
  ) async {
    final router = await pumpEnvironments(tester);

    expect(find.byType(BuildingsPage), findsOneWidget);
    await tester.tap(find.text('Bloco A'));
    await tester.pumpAndSettle();
    expect(find.byType(FloorsPage), findsOneWidget);

    await tester.tap(find.text('1º andar'));
    await tester.pumpAndSettle();
    expect(find.byType(RoomsPage), findsOneWidget);

    await tester.tap(find.text('Sala 101'));
    await tester.pumpAndSettle();
    expect(find.byType(RoomDetailPage), findsOneWidget);
    expect(router.state.uri.path, AppPaths.room('b1', 'f1', 'r1'));
  });

  testWidgets(
    'deep link para a sala preserva a pilha inteira (voltar sobe um nível)',
    (tester) async {
      final router = await pumpEnvironments(
        tester,
        initialLocation: AppPaths.room('b1', 'f1', 'r1'),
      );
      expect(find.byType(RoomDetailPage), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(RoomsPage), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(FloorsPage), findsOneWidget);

      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(BuildingsPage), findsOneWidget);
    },
  );

  testWidgets('o breadcrumb mostra o caminho completo e volta ao andar', (
    tester,
  ) async {
    final router = await pumpEnvironments(
      tester,
      initialLocation: AppPaths.room('b1', 'f1', 'r1'),
    );

    final crumb = find.byKey(const Key('location-breadcrumb'));
    for (final label in ['Ambientes', 'Bloco A', '1º andar', 'Sala 101']) {
      expect(
        find.descendant(of: crumb, matching: find.text(label)),
        findsOneWidget,
        reason: label,
      );
    }

    await tester.tap(
      find.descendant(of: crumb, matching: find.text('1º andar')),
    );
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppPaths.floor('b1', 'f1'));
    expect(find.byType(RoomsPage), findsOneWidget);
  });

  testWidgets('cards mostram ligados/offline e mudam com o WebSocket', (
    tester,
  ) async {
    await pumpEnvironments(tester);

    expect(find.text('1/2 ligados'), findsOneWidget);
    expect(find.text('1 offline'), findsOneWidget);

    events.add(
      const DeviceStatusChanged(deviceId: 'd1', status: DeviceStatus.off),
    );
    await tester.pump();

    expect(find.text('0/2 ligados'), findsOneWidget);
  });

  testWidgets('sem prédios mostra o estado vazio', (tester) async {
    when(() => repository.watchBuildings())
        .thenAnswer((_) => _fresh(<Building>[]));
    await pumpEnvironments(tester);

    expect(find.text('Nenhum prédio cadastrado'), findsOneWidget);
  });

  testWidgets('erro sem cache mostra o estado de erro e tenta de novo', (
    tester,
  ) async {
    when(() => repository.watchBuildings())
        .thenAnswer((_) => Stream.error(const NetworkException()));
    await pumpEnvironments(tester);

    expect(find.text('Sem conexão com a internet.'), findsOneWidget);

    when(() => repository.watchBuildings())
        .thenAnswer((_) => _fresh([_building]));
    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.text('Bloco A'), findsOneWidget);
  });

  testWidgets('sem rede, mostra os prédios salvos com aviso', (tester) async {
    when(() => repository.watchBuildings()).thenAnswer(
      (_) => Stream.value(
        Cached([_building], savedAt: DateTime(2026, 10, 14, 9), offline: true),
      ),
    );
    await pumpEnvironments(tester);

    expect(find.text('Bloco A'), findsOneWidget);
    expect(find.byType(StaleDataBanner), findsOneWidget);
  });
}
