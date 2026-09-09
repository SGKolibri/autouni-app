import 'package:autouni_app/app.dart';
import 'package:autouni_app/bootstrap.dart';
import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/app_config_provider.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget appWith(AppConfig config) => ProviderScope(
    overrides: [appConfigProvider.overrideWithValue(config)],
    child: const AutoUniApp(),
  );

  group('AutoUniApp', () {
    testWidgets('usa o nome do app definido pelo flavor', (tester) async {
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.dev)));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(app.title, 'AutoUni Dev');
    });

    testWidgets('mostra a faixa do flavor em dev', (tester) async {
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.dev)));

      expect(find.text('DEV'), findsOneWidget);
    });

    testWidgets('esconde a faixa do flavor em produção', (tester) async {
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.prod)));

      expect(find.text('DEV'), findsNothing);
      expect(find.text('PROD'), findsNothing);
    });

    testWidgets('renderiza o placeholder até o shell de navegação (S1-T5)', (
      tester,
    ) async {
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.prod)));

      expect(find.text('AutoUni'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
    });
  });

  group('buildAppRoot', () {
    testWidgets('injeta a config no ProviderScope raiz', (tester) async {
      final config = AppConfig.forFlavor(Flavor.prod);

      await tester.pumpWidget(buildAppRoot(config));

      final element = tester.element(find.byType(AutoUniApp));
      final container = ProviderScope.containerOf(element);
      expect(container.read(appConfigProvider), same(config));
    });
  });
}
