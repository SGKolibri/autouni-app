import 'dart:async';

import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:autouni_app/shared/devices/device_commands.dart';
import 'package:autouni_app/shared/devices/device_detail_sheet.dart';
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

import '../../support/campus_fixtures.dart';
import '../../support/pump_app.dart';

class _MockDeviceRepository extends Mock implements DeviceRepository {}

void main() {
  late _MockDeviceRepository repository;
  late StreamController<DeviceEvent> events;

  setUpAll(() => registerFallbackValue(DeviceCommand.on));

  setUp(() {
    repository = _MockDeviceRepository();
    events = StreamController<DeviceEvent>.broadcast(sync: true);
  });

  tearDown(() => events.close());

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget child, {
    UserRole role = UserRole.technician,
  }) => tester.pumpApp(
    child,
    overrides: [
      deviceRepositoryProvider.overrideWithValue(repository),
      deviceEventsProvider.overrideWithValue(events.stream),
      currentUserRoleProvider.overrideWithValue(role),
    ],
  );

  When<Future<ControlResult>> whenControl() => when(
    () => repository.control(
      any(),
      command: any(named: 'command'),
      intensity: any(named: 'intensity'),
      temperature: any(named: 'temperature'),
    ),
  );

  Switch rowSwitch(WidgetTester tester) =>
      tester.widget<Switch>(find.byType(Switch));

  group('LiveDeviceRow', () {
    testWidgets('toggle muda na hora, trava e confirma', (tester) async {
      final pending = Completer<ControlResult>();
      whenControl().thenAnswer((_) => pending.future);
      await pump(tester, LiveDeviceRow(device: device()));

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(rowSwitch(tester).value, isTrue);
      expect(rowSwitch(tester).onChanged, isNull);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      pending.complete(
        ControlResult(device: device(status: DeviceStatus.on), pending: false),
      );
      await tester.pumpAndSettle();

      expect(rowSwitch(tester).value, isTrue);
      expect(rowSwitch(tester).onChanged, isNotNull);
      expect(find.text('Ligado'), findsOneWidget);
    });

    testWidgets('erro desfaz o toggle e mostra a mensagem', (tester) async {
      whenControl().thenThrow(const NetworkException());
      await pump(tester, LiveDeviceRow(device: device()));

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();

      expect(rowSwitch(tester).value, isFalse);
      expect(find.text('Sem conexão com a internet.'), findsOneWidget);
    });

    testWidgets('evento do WebSocket atualiza a linha', (tester) async {
      await pump(tester, LiveDeviceRow(device: device()));

      events.add(
        const DeviceStatusChanged(deviceId: 'd1', status: DeviceStatus.on),
      );
      await tester.pump();

      expect(rowSwitch(tester).value, isTrue);
    });

    testWidgets('dispositivo que cai fica offline e sem controle', (
      tester,
    ) async {
      await pump(tester, LiveDeviceRow(device: device()));

      events.add(const DeviceOnlineChanged(deviceId: 'd1', online: false));
      await tester.pump();

      expect(find.text('Offline'), findsOneWidget);
      expect(rowSwitch(tester).onChanged, isNull);
    });

    testWidgets('VIEWER vê o estado, mas não controla', (tester) async {
      await pump(
        tester,
        LiveDeviceRow(device: device(status: DeviceStatus.on)),
        role: UserRole.viewer,
      );

      expect(rowSwitch(tester).value, isTrue);
      expect(rowSwitch(tester).onChanged, isNull);
    });

    testWidgets('lista global mostra a localização', (tester) async {
      await pump(
        tester,
        LiveDeviceRow(
          device: device(
            room: const Room(id: 'r1', floorId: 'f1', name: 'Sala 101'),
          ),
          showLocation: true,
        ),
      );

      expect(find.text('Desligado · Sala 101'), findsOneWidget);
    });
  });

  group('DeviceDetailSheet', () {
    final light = device(
      status: DeviceStatus.on,
      metadata: {'intensity': 40, 'power': 60},
    );
    final ac = device(
      id: 'ac1',
      name: 'Ar 1',
      type: DeviceType.ac,
      status: DeviceStatus.on,
      metadata: {'temperature': 22},
    );

    testWidgets('iluminação mostra o dimmer com o brilho atual', (
      tester,
    ) async {
      await pump(tester, DeviceDetailSheet(device: light));

      expect(find.text('Brilho: 40%'), findsOneWidget);
      expect(find.text('60 W'), findsOneWidget);
      expect(find.byKey(const Key('thermostat-value')), findsNothing);
    });

    testWidgets('soltar o dimmer envia o brilho', (tester) async {
      whenControl().thenAnswer(
        (_) async => ControlResult(device: light, pending: false),
      );
      await pump(tester, DeviceDetailSheet(device: light));

      await tester.drag(
        find.byKey(const Key('device-dimmer')),
        const Offset(-2000, 0),
      );
      await tester.pumpAndSettle();

      verify(
        () => repository.control('d1', command: DeviceCommand.on, intensity: 0),
      ).called(1);
      expect(find.text('Brilho: 0%'), findsOneWidget);
    });

    testWidgets('termostato sobe e desce 1 °C por toque', (tester) async {
      whenControl().thenAnswer(
        (_) async => ControlResult(device: ac, pending: false),
      );
      await pump(tester, DeviceDetailSheet(device: ac));

      expect(find.text('22 °C'), findsOneWidget);
      await tester.tap(find.byKey(const Key('thermostat-up')));
      await tester.pumpAndSettle();

      verify(
        () => repository.control(
          'ac1',
          command: DeviceCommand.on,
          temperature: 23,
        ),
      ).called(1);
      expect(find.text('23 °C'), findsOneWidget);
    });

    testWidgets('no limite do termostato o botão fica desabilitado', (
      tester,
    ) async {
      await pump(
        tester,
        DeviceDetailSheet(device: ac.copyWith(metadata: {'temperature': 30})),
      );

      final up = tester.widget<IconButton>(
        find.byKey(const Key('thermostat-up')),
      );
      expect(up.onPressed, isNull);
    });

    testWidgets('offline avisa e desabilita os controles', (tester) async {
      await pump(tester, DeviceDetailSheet(device: ac.copyWith(online: false)));

      expect(
        find.text('Dispositivo offline. Controle indisponível.'),
        findsOneWidget,
      );
      final power = tester.widget<SwitchListTile>(
        find.byKey(const Key('device-power')),
      );
      expect(power.onChanged, isNull);
    });

    testWidgets('VIEWER: as ações não renderizam, só os valores', (
      tester,
    ) async {
      await pump(tester, DeviceDetailSheet(device: ac), role: UserRole.viewer);

      expect(find.text('Seu perfil é somente leitura.'), findsOneWidget);
      expect(find.byKey(const Key('device-power')), findsNothing);
      expect(find.byKey(const Key('thermostat-up')), findsNothing);
      expect(find.text('22 °C'), findsOneWidget);
    });

    testWidgets('tocar na linha abre o detalhe', (tester) async {
      await pump(tester, LiveDeviceRow(device: light));

      await tester.tap(find.text('Luminária 1'));
      await tester.pumpAndSettle();

      expect(find.byType(DeviceDetailSheet), findsOneWidget);
      expect(find.byType(StatusBadge), findsWidgets);
    });
  });

  test('fixture sem localização não quebra o resumo', () {
    expect(device().locationLabel, isNull);
    expect(const Room(id: 'r', floorId: 'f', name: 'S').devices, isEmpty);
    expect(Device.fromJson(deviceJson()).id, 'd1');
  });
}
