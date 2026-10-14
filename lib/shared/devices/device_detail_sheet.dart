import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/design_system.dart';
import '../models/campus/campus_enums.dart';
import '../models/campus/campus_models.dart';
import '../rbac/app_permission.dart';
import '../rbac/rbac_providers.dart';
import '../utils/formatters.dart';
import 'device_controller.dart';
import 'device_limits.dart';
import 'device_live_state.dart';
import 'device_presentation.dart';
import 'live_device_row.dart';

/// Abre o detalhe de [device] com os controles contextuais.
Future<void> showDeviceDetailSheet(BuildContext context, Device device) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => DeviceDetailSheet(device: device),
    );

/// Detalhe de um dispositivo: status, disponibilidade, liga/desliga e o
/// controle do tipo — dimmer 0–100% (iluminação) ou termostato 16–30 °C
/// (ar-condicionado). Somente leitura sem permissão; desabilitado offline.
class DeviceDetailSheet extends ConsumerWidget {
  const DeviceDetailSheet({required this.device, super.key});

  final Device device;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final live = ref.watch(deviceLiveStateProvider);
    final current = live.apply(device);
    final canControl = ref.watch(
      hasPermissionProvider(AppPermission.controlDevices),
    );
    final busy = live.isPending(device.id);
    final enabled = canControl && current.online && !busy;
    final controller = ref.read(deviceControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  deviceIcon(current.type),
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(current.name, style: theme.textTheme.titleLarge),
                      Text(
                        current.locationLabel ?? current.type.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                StatusBadge(
                  current.status.label,
                  tone: deviceStatusTone(current.status),
                ),
                StatusBadge.availability(
                  current.online ? 'Online' : 'Offline',
                  online: current.online,
                ),
                if (current.powerWatts != null)
                  StatusBadge('${formatDecimal(current.powerWatts!, 0)} W'),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            if (!current.online)
              const AppBanner(
                tone: AppTone.neutral,
                icon: Icons.cloud_off,
                message: 'Dispositivo offline. Controle indisponível.',
              )
            else if (!canControl)
              const AppBanner(
                tone: AppTone.info,
                icon: Icons.visibility_outlined,
                message: 'Seu perfil é somente leitura.',
              ),
            if (canControl) ...[
              SwitchListTile(
                key: const Key('device-power'),
                contentPadding: EdgeInsets.zero,
                title: const Text('Ligado'),
                secondary: busy
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                value: current.isOn,
                onChanged: enabled
                    ? (on) => runDeviceCommand(
                        context,
                        controller.setPower(device, on: on),
                      )
                    : null,
              ),
              if (current.type == DeviceType.light)
                _DimmerControl(
                  device: device,
                  value: current.intensity ?? DeviceLimits.maxIntensity,
                  enabled: enabled,
                ),
              if (current.type == DeviceType.ac)
                _ThermostatControl(
                  device: device,
                  value: current.temperature ?? 24,
                  enabled: enabled,
                ),
            ] else ...[
              // Somente leitura: os valores aparecem, as ações não.
              const SizedBox(height: AppSpacing.md),
              if (current.type == DeviceType.light && current.intensity != null)
                _ReadOnlySetting(
                  label: 'Brilho',
                  value: '${current.intensity}%',
                ),
              if (current.type == DeviceType.ac && current.temperature != null)
                _ReadOnlySetting(
                  label: 'Temperatura',
                  value: '${formatDecimal(current.temperature!, 0)} °C',
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dimmer 0–100%: o comando sai ao soltar o slider, não a cada passo.
class _DimmerControl extends ConsumerStatefulWidget {
  const _DimmerControl({
    required this.device,
    required this.value,
    required this.enabled,
  });

  final Device device;
  final int value;
  final bool enabled;

  @override
  ConsumerState<_DimmerControl> createState() => _DimmerControlState();
}

class _DimmerControlState extends ConsumerState<_DimmerControl> {
  double? _dragging;

  @override
  Widget build(BuildContext context) {
    final shown = _dragging ?? widget.value.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Brilho: ${shown.round()}%',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Slider(
          key: const Key('device-dimmer'),
          value: shown,
          max: DeviceLimits.maxIntensity.toDouble(),
          divisions: DeviceLimits.maxIntensity,
          label: '${shown.round()}%',
          onChanged: widget.enabled
              ? (value) => setState(() => _dragging = value)
              : null,
          onChangeEnd: widget.enabled
              ? (value) {
                  setState(() => _dragging = null);
                  runDeviceCommand(
                    context,
                    ref
                        .read(deviceControllerProvider)
                        .setIntensity(
                          widget.device,
                          DeviceLimits.clampIntensity(value),
                        ),
                  );
                }
              : null,
        ),
      ],
    );
  }
}

/// Termostato 16–30 °C em passos de 1 °C; os botões somem nos limites.
class _ThermostatControl extends ConsumerWidget {
  const _ThermostatControl({
    required this.device,
    required this.value,
    required this.enabled,
  });

  final Device device;
  final double value;
  final bool enabled;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final current = DeviceLimits.clampTemperature(value);

    void set(double target) => runDeviceCommand(
      context,
      ref
          .read(deviceControllerProvider)
          .setTemperature(device, DeviceLimits.clampTemperature(target)),
    );

    return Row(
      children: [
        Expanded(child: Text('Temperatura', style: theme.textTheme.titleSmall)),
        IconButton.filledTonal(
          key: const Key('thermostat-down'),
          tooltip: 'Diminuir',
          onPressed: enabled && current > DeviceLimits.minTemperature
              ? () => set(current - DeviceLimits.temperatureStep)
              : null,
          icon: const Icon(Icons.remove),
        ),
        SizedBox(
          width: 72,
          child: Text(
            '${formatDecimal(current, 0)} °C',
            key: const Key('thermostat-value'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
        ),
        IconButton.filledTonal(
          key: const Key('thermostat-up'),
          tooltip: 'Aumentar',
          onPressed: enabled && current < DeviceLimits.maxTemperature
              ? () => set(current + DeviceLimits.temperatureStep)
              : null,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}

class _ReadOnlySetting extends StatelessWidget {
  const _ReadOnlySetting({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.titleSmall)),
          Text(value, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
