import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/app_config_provider.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

extension PumpApp on WidgetTester {
  /// Monta uma tela/widget de feature como no app real: `ProviderScope` com
  /// a [AppConfig] injetada (dev por padrão) + os [overrides] do teste,
  /// `MaterialApp` com o tema do design system e um `Scaffold`.
  ///
  /// Devolve o container para o teste inspecionar ou alterar estado.
  Future<ProviderContainer> pumpApp(
    Widget child, {
    List<Override> overrides = const [],
    AppConfig? config,
    Brightness brightness = Brightness.light,
  }) async {
    final container = ProviderContainer.test(
      overrides: [
        appConfigProvider.overrideWithValue(
          config ?? AppConfig.forFlavor(Flavor.dev),
        ),
        ...overrides,
      ],
    );

    await pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: brightness == Brightness.dark
              ? AppTheme.dark()
              : AppTheme.light(),
          home: Scaffold(body: child),
        ),
      ),
    );
    await pump();
    return container;
  }
}
