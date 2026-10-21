import 'dart:async';

import 'package:autouni_app/shared/devices/device_live_state.dart';
import 'package:autouni_app/shared/models/campus/campus_enums.dart';
import 'package:autouni_app/shared/realtime/device_events.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/campus_fixtures.dart';

void main() {
  late StreamController<DeviceEvent> events;
  late ProviderContainer container;

  LiveDevices live() => container.read(deviceLiveStateProvider);
  DeviceLiveState notifier() =>
      container.read(deviceLiveStateProvider.notifier);

  void emit(DeviceEvent event) => events.add(event);

  setUp(() {
    events = StreamController<DeviceEvent>.broadcast(sync: true);
    container = ProviderContainer.test(
      overrides: [deviceEventsProvider.overrideWithValue(events.stream)],
    );
    container.listen(deviceLiveStateProvider, (_, _) {});
  });

  tearDown(() => events.close());

  group('eventos do WebSocket', () {
    test('device:status muda o estado aplicado', () {
      emit(const DeviceStatusChanged(deviceId: 'd1', status: DeviceStatus.on));

      expect(live().apply(device()).status, DeviceStatus.on);
      expect(live().apply(device(id: 'd2')).status, DeviceStatus.off);
    });

    test('device:online muda a disponibilidade', () {
      emit(const DeviceOnlineChanged(deviceId: 'd1', online: false));

      expect(live().apply(device()).online, isFalse);
    });

    test('eventos se acumulam sobre o mesmo dispositivo', () {
      emit(const DeviceOnlineChanged(deviceId: 'd1', online: false));
      emit(const DeviceStatusChanged(deviceId: 'd1', status: DeviceStatus.on));

      final applied = live().apply(device());
      expect((applied.status, applied.online), (DeviceStatus.on, false));
    });
  });

  group('comando otimista', () {
    test('begin aplica o alvo na hora e marca pendente', () {
      notifier().begin('d1', const DeviceOverride(status: DeviceStatus.on));

      expect(live().apply(device()).status, DeviceStatus.on);
      expect(live().isPending('d1'), isTrue);
    });

    test('confirm sem espera de hardware encerra o pendente', () {
      final ticket = notifier().begin(
        'd1',
        const DeviceOverride(status: DeviceStatus.on),
      );

      notifier().confirm(
        ticket,
        server: device(status: DeviceStatus.on),
        awaitingHardware: false,
      );

      expect(live().isPending('d1'), isFalse);
      expect(live().apply(device()).status, DeviceStatus.on);
    });

    test('aguardando hardware, o evento do WebSocket confirma', () {
      final ticket = notifier().begin(
        'd1',
        const DeviceOverride(status: DeviceStatus.on),
      );
      notifier().confirm(
        ticket,
        server: device(status: DeviceStatus.on),
        awaitingHardware: true,
      );
      expect(live().isPending('d1'), isTrue);

      emit(const DeviceStatusChanged(deviceId: 'd1', status: DeviceStatus.on));

      expect(live().isPending('d1'), isFalse);
    });

    test('evento que chega antes da resposta HTTP já confirma', () {
      final ticket = notifier().begin(
        'd1',
        const DeviceOverride(status: DeviceStatus.on),
      );
      emit(const DeviceStatusChanged(deviceId: 'd1', status: DeviceStatus.on));

      notifier().confirm(
        ticket,
        server: device(status: DeviceStatus.on),
        awaitingHardware: true,
      );

      expect(live().isPending('d1'), isFalse);
    });

    test('sem confirmação do hardware, o pendente expira', () {
      fakeAsync((async) {
        final ticket = notifier().begin(
          'd1',
          const DeviceOverride(status: DeviceStatus.on),
        );
        notifier().confirm(
          ticket,
          server: device(status: DeviceStatus.on),
          awaitingHardware: true,
        );

        async.elapse(DeviceLiveState.pendingTimeout);

        expect(live().isPending('d1'), isFalse);
        expect(live().apply(device()).status, DeviceStatus.on);
      });
    });

    test('rollback volta ao estado anterior', () {
      emit(const DeviceOnlineChanged(deviceId: 'd1', online: true));
      final ticket = notifier().begin(
        'd1',
        const DeviceOverride(status: DeviceStatus.on),
      );

      notifier().rollback(ticket);

      expect(live().apply(device()).status, DeviceStatus.off);
      expect(live().isPending('d1'), isFalse);
      expect(live().overrides['d1']?.online, isTrue);
    });

    test('rollback não desfaz um evento mais novo do WebSocket', () {
      final ticket = notifier().begin(
        'd1',
        const DeviceOverride(status: DeviceStatus.on),
      );
      emit(
        const DeviceStatusChanged(deviceId: 'd1', status: DeviceStatus.error),
      );

      notifier().rollback(ticket);

      expect(live().apply(device()).status, DeviceStatus.error);
    });
  });

  group('ajustes', () {
    test('intensidade e temperatura entram no metadata aplicado', () {
      notifier().begin(
        'd1',
        const DeviceOverride(intensity: 40, temperature: 21),
      );

      final applied = live().apply(device(metadata: {'power': 40}));
      expect(applied.intensity, 40);
      expect(applied.temperature, 21);
      expect(applied.powerWatts, 40);
    });
  });

  group('reconcile', () {
    test('descarta alterações de estado já refletidas na rede', () {
      emit(const DeviceStatusChanged(deviceId: 'd1', status: DeviceStatus.on));

      notifier().reconcile([device()]);

      expect(live().overrides, isEmpty);
    });

    test('mantém os ajustes (o backend não os persiste)', () {
      final ticket = notifier().begin(
        'd1',
        const DeviceOverride(status: DeviceStatus.on, intensity: 30),
      );
      notifier().confirm(
        ticket,
        server: device(status: DeviceStatus.on),
        awaitingHardware: false,
      );

      notifier().reconcile([device(status: DeviceStatus.on)]);

      expect(live().overrides['d1']?.status, isNull);
      expect(live().overrides['d1']?.intensity, 30);
    });

    test('não mexe em dispositivos com comando pendente', () {
      notifier().begin('d1', const DeviceOverride(status: DeviceStatus.on));

      notifier().reconcile([device()]);

      expect(live().apply(device()).status, DeviceStatus.on);
    });
  });
}
