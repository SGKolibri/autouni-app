import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/models/campus/campus_enums.dart';

/// Cor de cada status no donut e na legenda.
Color statusColor(BuildContext context, DeviceStatus status) {
  final semantic = context.semanticColors;
  return switch (status) {
    DeviceStatus.on => semantic.success,
    DeviceStatus.off => Theme.of(context).colorScheme.outline,
    DeviceStatus.standby => semantic.warning,
    DeviceStatus.error => semantic.danger,
  };
}

/// Donut da distribuição de status dos dispositivos, com o total no centro
/// e a legenda ao lado.
class StatusDonut extends StatelessWidget {
  const StatusDonut({required this.byStatus, super.key});

  final Map<DeviceStatus, int> byStatus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = byStatus.values.fold<int>(0, (sum, count) => sum + count);

    return Row(
      children: [
        SizedBox.square(
          dimension: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (total > 0)
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 42,
                    startDegreeOffset: -90,
                    sections: [
                      for (final status in DeviceStatus.values)
                        if ((byStatus[status] ?? 0) > 0)
                          PieChartSectionData(
                            value: byStatus[status]!.toDouble(),
                            color: statusColor(context, status),
                            radius: 18,
                            showTitle: false,
                          ),
                    ],
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.surfaceContainerHighest,
                      width: 18,
                    ),
                  ),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    key: const Key('donut-total'),
                    style: theme.textTheme.titleLarge,
                  ),
                  Text('total', style: theme.textTheme.labelSmall),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final status in DeviceStatus.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: statusColor(context, status),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(child: Text(status.label)),
                      Text(
                        '${byStatus[status] ?? 0}',
                        key: ValueKey('donut-${status.name}'),
                        style: theme.textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
