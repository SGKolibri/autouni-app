import 'dart:async';

import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/shared/devices/device_commands.dart';
import 'package:autouni_app/shared/devices/device_controller.dart';
import 'package:autouni_app/shared/devices/device_live_state.dart';
import 'package:autouni_app/shared/devices/device_repository.dart';
import 'package:autouni_app/shared/models/campus/campus_enums.dart';
import 'package:autouni_app/shared/models/campus/campus_models.dart';
import 'package:autouni_app/shared/models/user_role.dart';
import 'package:autouni_app/shared/rbac/rbac_providers.dart';
import 'package:autouni_app/shared/realtime/device_events.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/campus_fixtures.dart';

class _MockDeviceRepository extends Mock implements DeviceRepository {}

void main() {
  late _MockDeviceRepository repository;
  late StreamController<DeviceEvent> events;
  late ProviderContainer container;

  setUpAll(() => registerFallbackValue(DeviceCommand.on));

  ProviderContainer build({UserRole role = UserRole.technician}) {
    final c = ProviderContainer.test(
      overrides: [
        deviceRepositoryProvider.overrideWithValue(repository),
        deviceEventsProvider.overrideWithValue(events.stream),
        currentUserRoleProvider.overrideWithValue(role),
      ],
    );
    c.listen(deviceLiveStateProvider, (_, _) {});
    return c;
  }

  DeviceController controller() => container.read(deviceControllerProvider);
  LiveDevices live() => container.read(deviceLiveStateProvider);

  When<Future<ControlResult>> whenControl() => when(
    () => repository.control(
      any(),
      command: any(named: 'command'),
      intensity: any(named: 'intensity'),
      temperature: any(named: 'temperature'),
    ),
  );

  void verifyNoControl() => verifyNever(
    () => repository.control(
      any(),
      command: any(named: 'command'),
      intensity: any(named: 'intensity'),
      temperature: any(named: 'temperature'),
    ),
  );

  setUp(() {
    repository = _MockDeviceRepository();
    events = StreamController<DeviceEvent>.broadcast(sync: true);
    container = build();
  });

  tearDown(() => events.close());

  group('setPower (toggle otimista)', () {
    test('muda na hora e confirma com a resposta do backend', () async {
      final pending = Completer<ControlResult>();
      whenControl().thenAnswer((_) => pending.future);

      final call = controller().setPower(device(), on: true);

      expect(live().apply(device()).status, DeviceStatus.on);
      expect(live().isPending('d1'), isTrue);

      pending.complete(
        ControlResult(device: device(status: DeviceStatus.on), pending: false),
      );
      final outcome = await call;

      expect(outcome.isSuccess, isTrue);
      expect(live().isPending('d1'), isFalse);
      verify(() => repository.control('d1', command: DeviceCommand.on));
    });

    test('erro do backend faz rollback e devolve a mensagem', () async {
      whenControl().thenThrow(const NetworkException());

      final outcome = await controller().setPower(device(), on: true);

      expect(outcome.status, ControlStatus.failed);
      expect(outcome.message, 'Sem conexão com a internet.');
      expect(live().apply(device()).status, DeviceStatus.off);
      expect(live().isPending('d1'), isFalse);
    });

    test('desligar envia o comando off', () async {
      whenControl().thenAnswer(
        (_) async => ControlResult(device: device(), pending: false),
      );

      await controller().setPower(device(status: DeviceStatus.on), on: false);

      verify(() => repository.control('d1', command: DeviceCommand.off));
    });

    test(
      'ignora um segundo comando enquanto o primeiro está pendente',
      () async {
        final pending = Completer<ControlResult>();
        whenControl().thenAnswer((_) => pending.future);

        final first = controller().setPower(device(), on: true);
        final second = await controller().setPower(device(), on: false);

        expect(second.status, ControlStatus.busy);
        pending.complete(
          ControlResult(
            device: device(status: DeviceStatus.on),
            pending: false,
          ),
        );
        await first;
        verify(() => repository.control(any(), command: any(named: 'command')))
            .called(1);
      },
    );
  });

  group('dispositivo offline (S4-T6)', () {
    test('não envia comando e avisa que está indisponível', () async {
      final outcome = await controller().setPower(
        device(online: false),
        on: true,
      );

      expect(outcome.status, ControlStatus.offline);
      verifyNoControl();
      expect(live().overrides, isEmpty);
    });

    test('vale também quando o WebSocket avisou que caiu', () async {
      events.add(const DeviceOnlineChanged(deviceId: 'd1', online: false));

      final outcome = await controller().setIntensity(device(), 50);

      expect(outcome.status, ControlStatus.offline);
      verifyNoControl();
    });
  });

  group('RBAC', () {
    test('VIEWER não controla dispositivos', () async {
      container = build(role: UserRole.viewer);

      final outcome = await controller().setPower(device(), on: true);

      expect(outcome.status, ControlStatus.forbidden);
      verifyNoControl();
    });

    test('VIEWER não usa o "desligar todos"', () async {
      container = build(role: UserRole.viewer);

      final outcome = await controller().turnOffAll([
        device(status: DeviceStatus.on),
      ]);

      expect(outcome.forbidden, isTrue);
      verifyNever(
        () => repository.bulkControl(any(), command: any(named: 'command')),
      );
    });
  });

  group('controles contextuais (S4-T4)', () {
    test('dimmer envia on + intensidade', () async {
      whenControl().thenAnswer(
        (_) async => ControlResult(
          device: device(status: DeviceStatus.on),
          pending: false,
        ),
      );

      final outcome = await controller().setIntensity(device(), 70);

      expect(outcome.isSuccess, isTrue);
      verify(
        () =>
            repository.control('d1', command: DeviceCommand.on, intensity: 70),
      );
      expect(live().apply(device()).intensity, 70);
    });

    test('dimmer fora de 0–100 é recusado sem request', () async {
      final outcome = await controller().setIntensity(device(), 120);

      expect(outcome.status, ControlStatus.invalid);
      verifyNoControl();
    });

    test('termostato envia on + temperatura', () async {
      final ac = device(type: DeviceType.ac);
      whenControl().thenAnswer(
        (_) async => ControlResult(device: ac, pending: false),
      );

      await controller().setTemperature(ac, 22);

      verify(
        () => repository.control(
          'd1',
          command: DeviceCommand.on,
          temperature: 22,
        ),
      );
      expect(live().apply(ac).temperature, 22);
    });

    for (final value in [15.0, 31.0]) {
      test('termostato recusa $value °C', () async {
        final outcome = await controller().setTemperature(
          device(type: DeviceType.ac),
          value,
        );

        expect(outcome.status, ControlStatus.invalid);
        expect(outcome.message, 'A temperatura vai de 16 °C a 30 °C.');
        verifyNoControl();
      });
    }

    test('erro ao ajustar desfaz o ajuste otimista', () async {
      whenControl().thenThrow(
        const ServerException(message: 'Erro no servidor.'),
      );

      await controller().setIntensity(device(metadata: {'intensity': 10}), 90);

      expect(live().apply(device(metadata: {'intensity': 10})).intensity, 10);
    });
  });

  group('turnOffAll (S4-T3)', () {
    final on1 = device(id: 'on1', status: DeviceStatus.on);
    final on2 = device(id: 'on2', status: DeviceStatus.on);
    final off = device(id: 'off');
    final offline = device(
      id: 'offline',
      status: DeviceStatus.on,
      online: false,
    );

    test('desliga só os ligados e online, numa única chamada', () async {
      when(() => repository.bulkControl(any(), command: any(named: 'command')))
          .thenAnswer(
            (_) async => const BulkControlResult(
              successCount: 2,
              failedCount: 0,
              failedDevices: [],
            ),
          );

      final outcome = await controller().turnOffAll([on1, on2, off, offline]);

      verify(
        () =>
            repository.bulkControl(['on1', 'on2'], command: DeviceCommand.off),
      ).called(1);
      expect(outcome.requested, 2);
      expect(outcome.succeeded, 2);
      expect(live().apply(on1).status, DeviceStatus.off);
      expect(live().apply(offline).status, DeviceStatus.on);
    });

    test('falha parcial desfaz só os que falharam', () async {
      when(() => repository.bulkControl(any(), command: any(named: 'command')))
          .thenAnswer(
            (_) async => const BulkControlResult(
              successCount: 1,
              failedCount: 1,
              failedDevices: ['on2'],
            ),
          );

      final outcome = await controller().turnOffAll([on1, on2]);

      expect(outcome.failedIds, ['on2']);
      expect(outcome.succeeded, 1);
      expect(live().apply(on1).status, DeviceStatus.off);
      expect(live().apply(on2).status, DeviceStatus.on);
    });

    test('erro na request desfaz todos', () async {
      when(() => repository.bulkControl(any(), command: any(named: 'command')))
          .thenThrow(const NetworkException());

      final outcome = await controller().turnOffAll([on1, on2]);

      expect(outcome.error, 'Sem conexão com a internet.');
      expect(outcome.succeeded, 0);
      expect(live().applyAll([on1, on2]).map((d) => d.status), [
        DeviceStatus.on,
        DeviceStatus.on,
      ]);
    });

    test('nada ligado: não chama o backend', () async {
      final outcome = await controller().turnOffAll(<Device>[off, offline]);

      expect(outcome.requested, 0);
      verifyNever(
        () => repository.bulkControl(any(), command: any(named: 'command')),
      );
    });
  });
}
