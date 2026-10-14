import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../models/campus/campus_enums.dart';
import '../models/campus/campus_models.dart';
import '../utils/formatters.dart';

/// Ícone de cada tipo de dispositivo.
IconData deviceIcon(DeviceType type) => switch (type) {
  DeviceType.light => Icons.lightbulb_outline,
  DeviceType.ac => Icons.ac_unit,
  DeviceType.projector => Icons.videocam_outlined,
  DeviceType.speaker => Icons.speaker_outlined,
  DeviceType.lock => Icons.lock_outline,
  DeviceType.sensor => Icons.sensors,
  DeviceType.other => Icons.power_outlined,
};

/// Tom do badge de status.
AppTone deviceStatusTone(DeviceStatus status) => switch (status) {
  DeviceStatus.on => AppTone.success,
  DeviceStatus.off => AppTone.neutral,
  DeviceStatus.standby => AppTone.warning,
  DeviceStatus.error => AppTone.danger,
};

/// Resumo de uma linha: status e o ajuste relevante ("Ligado · 70%").
String deviceSummary(Device device) {
  final setting = switch (device.type) {
    DeviceType.light when device.isOn && device.intensity != null =>
      '${device.intensity}%',
    DeviceType.ac when device.isOn && device.temperature != null =>
      '${formatDecimal(device.temperature!, 0)} °C',
    _ => null,
  };
  return [device.status.label, ?setting].join(' · ');
}
