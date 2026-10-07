import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/component_harness.dart';

void main() {
  testWidgets('mostra valor e rótulo', (tester) async {
    await pumpComponent(
      tester,
      const KpiCard(label: 'Dispositivos online', value: '842'),
    );
    expect(find.text('842'), findsOneWidget);
    expect(find.text('Dispositivos online'), findsOneWidget);
  });

  testWidgets('dispara onTap', (tester) async {
    var taps = 0;
    await pumpComponent(
      tester,
      KpiCard(label: 'x', value: '1', onTap: () => taps++),
    );
    await tester.tap(find.byType(KpiCard));
    expect(taps, 1);
  });

  testWidgets('trend up com positiveIsGood=false usa cor de perigo', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const KpiCard(
        label: 'Consumo',
        value: '48 kWh',
        icon: Icons.bolt,
        trend: KpiTrend(
          label: '+12%',
          direction: KpiTrendDirection.up,
          positiveIsGood: false,
        ),
      ),
    );
    final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_upward));
    expect(icon.color, SemanticColors.light.danger);
  });

  testWidgets('golden: com ícone e trend (light)', (tester) async {
    await pumpComponent(
      tester,
      const SizedBox(
        width: 180,
        child: KpiCard(
          label: 'Dispositivos online',
          value: '842',
          icon: Icons.sensors,
          trend: KpiTrend(label: '+3% hoje', direction: KpiTrendDirection.up),
        ),
      ),
    );
    await expectLater(
      find.byType(KpiCard),
      matchesGoldenFile('goldens/kpi_card_light.png'),
    );
  });

  testWidgets('golden: com ícone e trend (dark)', (tester) async {
    await pumpComponent(
      tester,
      brightness: Brightness.dark,
      const SizedBox(
        width: 180,
        child: KpiCard(
          label: 'Dispositivos online',
          value: '842',
          icon: Icons.sensors,
          trend: KpiTrend(label: '+3% hoje', direction: KpiTrendDirection.up),
        ),
      ),
    );
    await expectLater(
      find.byType(KpiCard),
      matchesGoldenFile('goldens/kpi_card_dark.png'),
    );
  });
}
