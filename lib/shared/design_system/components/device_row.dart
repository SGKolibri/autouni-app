import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';
import 'status_badge.dart';

/// Linha de dispositivo para listas (sala, lista global).
///
/// Estados cobertos: ligado/desligado e offline (controle indisponível). Sem
/// `onToggle` a linha vira somente-leitura (ex.: papel VIEWER).
class DeviceRow extends StatelessWidget {
  const DeviceRow({
    required this.name,
    required this.icon,
    this.subtitle,
    this.isOn = false,
    this.isOffline = false,
    this.onToggle,
    this.onTap,
    super.key,
  });

  final String name;
  final IconData icon;
  final String? subtitle;
  final bool isOn;
  final bool isOffline;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = isOn && !isOffline;

    final iconColor = isOffline
        ? scheme.onSurfaceVariant.withValues(alpha: 0.5)
        : active
        ? scheme.primary
        : scheme.onSurfaceVariant;

    return InkWell(
      onTap: isOffline ? null : onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: active
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null || isOffline) ...[
                    const SizedBox(height: 2),
                    if (isOffline)
                      const StatusBadge(
                        'Offline',
                        tone: AppTone.neutral,
                        dense: true,
                        icon: Icons.cloud_off,
                      )
                    else
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Switch(value: active, onChanged: isOffline ? null : onToggle),
          ],
        ),
      ),
    );
  }
}
