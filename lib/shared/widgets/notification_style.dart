import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../models/notification_type.dart';

/// Tom de cada tipo de notificação (cor do ícone e dos selos).
AppTone notificationTone(NotificationType type) => switch (type) {
  NotificationType.info => AppTone.info,
  NotificationType.warning => AppTone.warning,
  NotificationType.error => AppTone.danger,
  NotificationType.success => AppTone.success,
};

/// Ícone de cada tipo de notificação.
IconData notificationIcon(NotificationType type) => switch (type) {
  NotificationType.info => Icons.info_outline,
  NotificationType.warning => Icons.warning_amber_rounded,
  NotificationType.error => Icons.error_outline,
  NotificationType.success => Icons.check_circle_outline,
};
