import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../models/campus/campus_enums.dart';
import '../models/campus/campus_models.dart';
import '../rbac/app_permission.dart';
import '../rbac/rbac_providers.dart';
import 'device_commands.dart';
import 'device_limits.dart';
import 'device_live_state.dart';
import 'device_repository.dart';

/// Desfecho de um comando individual.
enum ControlStatus {
  success,

  /// Dispositivo offline: controle indisponível (nenhuma request sai).
  offline,

  /// O papel do usuário não permite (VIEWER).
  forbidden,

  /// Já há um comando aguardando confirmação para este dispositivo.
  busy,

  /// Valor fora dos limites (dimmer/termostato).
  invalid,

  /// O backend recusou ou a rede falhou; o estado voltou ao anterior.
  failed,
}

class ControlOutcome {
  const ControlOutcome(this.status, [this.message]);

  final ControlStatus status;

  /// Mensagem apresentável, quando não é sucesso.
  final String? message;

  bool get isSuccess => status == ControlStatus.success;
}

/// Desfecho do "Desligar todos".
class BulkOutcome {
  const BulkOutcome({
    required this.requested,
    this.failedIds = const [],
    this.error,
    this.forbidden = false,
  });

  /// Quantos dispositivos ligados e online entraram no comando.
  final int requested;
  final List<String> failedIds;

  /// A request inteira falhou (nada mudou).
  final String? error;
  final bool forbidden;

  int get succeeded => error != null ? 0 : requested - failedIds.length;
}

/// Comandos sobre dispositivos com atualização otimista: a tela muda na
/// hora, o backend confirma (HTTP + WebSocket) e, em erro, tudo volta ao
/// estado anterior.
class DeviceController {
  DeviceController(this._ref);

  final Ref _ref;

  DeviceRepository get _repository => _ref.read(deviceRepositoryProvider);
  DeviceLiveState get _live => _ref.read(deviceLiveStateProvider.notifier);
  LiveDevices get _liveState => _ref.read(deviceLiveStateProvider);

  bool _can(AppPermission permission) =>
      _ref.read(hasPermissionProvider(permission));

  /// Liga ou desliga.
  Future<ControlOutcome> setPower(Device device, {required bool on}) => _run(
    device,
    DeviceOverride(status: on ? DeviceStatus.on : DeviceStatus.off),
    () => _repository.control(
      device.id,
      command: on ? DeviceCommand.on : DeviceCommand.off,
    ),
  );

  /// Ajusta o brilho (liga a luz, se estiver apagada).
  Future<ControlOutcome> setIntensity(Device device, int intensity) {
    final invalid = DeviceLimits.validateIntensity(intensity);
    if (invalid != null) {
      return Future.value(ControlOutcome(ControlStatus.invalid, invalid));
    }
    return _run(
      device,
      DeviceOverride(status: DeviceStatus.on, intensity: intensity),
      () => _repository.control(
        device.id,
        command: DeviceCommand.on,
        intensity: intensity,
      ),
    );
  }

  /// Ajusta a temperatura alvo (liga o ar, se estiver desligado).
  Future<ControlOutcome> setTemperature(Device device, double temperature) {
    final invalid = DeviceLimits.validateTemperature(temperature);
    if (invalid != null) {
      return Future.value(ControlOutcome(ControlStatus.invalid, invalid));
    }
    return _run(
      device,
      DeviceOverride(status: DeviceStatus.on, temperature: temperature),
      () => _repository.control(
        device.id,
        command: DeviceCommand.on,
        temperature: temperature,
      ),
    );
  }

  /// Desliga todos os dispositivos ligados e online de [devices].
  Future<BulkOutcome> turnOffAll(Iterable<Device> devices) async {
    if (!_can(AppPermission.bulkControlDevices)) {
      return const BulkOutcome(requested: 0, forbidden: true);
    }
    final live = _liveState;
    final targets = [
      for (final device in live.applyAll(devices))
        if (device.online && device.isOn && !live.isPending(device.id)) device,
    ];
    if (targets.isEmpty) return const BulkOutcome(requested: 0);

    final tickets = {
      for (final device in targets)
        device.id: _live.begin(
          device.id,
          const DeviceOverride(status: DeviceStatus.off),
        ),
    };
    try {
      final result = await _repository.bulkControl(
        tickets.keys.toList(),
        command: DeviceCommand.off,
      );
      final failed = result.failedDevices.toSet();
      for (final device in targets) {
        final ticket = tickets[device.id]!;
        if (failed.contains(device.id)) {
          _live.rollback(ticket);
        } else {
          _live.confirm(
            ticket,
            server: device.copyWith(status: DeviceStatus.off),
            awaitingHardware: false,
          );
        }
      }
      return BulkOutcome(
        requested: targets.length,
        failedIds: [
          for (final device in targets)
            if (failed.contains(device.id)) device.id,
        ],
      );
    } on ApiException catch (error) {
      tickets.values.forEach(_live.rollback);
      return BulkOutcome(requested: targets.length, error: error.message);
    }
  }

  Future<ControlOutcome> _run(
    Device device,
    DeviceOverride target,
    Future<ControlResult> Function() request,
  ) async {
    if (!_can(AppPermission.controlDevices)) {
      return const ControlOutcome(
        ControlStatus.forbidden,
        'Seu perfil não permite controlar dispositivos.',
      );
    }
    final live = _liveState;
    if (!live.apply(device).online) {
      return const ControlOutcome(
        ControlStatus.offline,
        'Dispositivo offline. Controle indisponível.',
      );
    }
    if (live.isPending(device.id)) {
      return const ControlOutcome(ControlStatus.busy);
    }

    final ticket = _live.begin(device.id, target);
    try {
      final result = await request();
      _live.confirm(
        ticket,
        server: result.device,
        awaitingHardware: result.pending,
      );
      return const ControlOutcome(ControlStatus.success);
    } on ApiException catch (error) {
      _live.rollback(ticket);
      return ControlOutcome(ControlStatus.failed, error.message);
    }
  }
}

final deviceControllerProvider = Provider<DeviceController>(
  DeviceController.new,
  name: 'deviceControllerProvider',
);
