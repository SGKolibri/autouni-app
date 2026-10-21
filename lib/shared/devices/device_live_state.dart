import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cached.dart';
import '../models/campus/campus_enums.dart';
import '../models/campus/campus_models.dart';
import '../realtime/device_events.dart';

/// Alterações conhecidas de um dispositivo desde o último carregamento:
/// vindas do WebSocket ou de um comando otimista. Campos nulos = sem
/// alteração.
@immutable
class DeviceOverride {
  const DeviceOverride({
    this.status,
    this.online,
    this.intensity,
    this.temperature,
  });

  final DeviceStatus? status;
  final bool? online;
  final int? intensity;
  final double? temperature;

  DeviceOverride merge(DeviceOverride patch) => DeviceOverride(
    status: patch.status ?? status,
    online: patch.online ?? online,
    intensity: patch.intensity ?? intensity,
    temperature: patch.temperature ?? temperature,
  );

  /// Só os ajustes (o backend não persiste brilho nem temperatura, então eles
  /// sobrevivem a um recarregamento).
  DeviceOverride? get settingsOnly => intensity == null && temperature == null
      ? null
      : DeviceOverride(intensity: intensity, temperature: temperature);
}

/// Camada "ao vivo" sobre os dispositivos carregados das telas.
@immutable
class LiveDevices {
  const LiveDevices({this.overrides = const {}, this.pending = const {}});

  final Map<String, DeviceOverride> overrides;

  /// Dispositivos com comando aguardando confirmação.
  final Set<String> pending;

  bool isPending(String deviceId) => pending.contains(deviceId);

  /// [base] com as alterações conhecidas aplicadas.
  Device apply(Device base) {
    final override = overrides[base.id];
    if (override == null) return base;
    return base.copyWith(
      status: override.status ?? base.status,
      online: override.online ?? base.online,
      metadata: override.intensity == null && override.temperature == null
          ? base.metadata
          : {
              ...?base.metadata,
              'intensity': ?override.intensity,
              'temperature': ?override.temperature,
            },
    );
  }

  List<Device> applyAll(Iterable<Device> devices) => [
    for (final device in devices) apply(device),
  ];
}

/// Comando em andamento sobre um dispositivo (ver [DeviceLiveState.begin]).
class CommandTicket {
  CommandTicket._(this.deviceId, this._previous, this._eventSeq);

  final String deviceId;
  final DeviceOverride? _previous;
  final int _eventSeq;
}

/// Mantém o estado ao vivo: aplica `device:status`/`device:online` e os
/// comandos otimistas (com confirmação e rollback).
class DeviceLiveState extends Notifier<LiveDevices> {
  /// Quanto esperar o hardware confirmar um comando antes de desistir do
  /// indicador de "pendente" (o estado gravado no backend segue valendo).
  static const Duration pendingTimeout = Duration(seconds: 10);

  final Map<String, Timer> _timers = {};
  final Map<String, int> _eventSeq = {};

  @override
  LiveDevices build() {
    final events = ref.watch(deviceEventsProvider).listen(_onEvent);
    ref.onDispose(() {
      unawaited(events.cancel());
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });
    return const LiveDevices();
  }

  void _onEvent(DeviceEvent event) {
    final id = event.deviceId;
    _eventSeq[id] = (_eventSeq[id] ?? 0) + 1;
    switch (event) {
      case DeviceStatusChanged(:final status):
        // O backend confirmou o estado: fim do "pendente".
        _cancelTimer(id);
        _patch(id, DeviceOverride(status: status), pending: false);
      case DeviceOnlineChanged(:final online):
        _patch(id, DeviceOverride(online: online));
    }
  }

  /// Aplica o estado alvo de um comando e marca o dispositivo como pendente.
  CommandTicket begin(String deviceId, DeviceOverride target) {
    final ticket = CommandTicket._(
      deviceId,
      state.overrides[deviceId],
      _eventSeq[deviceId] ?? 0,
    );
    _cancelTimer(deviceId);
    _patch(deviceId, target, pending: true);
    return ticket;
  }

  /// O backend aceitou o comando e gravou [server].
  ///
  /// Se um evento do WebSocket chegou durante a request, ele é mais novo e
  /// prevalece. Com [awaitingHardware], segue "pendente" até o evento de
  /// confirmação ou até [pendingTimeout].
  void confirm(
    CommandTicket ticket, {
    required Device server,
    required bool awaitingHardware,
  }) {
    final id = ticket.deviceId;
    final eventArrived = (_eventSeq[id] ?? 0) != ticket._eventSeq;
    final stillPending = awaitingHardware && !eventArrived;
    _patch(
      id,
      DeviceOverride(
        status: eventArrived ? null : server.status,
        online: server.online,
      ),
      pending: stillPending,
    );
    if (stillPending) {
      _timers[id] = Timer(pendingTimeout, () {
        _timers.remove(id);
        if (ref.mounted) _setPending(id, pending: false);
      });
    }
  }

  /// O comando falhou: volta ao estado de antes, a menos que um evento do
  /// WebSocket tenha trazido um estado mais novo nesse meio tempo.
  void rollback(CommandTicket ticket) {
    final id = ticket.deviceId;
    _cancelTimer(id);
    final eventArrived = (_eventSeq[id] ?? 0) != ticket._eventSeq;
    final overrides = {...state.overrides};
    if (!eventArrived) {
      if (ticket._previous == null) {
        overrides.remove(id);
      } else {
        overrides[id] = ticket._previous;
      }
    }
    state = LiveDevices(
      overrides: overrides,
      pending: {...state.pending}..remove(id),
    );
  }

  /// Dados frescos da rede chegaram: descarta as alterações de estado já
  /// refletidas neles (as de dispositivos com comando pendente ficam).
  void reconcile(Iterable<Device> fresh) {
    final overrides = {...state.overrides};
    var changed = false;
    for (final device in fresh) {
      final current = overrides[device.id];
      if (current == null || state.isPending(device.id)) continue;
      final kept = current.settingsOnly;
      if (kept == null) {
        overrides.remove(device.id);
      } else {
        overrides[device.id] = kept;
      }
      changed = true;
    }
    if (changed) {
      state = LiveDevices(overrides: overrides, pending: state.pending);
    }
  }

  void _patch(String id, DeviceOverride patch, {bool? pending}) {
    final current = state.overrides[id] ?? const DeviceOverride();
    final pendingSet = {...state.pending};
    if (pending == true) pendingSet.add(id);
    if (pending == false) pendingSet.remove(id);
    state = LiveDevices(
      overrides: {...state.overrides, id: current.merge(patch)},
      pending: pendingSet,
    );
  }

  void _setPending(String id, {required bool pending}) {
    final pendingSet = {...state.pending};
    pending ? pendingSet.add(id) : pendingSet.remove(id);
    state = LiveDevices(overrides: state.overrides, pending: pendingSet);
  }

  void _cancelTimer(String id) => _timers.remove(id)?.cancel();
}

final deviceLiveStateProvider = NotifierProvider<DeviceLiveState, LiveDevices>(
  DeviceLiveState.new,
  name: 'deviceLiveStateProvider',
);

/// Passa [source] adiante e, a cada resposta fresca da rede, reconcilia o
/// estado ao vivo com os dispositivos dela (ver [DeviceLiveState.reconcile]).
Stream<Cached<T>> reconcileLiveDevices<T>(
  Ref ref,
  Stream<Cached<T>> source,
  Iterable<Device> Function(T data) devicesOf,
) => source.map((cached) {
  if (!cached.isStale) {
    final live = ref.read(deviceLiveStateProvider.notifier);
    final devices = devicesOf(cached.data).toList();
    // Fora do build do provider: Riverpod não deixa alterar outro provider
    // durante a inicialização.
    Future.microtask(() {
      if (ref.mounted) live.reconcile(devices);
    });
  }
  return cached;
});
