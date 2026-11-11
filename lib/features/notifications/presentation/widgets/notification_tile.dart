import 'package:flutter/material.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/notification_style.dart';
import '../../domain/app_notification.dart';

/// Linha da central: ícone do tipo, título (negrito e ponto se não lida),
/// mensagem, horário e seta quando abre uma tela.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.notification,
    this.onTap,
    this.opening = false,
    super.key,
  });

  final AppNotification notification;
  final VoidCallback? onTap;

  /// Resolvendo o link (mostra progresso no lugar da seta).
  final bool opening;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tone = notificationTone(notification.type).resolve(context);
    final unread = !notification.read;
    final createdAt = notification.createdAt;

    return Semantics(
      label: unread ? 'Não lida' : null,
      child: InkWell(
        onTap: opening ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  notificationIcon(notification.type),
                  size: 20,
                  color: tone,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: unread
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (createdAt != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            formatClock(createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (notification.message.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xxs),
                        child: Text(
                          notification.message,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 20,
                child: Column(
                  children: [
                    if (unread)
                      Container(
                        key: ValueKey('unread-dot-${notification.id}'),
                        margin: const EdgeInsets.only(top: AppSpacing.xs),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    if (opening)
                      const Padding(
                        padding: EdgeInsets.only(top: AppSpacing.sm),
                        child: SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    else if (notification.hasLink)
                      Icon(
                        Icons.chevron_right,
                        size: 20,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
