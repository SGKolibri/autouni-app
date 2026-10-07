import 'package:autouni_app/app.dart';
import 'package:autouni_app/bootstrap.dart';
import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/app_config_provider.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:autouni_app/core/router/app_tab.dart';
import 'package:autouni_app/shared/design_system/design_system.dart';
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

    testWidgets('abre no shell de navegação, na aba Início', (tester) async {
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.prod)));
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNav), findsOneWidget);
      expect(
        find.byKey(ValueKey('tab-page-${AppTab.dashboard.name}')),
        findsOneWidget,
      );
    });

    testWidgets('mantém a faixa do flavor por cima do shell em dev', (
      tester,
    ) async {
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.dev)));
      await tester.pumpAndSettle();

      expect(find.byType(AppBottomNav), findsOneWidget);
      expect(find.text('DEV'), findsOneWidget);
    });

    testWidgets('usa os temas claro e escuro do design system', (tester) async {
      await tester.pumpWidget(appWith(AppConfig.forFlavor(Flavor.prod)));

      final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(
        app.theme?.colorScheme.primary,
        AppTheme.light().colorScheme.primary,
      );
      expect(app.darkTheme?.brightness, Brightness.dark);
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
