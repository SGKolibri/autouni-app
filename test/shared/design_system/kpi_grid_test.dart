import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpGrid(
    WidgetTester tester, {
    required double width,
    double textScale = 1,
  }) async {
    tester.view.physicalSize = Size(width, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: MediaQuery(
          data: MediaQueryData(
            size: Size(width, 900),
            textScaler: TextScaler.linear(textScale),
          ),
          child: const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: KpiGrid(
                children: [
                  KpiCard(
                    label: 'Dispositivos ligados',
                    value: '234/977',
                    icon: Icons.power,
                  ),
                  KpiCard(
                    label: 'Online',
                    value: '1/977',
                    icon: Icons.wifi,
                    trend: KpiTrend(
                      label: '976 offline',
                      direction: KpiTrendDirection.down,
                    ),
                  ),
                  KpiCard(
                    label: 'Consumo hoje',
                    value: '1.250,0 kWh',
                    icon: Icons.bolt,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  // Um overflow de layout falharia o teste com "BOTTOM OVERFLOWED".
  for (final (width, scale) in [(360.0, 1.0), (320.0, 1.3), (412.0, 2.0)]) {
    testWidgets('sem overflow em ${width.toInt()} px com fonte x$scale', (
      tester,
    ) async {
      await pumpGrid(tester, width: width, textScale: scale);

      expect(tester.takeException(), isNull);
      expect(find.byType(KpiCard), findsNWidgets(3));
    });
  }

  testWidgets('cards da mesma linha ficam com a mesma altura', (tester) async {
    await pumpGrid(tester, width: 360);

    final ligados = tester.getSize(find.widgetWithText(KpiCard, '234/977'));
    final online = tester.getSize(find.widgetWithText(KpiCard, '1/977'));
    expect(ligados.height, online.height);
  });

  testWidgets('última linha incompleta mantém a largura das colunas', (
    tester,
  ) async {
    await pumpGrid(tester, width: 360);

    final first = tester.getSize(find.widgetWithText(KpiCard, '234/977'));
    final lonely = tester.getSize(find.widgetWithText(KpiCard, '1.250,0 kWh'));
    expect(lonely.width, first.width);
  });
}
