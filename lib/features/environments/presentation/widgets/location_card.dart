import 'package:flutter/material.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/devices/device_counts.dart';
import '../../../../shared/utils/formatters.dart';

/// Card de um prédio, andar ou sala: nome, descrição, dispositivos ligados
/// (ao vivo), offline e consumo de hoje.
class LocationCard extends StatelessWidget {
  const LocationCard({
    required this.title,
    required this.icon,
    required this.counts,
    this.subtitle,
    this.todayEnergyKwh,
    this.onTap,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final DeviceCounts counts;
  final double? todayEnergyKwh;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: scheme.secondaryContainer,
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(icon, color: scheme.onSecondaryContainer),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      children: [
                        StatusBadge(
                          '${counts.on}/${counts.total} ligados',
                          tone: counts.on > 0
                              ? AppTone.success
                              : AppTone.neutral,
                          dense: true,
                        ),
                        if (counts.offline > 0)
                          StatusBadge(
                            '${counts.offline} offline',
                            tone: AppTone.warning,
                            dense: true,
                          ),
                        if (todayEnergyKwh != null)
                          StatusBadge(
                            '${formatKwh(todayEnergyKwh!)} hoje',
                            icon: Icons.bolt,
                            dense: true,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
