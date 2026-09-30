import 'package:autouni_app/core/router/app_router.dart';
import 'package:autouni_app/core/router/app_tab.dart';
import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Future<GoRouter> _pumpRouter(
  WidgetTester tester, {
  String? initialLocation,
}) async {
  final router = createAppRouter(initialLocation: initialLocation);
  addTearDown(router.dispose);

  await tester.pumpWidget(
    MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
  );
  await tester.pumpAndSettle();
  return router;
}

int _selectedIndex(WidgetTester tester) =>
    tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex;

Finder _tabPage(AppTab tab, {bool skipOffstage = true}) =>
    find.byKey(ValueKey('tab-page-${tab.name}'), skipOffstage: skipOffstage);

void main() {
  group('AppTab', () {
    test('define as 5 abas na ordem da bottom nav do handoff', () {
      expect(AppTab.values.map((t) => t.label), [
        'Início',
        'Ambientes',
        'Automações',
        'Alertas',
        'Ajustes',
      ]);
    });

    test('cada aba tem um caminho raiz único', () {
      final paths = AppTab.values.map((t) => t.path).toList();

      expect(paths.toSet(), hasLength(paths.length));
      expect(paths, everyElement(startsWith('/')));
    });
  });

  group('shell de navegação', () {
    testWidgets('abre na aba Início', (tester) async {
      final router = await _pumpRouter(tester);

      expect(router.state.uri.path, AppTab.dashboard.path);
      expect(_selectedIndex(tester), 0);
      expect(_tabPage(AppTab.dashboard), findsOneWidget);
    });

    testWidgets('a raiz "/" redireciona para a aba Início', (tester) async {
      final router = await _pumpRouter(tester, initialLocation: '/');

      expect(router.state.uri.path, AppTab.dashboard.path);
      expect(_tabPage(AppTab.dashboard), findsOneWidget);
    });

    testWidgets('renderiza a bottom nav do design system com 5 abas', (
      tester,
    ) async {
      await _pumpRouter(tester);

      expect(find.byType(AppBottomNav), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
    });

    for (final tab in AppTab.values) {
      testWidgets(
        'tocar em "${tab.label}" troca a tela, a rota e a aba ativa',
        (tester) async {
          final router = await _pumpRouter(tester);

          await tester.tap(
            find.descendant(
              of: find.byType(NavigationBar),
              matching: find.text(tab.label),
            ),
          );
          await tester.pumpAndSettle();

          expect(router.state.uri.path, tab.path);
          expect(_selectedIndex(tester), tab.index);
          expect(_tabPage(tab), findsOneWidget);
          expect(
            find.descendant(
              of: find.byType(AppTopBar),
              matching: find.text(tab.label),
            ),
            findsOneWidget,
          );
        },
      );
    }

    testWidgets('mantém a aba anterior viva (estado preservado)', (
      tester,
    ) async {
      await _pumpRouter(tester);

      await tester.tap(find.text(AppTab.environments.label));
      await tester.pumpAndSettle();

      expect(_tabPage(AppTab.dashboard), findsNothing);
      expect(_tabPage(AppTab.dashboard, skipOffstage: false), findsOneWidget);
    });

    testWidgets('deep link abre direto na aba correspondente', (tester) async {
      final router = await _pumpRouter(
        tester,
        initialLocation: AppTab.notifications.path,
      );

      expect(router.state.uri.path, AppTab.notifications.path);
      expect(_selectedIndex(tester), AppTab.notifications.index);
      expect(_tabPage(AppTab.notifications), findsOneWidget);
    });

    testWidgets('navegação programática via go() sincroniza a bottom nav', (
      tester,
    ) async {
      final router = await _pumpRouter(tester);

      router.go(AppTab.settings.path);
      await tester.pumpAndSettle();

      expect(_selectedIndex(tester), AppTab.settings.index);
      expect(_tabPage(AppTab.settings), findsOneWidget);
    });

    testWidgets('rota desconhecida mostra página de não encontrado', (
      tester,
    ) async {
      final router = await _pumpRouter(tester, initialLocation: '/nao-existe');

      expect(find.text('Página não encontrada'), findsOneWidget);
      expect(find.byType(AppBottomNav), findsNothing);

      await tester.tap(find.text('Voltar ao início'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, AppTab.dashboard.path);
      expect(_tabPage(AppTab.dashboard), findsOneWidget);
    });
  });
}
