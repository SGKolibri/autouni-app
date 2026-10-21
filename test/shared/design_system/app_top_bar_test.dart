import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/component_harness.dart';

void main() {
  testWidgets('mostra o título e as ações', (tester) async {
    await pumpComponent(
      tester,
      size: const Size(390, 160),
      padding: EdgeInsets.zero,
      scaffoldWith(
        appBar: const AppTopBar(
          title: 'Dashboard',
          actions: [Icon(Icons.search)],
        ),
      ),
    );
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byIcon(Icons.search), findsOneWidget);
  });

  testWidgets('preferredSize soma a altura do bottom', (tester) async {
    const bar = AppTopBar(
      title: 'x',
      bottom: TabBar(
        tabs: [
          Tab(text: 'a'),
          Tab(text: 'b'),
        ],
      ),
    );
    expect(bar.preferredSize.height, greaterThan(kToolbarHeight));
  });

  testWidgets('golden: com ponto de conexão (reconectando)', (tester) async {
    await pumpComponent(
      tester,
      size: const Size(390, 160),
      padding: EdgeInsets.zero,
      scaffoldWith(
        appBar: const AppTopBar(
          title: 'Sala 204',
          showConnectionDot: true,
          connected: false,
          actions: [Icon(Icons.more_vert)],
        ),
      ),
    );
    await expectLater(
      find.byType(AppBar),
      matchesGoldenFile('goldens/app_top_bar.png'),
    );
  });
}
