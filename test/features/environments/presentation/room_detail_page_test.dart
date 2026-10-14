import 'dart:async';

import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/realtime/realtime_client.dart';
import 'package:autouni_app/core/realtime/realtime_providers.dart';
import 'package:autouni_app/features/environments/data/environments_repository.dart';
import 'package:autouni_app/features/environments/presentation/pages/room_detail_page.dart';
import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:autouni_app/shared/devices/device_commands.dart';
import 'package:autouni_app/shared/devices/device_repository.dart';
import 'package:autouni_app/shared/devices/live_device_row.dart';
import 'package:autouni_app/shared/models/campus/campus_models.dart';
import 'package:autouni_app/shared/models/user_role.dart';
import 'package:autouni_app/shared/rbac/rbac_providers.dart';
import 'package:autouni_app/shared/realtime/device_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/campus_fixtures.dart';
import '../../../support/pump_router_app.dart';

class _MockEnvironments extends Mock implements EnvironmentsRepository {}

class _MockDevices extends Mock implements DeviceRepository {}

void main() {
  late _MockEnvironments environments;
  late _MockDevices devices;
  late StreamController<DeviceEvent> events;

  setUpAll(() => registerFallbackValue(DeviceCommand.on));

  Room room({List<Map<String, dynamic>>? deviceList}) => Room.fromJson(
    roomJson(
      id: 'r1',
      name: 'Sala 101',
      todayEnergyKwh: 2.5,
      devices:
          deviceList ??
          [
            deviceJson(id: 'd1', name: 'Luz A', status: 'ON'),
            deviceJson(id: 'd2', name: 'Luz B', status: 'ON'),
            deviceJson(id: 'd3', name: 'Projetor', type: 'PROJECTOR'),
            deviceJson(
              id: 'd4',
              name: 'Ar',
              type: 'AC',
              status: 'ON',
              online: false,
            ),
          ],
    ),
  );

  setUp(() {
    environments = _MockEnvironments();
    devices = _MockDevices();
    events = StreamController<DeviceEvent>.broadcast(sync: true);
    when(() => environments.watchRoom('r1'))
        .thenAnswer((_) => Stream.value(Cached(room())));
  });

  tearDown(() => events.close());

  Future<void> pumpPage(
    WidgetTester tester, {
    UserRole role = UserRole.technician,
  }) async {
    // Tela alta: a lista inteira cabe sem rolar.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpRouterApp(
      initialLocation: '/room',
      routes: [
        GoRoute(
          path: '/room',
          builder: (_, _) => const RoomDetailPage(
            buildingId: 'b1',
            floorId: 'f1',
            roomId: 'r1',
          ),
        ),
      ],
      overrides: [
        environmentsRepositoryProvider.overrideWithValue(environments),
        deviceRepositoryProvider.overrideWithValue(devices),
        deviceEventsProvider.overrideWithValue(events.stream),
        realtimeStatusProvider.overrideWithValue(
          RealtimeConnectionStatus.connected,
        ),
        currentUserRoleProvider.overrideWithValue(role),
      ],
    );
    await tester.pumpAndSettle();
  }

  String kpi(WidgetTester tester, String label) =>
      tester.widget<KpiCard>(find.widgetWithText(KpiCard, label)).value;

  testWidgets('mostra os KPIs e a lista de dispositivos', (tester) async {
    await pumpPage(tester);

    expect(kpi(tester, 'Ligados'), '3/4');
    expect(kpi(tester, 'Online'), '3/4');
    expect(kpi(tester, 'Consumo hoje'), '2,50 kWh');
    expect(find.byType(LiveDeviceRow), findsNWidgets(4));
  });

  testWidgets('"Desligar todos" pede confirmação e desliga os online', (
    tester,
  ) async {
    when(() => devices.bulkControl(any(), command: any(named: 'command')))
        .thenAnswer(
          (_) async => const BulkControlResult(
            successCount: 2,
            failedCount: 0,
            failedDevices: [],
          ),
        );
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('room-turn-off-all')));
    await tester.pumpAndSettle();
    expect(
      find.text('Os 2 dispositivos ligados em Sala 101 serão desligados.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Desligar'));
    await tester.pumpAndSettle();

    verify(() => devices.bulkControl(['d1', 'd2'], command: DeviceCommand.off))
        .called(1);
    expect(find.text('2 dispositivos desligados.'), findsOneWidget);
    expect(kpi(tester, 'Ligados'), '1/4');
  });

  testWidgets('cancelar a confirmação não chama o backend', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('room-turn-off-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verifyNever(
      () => devices.bulkControl(any(), command: any(named: 'command')),
    );
  });

  testWidgets('falha parcial é informada', (tester) async {
    when(() => devices.bulkControl(any(), command: any(named: 'command')))
        .thenAnswer(
          (_) async => const BulkControlResult(
            successCount: 1,
            failedCount: 1,
            failedDevices: ['d2'],
          ),
        );
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('room-turn-off-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desligar'));
    await tester.pumpAndSettle();

    expect(find.text('1 de 2 desligados; 1 não responderam.'), findsOneWidget);
  });

  testWidgets('erro na request desfaz e mostra a mensagem', (tester) async {
    when(() => devices.bulkControl(any(), command: any(named: 'command')))
        .thenThrow(const NetworkException());
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('room-turn-off-all')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Desligar'));
    await tester.pumpAndSettle();

    expect(find.text('Sem conexão com a internet.'), findsOneWidget);
    expect(kpi(tester, 'Ligados'), '3/4');
  });

  testWidgets('sem nada ligado e online, o botão fica desabilitado', (
    tester,
  ) async {
    when(() => environments.watchRoom('r1')).thenAnswer(
      (_) =>
          Stream.value(Cached(room(deviceList: [deviceJson(status: 'OFF')]))),
    );
    await pumpPage(tester);

    final button = tester.widget<IconButton>(
      find.byKey(const Key('room-turn-off-all')),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('VIEWER não vê o "Desligar todos"', (tester) async {
    await pumpPage(tester, role: UserRole.viewer);

    expect(find.byKey(const Key('room-turn-off-all')), findsNothing);
  });

  testWidgets('sala sem dispositivos mostra o estado vazio', (tester) async {
    when(() => environments.watchRoom('r1'))
        .thenAnswer((_) => Stream.value(Cached(room(deviceList: []))));
    await pumpPage(tester);

    expect(find.text('Nenhum dispositivo nesta sala'), findsOneWidget);
  });
}
