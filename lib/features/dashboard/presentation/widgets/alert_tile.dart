import 'package:flutter/material.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/models/notification_type.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/dashboard_models.dart';

AppTone notificationTone(NotificationType type) => switch (type) {
  NotificationType.info => AppTone.info,
  NotificationType.warning => AppTone.warning,
  NotificationType.error => AppTone.danger,
  NotificationType.success => AppTone.success,
};

/// Linha de alerta recente: tipo, título, mensagem e horário. Não lidos em
/// negrito.
class AlertTile extends StatelessWidget {
  const AlertTile({required this.alert, super.key});

  final DashboardAlert alert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = notificationTone(alert.type);
    final createdAt = alert.createdAt;
    return ListTile(
      leading: Icon(_icon, color: tone.resolve(context)),
      title: Text(
        alert.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: alert.read ? null : const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        alert.message,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: createdAt == null
          ? null
          : Text(formatClock(createdAt), style: theme.textTheme.labelSmall),
    );
  }

  IconData get _icon => switch (alert.type) {
    NotificationType.info => Icons.info_outline,
    NotificationType.warning => Icons.warning_amber_rounded,
    NotificationType.error => Icons.error_outline,
    NotificationType.success => Icons.check_circle_outline,
  };
}
