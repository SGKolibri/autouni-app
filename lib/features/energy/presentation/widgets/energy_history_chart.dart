import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/energy_models.dart';

/// Linha do consumo por hora (hoje) ou por dia (semana/mês).
class EnergyHistoryChart extends StatelessWidget {
  const EnergyHistoryChart({
    required this.points,
    required this.period,
    super.key,
  });

  final List<EnergyHistoryPoint> points;
  final EnergyPeriod period;

  /// Quantos rótulos no eixo X, no máximo.
  static const int maxLabels = 6;

  /// Rótulo do eixo X para o ponto: hora em "hoje", dia/mês nos outros.
  static String labelFor(EnergyPeriod period, DateTime bucket) =>
      period == EnergyPeriod.today
      ? formatHour(bucket)
      : formatDayMonth(bucket);

  /// Intervalo entre rótulos para caber no máximo [maxLabels].
  static int labelStep(int count) =>
      count <= maxLabels ? 1 : (count / maxLabels).ceil();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (points.isEmpty) {
      return SizedBox(
        height: 180,
        child: Center(
          child: Text(
            'Sem leituras no período.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final color = theme.colorScheme.primary;
    final maxY = points.map((p) => p.totalKwh).reduce(math.max);
    final top = maxY <= 0 ? 1.0 : maxY * 1.15;
    final step = labelStep(points.length);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Semantics(
      label:
          'Gráfico de consumo: ${points.length} pontos, '
          'máximo ${formatKwh(maxY)}',
      excludeSemantics: true,
      child: SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: top,
            lineTouchData: const LineTouchData(enabled: false),
            gridData: FlGridData(
              drawVerticalLine: false,
              horizontalInterval: top / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                color: theme.colorScheme.outlineVariant,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 48,
                  interval: top / 4,
                  getTitlesWidget: (value, meta) => SideTitleWidget(
                    meta: meta,
                    child: Text(
                      formatDecimal(value, value < 10 ? 1 : 0),
                      maxLines: 1,
                      softWrap: false,
                      style: labelStyle,
                    ),
                  ),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  reservedSize: 24,
                  getTitlesWidget: (value, meta) {
                    final index = value.round();
                    if (index != value ||
                        index < 0 ||
                        index >= points.length ||
                        index % step != 0) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        labelFor(period, points[index].bucket),
                        style: labelStyle,
                      ),
                    );
                  },
                ),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < points.length; i++)
                    FlSpot(i.toDouble(), points[i].totalKwh),
                ],
                isCurved: true,
                preventCurveOverShooting: true,
                color: color,
                barWidth: 3,
                dotData: FlDotData(show: points.length == 1),
                belowBarData: BarAreaData(
                  show: true,
                  color: color.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
          duration: AppDuration.medium,
        ),
      ),
    );
  }
}
