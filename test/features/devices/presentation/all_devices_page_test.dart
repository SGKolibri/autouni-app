import 'dart:async';

import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/realtime/realtime_client.dart';
import 'package:autouni_app/core/realtime/realtime_providers.dart';
import 'package:autouni_app/features/devices/presentation/pages/all_devices_page.dart';
import 'package:autouni_app/features/devices/presentation/providers/devices_providers.dart';
import 'package:autouni_app/shared/devices/device_repository.dart';
import 'package:autouni_app/shared/devices/live_device_row.dart';
import 'package:autouni_app/shared/models/campus/campus_enums.dart';
import 'package:autouni_app/shared/models/campus/campus_models.dart';
import 'package:autouni_app/shared/models/user_role.dart';
import 'package:autouni_app/shared/rbac/rbac_providers.dart';
import 'package:autouni_app/shared/realtime/device_events.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/campus_fixtures.dart';
import '../../../support/pump_app.dart';

class _MockDevices extends Mock implements DeviceRepository {}

/// 977 dispositivos, como no campus real; os 10 primeiros são ar-condicionado
/// ligados e o 977º está offline.
final _campus = [
  for (var i = 1; i <= 977; i++)
    device(
      id: 'd$i',
      name: 'Dispositivo ${i.toString().padLeft(4, '0')}',
      type: i <= 10 ? DeviceType.ac : DeviceType.light,
      status: i <= 10 ? DeviceStatus.on : DeviceStatus.off,
      online: i != 977,
    ),
];

void main() {
  late _MockDevices repository;
  late StreamController<DeviceEvent> events;

  setUp(() {
    repository = _MockDevices();
    events = StreamController<DeviceEvent>.broadcast(sync: true);
    when(() => repository.watchAll())
        .thenAnswer((_) => Stream.value(Cached(_campus)));
  });

  tearDown(() => events.close());

  Future<ProviderContainer> pumpPage(WidgetTester tester) async {
    final container = await tester.pumpApp(
      const AllDevicesPage(),
      overrides: [
        deviceRepositoryProvider.overrideWithValue(repository),
        deviceEventsProvider.overrideWithValue(events.stream),
        realtimeStatusProvider.overrideWithValue(
          RealtimeConnectionStatus.connected,
        ),
        currentUserRoleProvider.overrideWithValue(UserRole.technician),
      ],
    );
    await tester.pumpAndSettle();
    return container;
  }

  String countText(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('devices-count'))).data!;

  testWidgets('mostra o total e carrega por páginas ao rolar', (tester) async {
    final container = await pumpPage(tester);

    expect(countText(tester), '977 dispositivos');
    expect(container.read(deviceListLimitProvider), 30);

    await tester.scrollUntilVisible(
      find.byKey(const Key('devices-load-more')),
      600,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();

    expect(container.read(deviceListLimitProvider), 60);
    expect(
      container.read(visibleDevicesProvider).value!.data.items,
      hasLength(60),
    );
  });

  testWidgets('a busca filtra e volta à primeira página', (tester) async {
    final container = await pumpPage(tester);
    container.read(deviceListLimitProvider.notifier).loadMore();

    await tester.enterText(find.byKey(const Key('devices-search')), '0977');
    await tester.pumpAndSettle();

    expect(countText(tester), '1 dispositivo');
    expect(find.byType(LiveDeviceRow), findsOneWidget);
    expect(find.text('Offline'), findsOneWidget);
    expect(container.read(deviceListLimitProvider), 30);
  });

  testWidgets('filtros no bottom sheet', (tester) async {
    await pumpPage(tester);

    await tester.tap(find.byKey(const Key('devices-filter')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('filter-type-ac')));
    await tester.pumpAndSettle();

    expect(find.text('Ver 10 dispositivos'), findsOneWidget);
    await tester.tap(find.byKey(const Key('filter-apply')));
    await tester.pumpAndSettle();

    expect(countText(tester), '10 dispositivos');
    expect(find.text('1'), findsOneWidget); // badge de filtros ativos
  });

  testWidgets('sem resultados oferece limpar busca e filtros', (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byKey(const Key('devices-search')), 'xyz');
    await tester.pumpAndSettle();

    expect(find.text('Nenhum dispositivo encontrado'), findsOneWidget);
    await tester.tap(find.text('Limpar busca e filtros'));
    await tester.pumpAndSettle();

    expect(countText(tester), '977 dispositivos');
  });

  testWidgets('evento do WebSocket reflete no filtro de status', (
    tester,
  ) async {
    final container = await pumpPage(tester);
    container.read(deviceFilterProvider.notifier).toggleStatus(DeviceStatus.on);
    await tester.pumpAndSettle();
    expect(countText(tester), '10 dispositivos');

    events.add(
      const DeviceStatusChanged(deviceId: 'd500', status: DeviceStatus.on),
    );
    await tester.pumpAndSettle();

    expect(countText(tester), '11 dispositivos');
  });

  testWidgets('lista vazia no backend mostra o estado vazio', (tester) async {
    when(() => repository.watchAll())
        .thenAnswer((_) => Stream.value(const Cached(<Device>[])));
    await pumpPage(tester);

    expect(find.text('Nenhum dispositivo cadastrado'), findsOneWidget);
  });
}
