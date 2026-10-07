import 'package:autouni_app/core/router/app_tab.dart';
import 'package:autouni_app/core/router/router_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('appRouterProvider', () {
    test('expõe um único GoRouter por container', () {
      final container = ProviderContainer.test();

      final router = container.read(appRouterProvider);

      expect(router, isA<GoRouter>());
      expect(container.read(appRouterProvider), same(router));
    });

    test('começa na aba Início', () {
      final container = ProviderContainer.test();

      final router = container.read(appRouterProvider);

      expect(
        router.routeInformationProvider.value.uri.path,
        AppTab.dashboard.path,
      );
    });
  });
}
