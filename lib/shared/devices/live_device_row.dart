import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/design_system.dart';
import '../models/campus/campus_models.dart';
import '../rbac/app_permission.dart';
import '../rbac/rbac_providers.dart';
import 'device_controller.dart';
import 'device_detail_sheet.dart';
import 'device_live_state.dart';
import 'device_presentation.dart';

/// [DeviceRow] ligada ao estado ao vivo: aplica eventos do WebSocket, faz o
/// toggle otimista, trava enquanto o comando aguarda confirmação, desabilita
/// offline e vira somente leitura sem permissão (VIEWER).
///
/// Tocar na linha abre o detalhe com os controles contextuais.
class LiveDeviceRow extends ConsumerWidget {
  const LiveDeviceRow({
    required this.device,
    this.showLocation = false,
    super.key,
  });

  /// Dispositivo como carregado da API (o estado ao vivo é aplicado aqui).
  final Device device;

  /// Mostra "Sala · Andar · Prédio" no lugar do status (lista global).
  final bool showLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(deviceLiveStateProvider);
    final current = live.apply(device);
    final canControl = ref.watch(
      hasPermissionProvider(AppPermission.controlDevices),
    );
    final location = showLocation ? current.locationLabel : null;

    return DeviceRow(
      key: ValueKey('device-row-${device.id}'),
      name: current.name,
      icon: deviceIcon(current.type),
      subtitle: location == null
          ? deviceSummary(current)
          : '${deviceSummary(current)} · $location',
      isOn: current.isOn,
      isOffline: !current.online,
      busy: live.isPending(device.id),
      onToggle: canControl
          ? (on) => runDeviceCommand(
              context,
              ref.read(deviceControllerProvider).setPower(device, on: on),
            )
          : null,
      onTap: () => showDeviceDetailSheet(context, device),
    );
  }
}

/// Aguarda um comando e mostra a falha num snackbar.
Future<void> runDeviceCommand(
  BuildContext context,
  Future<ControlOutcome> command,
) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  final outcome = await command;
  final message = outcome.message;
  if (outcome.isSuccess || message == null || messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}
