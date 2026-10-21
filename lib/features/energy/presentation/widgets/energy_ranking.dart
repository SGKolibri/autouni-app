import 'package:flutter/material.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/energy_models.dart';

/// Ranking de consumo: cada linha com a barra proporcional ao maior
/// consumidor e a fatia do total. Tocar abre o consumo da entidade.
class EnergyRanking extends StatelessWidget {
  const EnergyRanking({required this.items, this.onTap, super.key});

  /// Já ordenados do maior para o menor.
  final List<EnergyRankingItem> items;
  final ValueChanged<EnergyRankingItem>? onTap;

  /// Fatia de [item] no total do ranking, em % inteiro.
  static int shareOf(EnergyRankingItem item, List<EnergyRankingItem> items) {
    final total = items.fold<double>(0, (sum, i) => sum + i.totalKwh);
    if (total <= 0) return 0;
    return (item.totalKwh / total * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          'Nada para comparar neste nível.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }
    final top = items.first.totalKwh;

    return Column(
      children: [
        for (final (index, item) in items.indexed)
          InkWell(
            key: ValueKey('ranking-${item.id}'),
            onTap: onTap == null ? null : () => onTap!(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              '${formatKwh(item.totalKwh)} · '
                              '${shareOf(item, items)}%',
                              style: theme.textTheme.labelMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ClipRRect(
                          borderRadius: AppRadius.pillAll,
                          child: LinearProgressIndicator(
                            value: top <= 0 ? 0 : item.totalKwh / top,
                            minHeight: 6,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onTap != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
