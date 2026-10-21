import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/app_config_provider.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:autouni_app/core/config/provider_retry.dart';
import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Como `pumpApp`, mas com um [GoRouter] de teste — para telas que navegam
/// (`context.push`/`go`). Rotas não declaradas viram uma tela com o caminho.
extension PumpRouterApp on WidgetTester {
  Future<(ProviderContainer, GoRouter)> pumpRouterApp({
    required String initialLocation,
    required List<RouteBase> routes,
    List<Override> overrides = const [],
  }) async {
    final container = ProviderContainer.test(
      retry: noAutomaticRetry,
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.forFlavor(Flavor.dev)),
        ...overrides,
      ],
    );
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: routes,
      errorBuilder: (context, state) =>
          Scaffold(body: Text('rota ${state.uri}')),
    );
    addTearDown(router.dispose);

    await pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await pump();
    return (container, router);
  }
}

/// Rota que só mostra um texto — destino de navegação em testes.
GoRoute stubRoute(String path) => GoRoute(
  path: path,
  builder: (context, state) => Scaffold(body: Text('stub $path')),
);
