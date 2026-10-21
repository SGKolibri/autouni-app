import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/utils/formatters.dart';

/// Gauge semicircular da potência: o valor atual sobre a escala até o pico
/// do período. Sem dados, mostra só a trilha e "—".
class PowerGauge extends StatelessWidget {
  const PowerGauge({required this.currentKw, required this.peakKw, super.key});

  final double? currentKw;
  final double? peakKw;

  static const double _size = 200;
  static const double _thickness = 22;

  /// Fração do arco preenchida (0–1).
  static double fraction(double? current, double? peak) {
    if (current == null || peak == null || peak <= 0) return 0;
    return (current / peak).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filled = fraction(currentKw, peakKw);
    final current = currentKw;
    final peak = peakKw;

    return Semantics(
      label: current == null
          ? 'Potência sem dados'
          : 'Potência ${formatKw(current)}'
                '${peak == null ? '' : ' de ${formatKw(peak)} de pico'}',
      excludeSemantics: true,
      child: SizedBox(
        width: _size,
        height: _size / 2 + AppSpacing.lg,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _size / 2,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: _size,
                  child: SizedBox.square(
                    dimension: _size,
                    child: PieChart(
                      PieChartData(
                        startDegreeOffset: 180,
                        sectionsSpace: 0,
                        centerSpaceRadius: _size / 2 - _thickness,
                        sections: [
                          if (filled > 0)
                            _section(theme.colorScheme.primary, filled),
                          if (filled < 1)
                            _section(
                              theme.colorScheme.surfaceContainerHighest,
                              1 - filled,
                            ),
                          // Metade de baixo, escondida pelo recorte.
                          _section(Colors.transparent, 1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  current == null ? '—' : formatKw(current),
                  key: const Key('gauge-value'),
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  peak == null ? 'sem leituras' : 'pico ${formatKw(peak)}',
                  key: const Key('gauge-peak'),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _section(Color color, double value) =>
      PieChartSectionData(
        value: value,
        color: color,
        radius: _thickness,
        showTitle: false,
      );
}
