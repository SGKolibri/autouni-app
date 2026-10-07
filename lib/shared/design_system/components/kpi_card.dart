import 'package:flutter/material.dart';

import '../tokens/app_palette.dart' show SemanticColorsX;
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Direção da variação exibida no rodapé do [KpiCard].
enum KpiTrendDirection { up, down, flat }

/// Variação de um KPI (ex.: "+12% vs. ontem").
class KpiTrend {
  const KpiTrend({
    required this.label,
    this.direction = KpiTrendDirection.flat,
    this.positiveIsGood = true,
  });

  final String label;
  final KpiTrendDirection direction;

  /// Quando `false`, subir é ruim (ex.: consumo de energia) e a cor inverte.
  final bool positiveIsGood;
}

/// Card de indicador para o dashboard: rótulo, valor em destaque, ícone
/// opcional e variação opcional.
class KpiCard extends StatelessWidget {
  const KpiCard({
    required this.label,
    required this.value,
    this.icon,
    this.trend,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final IconData? icon;
  final KpiTrend? trend;
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: scheme.secondaryContainer,
                    borderRadius: AppRadius.smAll,
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: scheme.onSecondaryContainer,
                  ),
                ),
              if (icon != null) const SizedBox(height: AppSpacing.md),
              Text(
                value,
                style: theme.textTheme.headlineSmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (trend != null) ...[
                const SizedBox(height: AppSpacing.sm),
                _TrendRow(trend: trend!),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.trend});

  final KpiTrend trend;

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;
    final (icon, isPositive) = switch (trend.direction) {
      KpiTrendDirection.up => (Icons.arrow_upward, true),
      KpiTrendDirection.down => (Icons.arrow_downward, false),
      KpiTrendDirection.flat => (Icons.remove, true),
    };
    final good = trend.direction == KpiTrendDirection.flat
        ? null
        : isPositive == trend.positiveIsGood;
    final color = switch (good) {
      true => semantic.success,
      false => semantic.danger,
      null => Theme.of(context).colorScheme.onSurfaceVariant,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppSpacing.xxs),
        Flexible(
          child: Text(
            trend.label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
