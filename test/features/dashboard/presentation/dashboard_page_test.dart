import 'dart:async';

import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/realtime/realtime_client.dart';
import 'package:autouni_app/core/realtime/realtime_providers.dart';
import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/features/dashboard/data/dashboard_repository.dart';
import 'package:autouni_app/features/dashboard/domain/dashboard_models.dart';
import 'package:autouni_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:autouni_app/shared/models/campus/campus_enums.dart';
import 'package:autouni_app/shared/models/campus/campus_models.dart';
import 'package:autouni_app/shared/models/notification_type.dart';
import 'package:autouni_app/shared/realtime/device_events.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/campus_fixtures.dart';
import '../../../support/pump_router_app.dart';

class _MockRepository extends Mock implements DashboardRepository {}

DashboardOverview _overview({
  EnergySummary? energy = const EnergySummary(todayEnergyKwh: 42.5),
  List<DashboardAlert> alerts = const [],
}) => DashboardOverview(
  buildings: [
    Building.fromJson(
      buildingJson(
        id: 'b1',
        name: 'Bloco A',
        todayEnergyKwh: 10,
        floors: [
          floorJson(
            rooms: [
              roomJson(
                devices: [
                  deviceJson(id: 'd1', status: 'ON'),
                  deviceJson(id: 'd2', status: 'ON'),
                  deviceJson(id: 'd3', status: 'STANDBY', online: false),
                  deviceJson(id: 'd4', status: 'ERROR'),
                ],
              ),
            ],
          ),
        ],
      ),
    ),
  ],
  energy: energy,
  alerts: alerts,
);

void main() {
  late _MockRepository repository;
  late StreamController<DeviceEvent> events;

  setUp(() {
    repository = _MockRepository();
    events = StreamController<DeviceEvent>.broadcast(sync: true);
    when(() => repository.watchOverview())
        .thenAnswer((_) => Stream.value(Cached(_overview())));
  });

  tearDown(() => events.close());

  Future<GoRouter> pumpDashboard(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (_, router) = await tester.pumpRouterApp(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(path: '/dashboard', builder: (_, _) => const DashboardPage()),
        stubRoute(AppPaths.building('b1')),
      ],
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(repository),
        deviceEventsProvider.overrideWithValue(events.stream),
        realtimeStatusProvider.overrideWithValue(
          RealtimeConnectionStatus.connected,
        ),
      ],
    );
    await tester.pumpAndSettle();
    return router;
  }

  String kpi(WidgetTester tester, String label) =>
      tester.widget<KpiCard>(find.widgetWithText(KpiCard, label)).value;

  String donut(WidgetTester tester, String key) =>
      tester.widget<Text>(find.byKey(Key(key))).data!;

  testWidgets('mostra os KPIs do campus', (tester) async {
    await pumpDashboard(tester);

    expect(kpi(tester, 'Dispositivos ligados'), '2/4');
    expect(kpi(tester, 'Online'), '3/4');
    expect(find.text('1 offline'), findsOneWidget);
    expect(kpi(tester, 'Consumo hoje'), '42,5 kWh');
    expect(kpi(tester, 'Alertas não lidos'), '0');
  });

  testWidgets('donut com a distribuição de status', (tester) async {
    await pumpDashboard(tester);

    expect(find.byType(PieChart), findsOneWidget);
    expect(donut(tester, 'donut-total'), '4');
    expect(donut(tester, 'donut-on'), '2');
    expect(donut(tester, 'donut-standby'), '1');
    expect(donut(tester, 'donut-error'), '1');
    expect(donut(tester, 'donut-off'), '0');
  });

  testWidgets('eventos do WebSocket atualizam KPIs e donut (S3-T4)', (
    tester,
  ) async {
    await pumpDashboard(tester);

    events
      ..add(const DeviceStatusChanged(deviceId: 'd1', status: DeviceStatus.off))
      ..add(const DeviceOnlineChanged(deviceId: 'd3', online: true));
    await tester.pumpAndSettle();

    expect(kpi(tester, 'Dispositivos ligados'), '1/4');
    expect(kpi(tester, 'Online'), '4/4');
    expect(donut(tester, 'donut-off'), '1');
    verify(() => repository.watchOverview()).called(1);
  });

  testWidgets('lista os prédios e abre o prédio tocado', (tester) async {
    final router = await pumpDashboard(tester);

    expect(find.text('2/4 ligados · 10,0 kWh hoje'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('dashboard-building-b1')));
    await tester.pumpAndSettle();

    expect(router.state.uri.path, AppPaths.building('b1'));
    expect(find.text('stub ${AppPaths.building('b1')}'), findsOneWidget);
  });

  testWidgets('alertas recentes: no máximo 5, com não lidos contados', (
    tester,
  ) async {
    when(() => repository.watchOverview()).thenAnswer(
      (_) => Stream.value(
        Cached(
          _overview(
            alerts: [
              for (var i = 0; i < 7; i++)
                DashboardAlert(
                  id: 'n$i',
                  title: 'Alerta $i',
                  type: NotificationType.warning,
                  read: i.isEven,
                ),
            ],
          ),
        ),
      ),
    );
    await pumpDashboard(tester);

    expect(kpi(tester, 'Alertas não lidos'), '3');
    expect(find.text('Alerta 4'), findsOneWidget);
    expect(find.text('Alerta 5'), findsNothing);
  });

  testWidgets('sem alertas e sem consumo', (tester) async {
    when(() => repository.watchOverview())
        .thenAnswer((_) => Stream.value(Cached(_overview(energy: null))));
    await pumpDashboard(tester);

    expect(find.text('Nenhum alerta recente.'), findsOneWidget);
    expect(kpi(tester, 'Consumo hoje'), '—');
  });

  testWidgets('carregando mostra o esqueleto', (tester) async {
    when(() => repository.watchOverview())
        .thenAnswer((_) => const Stream.empty());
    await tester.pumpRouterApp(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(path: '/dashboard', builder: (_, _) => const DashboardPage()),
      ],
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(repository),
        deviceEventsProvider.overrideWithValue(events.stream),
        realtimeStatusProvider.overrideWithValue(
          RealtimeConnectionStatus.connected,
        ),
      ],
    );

    expect(find.bySemanticsLabel('Carregando'), findsOneWidget);
  });

  testWidgets('erro sem cache permite tentar de novo', (tester) async {
    when(() => repository.watchOverview())
        .thenAnswer((_) => Stream.error(const NetworkException()));
    await pumpDashboard(tester);

    expect(find.text('Sem conexão com a internet.'), findsOneWidget);
    expect(find.text('Tentar de novo'), findsOneWidget);
  });

  testWidgets('WebSocket caído mostra o banner', (tester) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpRouterApp(
      initialLocation: '/dashboard',
      routes: [
        GoRoute(path: '/dashboard', builder: (_, _) => const DashboardPage()),
      ],
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(repository),
        deviceEventsProvider.overrideWithValue(events.stream),
        realtimeStatusProvider.overrideWithValue(
          RealtimeConnectionStatus.reconnecting,
        ),
      ],
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Tempo real indisponível — tentando reconectar.'),
      findsOneWidget,
    );
  });
}
