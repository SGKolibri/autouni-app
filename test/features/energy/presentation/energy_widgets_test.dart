import 'package:autouni_app/features/energy/domain/energy_models.dart';
import 'package:autouni_app/features/energy/presentation/widgets/energy_history_chart.dart';
import 'package:autouni_app/features/energy/presentation/widgets/energy_ranking.dart';
import 'package:autouni_app/features/energy/presentation/widgets/power_gauge.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/component_harness.dart';

EnergyHistoryPoint _point(int day, int hour, double kwh) =>
    EnergyHistoryPoint(bucket: DateTime(2026, 10, day, hour), totalKwh: kwh);

void main() {
  group('PowerGauge', () {
    test('fração do arco: atual sobre o pico, limitada a 0–1', () {
      expect(PowerGauge.fraction(1, 4), 0.25);
      expect(PowerGauge.fraction(5, 4), 1);
      expect(PowerGauge.fraction(null, 4), 0);
      expect(PowerGauge.fraction(1, 0), 0);
      expect(PowerGauge.fraction(1, null), 0);
    });

    testWidgets('mostra a potência atual e o pico', (tester) async {
      await pumpComponent(
        tester,
        const PowerGauge(currentKw: 1.5, peakKw: 3.2),
      );

      expect(find.text('1,50 kW'), findsOneWidget);
      expect(find.text('pico 3,20 kW'), findsOneWidget);
      expect(find.byType(PieChart), findsOneWidget);
      expect(
        find.bySemanticsLabel('Potência 1,50 kW de 3,20 kW de pico'),
        findsOneWidget,
      );
    });

    testWidgets('sem dados mostra traço', (tester) async {
      await pumpComponent(
        tester,
        const PowerGauge(currentKw: null, peakKw: null),
      );

      expect(find.text('—'), findsOneWidget);
      expect(find.text('sem leituras'), findsOneWidget);
    });

    for (final brightness in Brightness.values) {
      testWidgets('golden (${brightness.name})', (tester) async {
        await pumpComponent(
          tester,
          const PowerGauge(currentKw: 2.1, peakKw: 3.4),
          brightness: brightness,
        );
        await expectLater(
          find.byType(PowerGauge),
          matchesGoldenFile('goldens/power_gauge_${brightness.name}.png'),
        );
      });
    }
  });

  group('EnergyHistoryChart', () {
    test('rótulo: hora em "hoje", dia/mês nos outros períodos', () {
      final bucket = DateTime(2026, 10, 21, 9);

      expect(EnergyHistoryChart.labelFor(EnergyPeriod.today, bucket), '09h');
      expect(EnergyHistoryChart.labelFor(EnergyPeriod.week, bucket), '21/10');
    });

    test('espaça os rótulos para caber no máximo 6', () {
      expect(EnergyHistoryChart.labelStep(6), 1);
      expect(EnergyHistoryChart.labelStep(7), 2);
      expect(EnergyHistoryChart.labelStep(24), 4);
      expect(EnergyHistoryChart.labelStep(31), 6);
    });

    testWidgets('desenha um ponto por bucket', (tester) async {
      await pumpComponent(
        tester,
        EnergyHistoryChart(
          points: [_point(21, 8, 1), _point(21, 9, 3), _point(21, 10, 2)],
          period: EnergyPeriod.today,
        ),
        size: const Size(390, 260),
      );

      final chart = tester.widget<LineChart>(find.byType(LineChart));
      expect(chart.data.lineBarsData.single.spots, const [
        FlSpot(0, 1),
        FlSpot(1, 3),
        FlSpot(2, 2),
      ]);
      expect(chart.data.minY, 0);
      expect(find.text('08h'), findsOneWidget);
    });

    testWidgets('sem pontos, mensagem em vez do gráfico', (tester) async {
      await pumpComponent(
        tester,
        const EnergyHistoryChart(points: [], period: EnergyPeriod.week),
      );

      expect(find.byType(LineChart), findsNothing);
      expect(find.text('Sem leituras no período.'), findsOneWidget);
    });

    testWidgets('golden: semana', (tester) async {
      await pumpComponent(
        tester,
        EnergyHistoryChart(
          points: [
            for (var day = 15; day <= 21; day++)
              _point(day, 0, 10 + (day % 3) * 4.5),
          ],
          period: EnergyPeriod.week,
        ),
        size: const Size(390, 260),
      );
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(EnergyHistoryChart),
        matchesGoldenFile('goldens/energy_history_chart.png'),
      );
    });
  });

  group('EnergyRanking', () {
    const items = [
      EnergyRankingItem(id: 'b2', name: 'Bloco B', totalKwh: 30),
      EnergyRankingItem(id: 'b1', name: 'Bloco A', totalKwh: 10),
    ];

    test('fatia de cada item no total', () {
      expect(EnergyRanking.shareOf(items[0], items), 75);
      expect(EnergyRanking.shareOf(items[1], items), 25);
      expect(
        EnergyRanking.shareOf(
          const EnergyRankingItem(id: 'x', name: 'x'),
          const [EnergyRankingItem(id: 'x', name: 'x')],
        ),
        0,
      );
    });

    testWidgets('barras proporcionais ao maior consumidor', (tester) async {
      await pumpComponent(tester, const EnergyRanking(items: items));

      final bars = tester
          .widgetList<LinearProgressIndicator>(
            find.byType(LinearProgressIndicator),
          )
          .map((bar) => bar.value);
      expect(bars, [1.0, closeTo(1 / 3, 1e-9)]);
      expect(find.text('30,0 kWh · 75%'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('tocar devolve o item', (tester) async {
      EnergyRankingItem? tapped;
      await pumpComponent(
        tester,
        EnergyRanking(items: items, onTap: (item) => tapped = item),
      );

      await tester.tap(find.byKey(const ValueKey('ranking-b1')));

      expect(tapped, items[1]);
    });

    testWidgets('vazio', (tester) async {
      await pumpComponent(tester, const EnergyRanking(items: []));

      expect(find.text('Nada para comparar neste nível.'), findsOneWidget);
    });
  });
}
