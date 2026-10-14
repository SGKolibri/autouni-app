import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/component_harness.dart';

void main() {
  testWidgets('reflete o estado ligado no switch', (tester) async {
    await pumpComponent(
      tester,
      const DeviceRow(name: 'Ar-condicionado', icon: Icons.ac_unit, isOn: true),
    );
    expect(tester.widget<Switch>(find.byType(Switch)).value, isTrue);
  });

  testWidgets('onToggle recebe o novo valor', (tester) async {
    bool? received;
    await pumpComponent(
      tester,
      DeviceRow(name: 'Luz', icon: Icons.light, onToggle: (v) => received = v),
    );
    await tester.tap(find.byType(Switch));
    expect(received, isTrue);
  });

  testWidgets('offline desabilita o controle e mostra o badge', (tester) async {
    var toggled = false;
    await pumpComponent(
      tester,
      DeviceRow(
        name: 'Projetor',
        icon: Icons.cast,
        isOffline: true,
        onToggle: (_) => toggled = true,
      ),
    );
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(find.text('Offline'), findsOneWidget);

    await tester.tap(find.byType(Switch), warnIfMissed: false);
    expect(toggled, isFalse);
  });

  testWidgets('sem onToggle o switch fica somente-leitura (VIEWER)', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const DeviceRow(name: 'Tomada', icon: Icons.power, isOn: true),
    );
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
  });

  testWidgets('golden: estados on / off / offline', (tester) async {
    await pumpComponent(
      tester,
      size: const Size(390, 320),
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DeviceRow(
            name: 'Ar-condicionado',
            icon: Icons.ac_unit,
            subtitle: 'Sala 204',
            isOn: true,
            onToggle: (_) {},
          ),
          const Divider(height: 1),
          DeviceRow(
            name: 'Luz do corredor',
            icon: Icons.light,
            subtitle: 'Bloco B',
            onToggle: (_) {},
          ),
          const Divider(height: 1),
          const DeviceRow(
            name: 'Projetor',
            icon: Icons.cast,
            subtitle: 'Auditório',
            isOffline: true,
          ),
        ],
      ),
    );
    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('goldens/device_row.png'),
    );
  });
}
