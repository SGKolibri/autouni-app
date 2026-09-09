import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppTheme', () {
    test('light e dark expõem o brightness correto e Material 3', () {
      expect(AppTheme.light().brightness, Brightness.light);
      expect(AppTheme.dark().brightness, Brightness.dark);
      expect(AppTheme.light().useMaterial3, isTrue);
    });

    test('registra a extensão SemanticColors nos dois temas', () {
      expect(
        AppTheme.light().extension<SemanticColors>(),
        SemanticColors.light,
      );
      expect(AppTheme.dark().extension<SemanticColors>(), SemanticColors.dark);
    });

    test('deriva o ColorScheme da cor de marca', () {
      final expected = ColorScheme.fromSeed(seedColor: AppPalette.brand);
      expect(AppTheme.light().colorScheme.primary, expected.primary);
    });
  });

  group('SemanticColors', () {
    test('lerp em t=0 volta o próprio valor', () {
      final mixed = SemanticColors.light.lerp(SemanticColors.dark, 0);
      expect(mixed, SemanticColors.light);
    });

    test('copyWith troca só o campo pedido', () {
      final changed = SemanticColors.light.copyWith(
        danger: const Color(0xFF000000),
      );
      expect(changed.danger, const Color(0xFF000000));
      expect(changed.success, SemanticColors.light.success);
    });

    testWidgets('context.semanticColors resolve a extensão do tema', (
      tester,
    ) async {
      late SemanticColors resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark(),
          home: Builder(
            builder: (context) {
              resolved = context.semanticColors;
              return const SizedBox();
            },
          ),
        ),
      );
      expect(resolved, SemanticColors.dark);
    });
  });
}
