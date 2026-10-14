import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/component_harness.dart';

void main() {
  testWidgets('mostra o rótulo', (tester) async {
    await pumpComponent(
      tester,
      const StatusBadge('Ativo', tone: AppTone.success),
    );
    expect(find.text('Ativo'), findsOneWidget);
  });

  testWidgets('mostra o ícone quando informado', (tester) async {
    await pumpComponent(
      tester,
      const StatusBadge('Alerta', tone: AppTone.warning, icon: Icons.warning),
    );
    expect(find.byIcon(Icons.warning), findsOneWidget);
  });

  testWidgets('availability: online usa o tom de sucesso e um ponto', (
    tester,
  ) async {
    await pumpComponent(
      tester,
      const StatusBadge.availability('Online', online: true),
    );
    expect(find.text('Online'), findsOneWidget);
    expect(find.byIcon(Icons.warning), findsNothing);
  });

  testWidgets('golden: todos os tons', (tester) async {
    await pumpComponent(
      tester,
      const Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          StatusBadge('Neutro'),
          StatusBadge('Sucesso', tone: AppTone.success, icon: Icons.check),
          StatusBadge('Aviso', tone: AppTone.warning, icon: Icons.warning),
          StatusBadge('Info', tone: AppTone.info, icon: Icons.info),
          StatusBadge('Erro', tone: AppTone.danger, icon: Icons.error),
          StatusBadge.availability('Online', online: true),
          StatusBadge.availability('Offline', online: false),
        ],
      ),
    );
    await expectLater(
      find.byType(Wrap),
      matchesGoldenFile('goldens/status_badge.png'),
    );
  });
}
