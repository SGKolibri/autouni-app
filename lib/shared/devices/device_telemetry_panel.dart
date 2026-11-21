import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/design_system.dart';
import '../realtime/telemetry_events.dart';

String _fmt(double? v, int digits, String unit) =>
    v == null ? '—' : '${v.toStringAsFixed(digits)} $unit';

/// Tensão/corrente/potência, gás (com alarme) ou movimento de um device,
/// conforme o que chegar pelo WebSocket. Some se não houver telemetria.
class DeviceTelemetryPanel extends ConsumerWidget {
  const DeviceTelemetryPanel({required this.deviceId, super.key});

  final String deviceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(telemetryLiveProvider);
    final energy = t.energy[deviceId];
    final sensor = t.sensors[deviceId];
    final alarm = t.alarms[deviceId];
    if (energy == null && sensor == null && alarm == null) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);

    Widget metric(String label, String value) => Padding(
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: theme.textTheme.titleSmall),
        ],
      ),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (energy != null)
            Wrap(
              runSpacing: AppSpacing.sm,
              children: [
                metric('Tensão', _fmt(energy.voltage, 1, 'V')),
                metric('Corrente', _fmt(energy.current, 2, 'A')),
                metric('Potência', _fmt(energy.powerW, 0, 'W')),
              ],
            ),
          if (sensor != null && !sensor.isMotion)
            Row(
              children: [
                metric(
                  sensor.kind == 'GAS_MQ2' ? 'Gás (MQ-2)' : 'Ar (MQ-135)',
                  '${sensor.value.toStringAsFixed(0)} ${sensor.unit ?? ''}'
                      .trim(),
                ),
                Chip(
                  label: Text(
                    alarm == null
                        ? 'Normal'
                        : '${alarm.isCritical ? 'Alarme' : 'Aviso'} · '
                              'limite ${alarm.threshold.toStringAsFixed(0)}',
                  ),
                  backgroundColor: alarm == null
                      ? null
                      : alarm.isCritical
                      ? theme.colorScheme.errorContainer
                      : theme.colorScheme.tertiaryContainer,
                ),
              ],
            ),
          if (sensor != null && sensor.isMotion)
            metric(
              'Movimento',
              sensor.value > 0 ? 'Detectado' : 'Sem movimento',
            ),
        ],
      ),
    );
  }
}

/// Chip "Ocupada"/"Vazia" da sala, se já houve evento de presença.
class RoomOccupancyChip extends ConsumerWidget {
  const RoomOccupancyChip({required this.roomId, this.initial, super.key});

  final String roomId;

  /// Valor vindo da API (`Room.occupied`) até chegar um evento.
  final bool? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occupied =
        ref.watch(telemetryLiveProvider.select((t) => t.occupancy[roomId])) ??
        initial;
    if (occupied == null) return const SizedBox.shrink();
    return Chip(
      avatar: Icon(occupied ? Icons.directions_walk : Icons.person_off),
      label: Text(occupied ? 'Ocupada' : 'Vazia'),
    );
  }
}
