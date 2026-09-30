import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/app_config_provider.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'pump_app.dart';

final _greetingProvider = Provider<String>((ref) => 'real');

class _Probe extends ConsumerWidget {
  const _Probe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return Text('${config.flavor.name}|${ref.watch(_greetingProvider)}');
  }
}

void main() {
  group('pumpApp', () {
    testWidgets('injeta uma AppConfig de dev por padrão', (tester) async {
      await tester.pumpApp(const _Probe());

      expect(find.text('dev|real'), findsOneWidget);
    });

    testWidgets('aceita uma AppConfig específica', (tester) async {
      await tester.pumpApp(
        const _Probe(),
        config: AppConfig.forFlavor(Flavor.prod),
      );

      expect(find.text('prod|real'), findsOneWidget);
    });

    testWidgets('aplica os overrides de providers do teste', (tester) async {
      await tester.pumpApp(
        const _Probe(),
        overrides: [_greetingProvider.overrideWithValue('fake')],
      );

      expect(find.text('dev|fake'), findsOneWidget);
    });

    testWidgets('envolve em MaterialApp + Scaffold com o tema do app', (
      tester,
    ) async {
      await tester.pumpApp(const _Probe(), brightness: Brightness.dark);

      expect(find.byType(Scaffold), findsOneWidget);
      final context = tester.element(find.byType(_Probe));
      expect(Theme.of(context).brightness, Brightness.dark);
    });

    testWidgets('devolve o container para inspecionar estado', (tester) async {
      final container = await tester.pumpApp(const _Probe());

      expect(container.read(_greetingProvider), 'real');
      expect(container.read(flavorProvider), Flavor.dev);
    });
  });
}
