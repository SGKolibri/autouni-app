import 'package:flutter/material.dart';

/// Tipografia do design system.
///
/// Usa a família padrão da plataforma por enquanto; se o handoff definir uma
/// fonte de marca, basta trocar [fontFamily] e registrar o asset no pubspec.
abstract final class AppTypography {
  static const String? fontFamily = null;

  /// [TextTheme] base, derivado do Material 3 com pesos um pouco mais firmes
  /// para títulos.
  static TextTheme textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? Typography.material2021().white
        : Typography.material2021().black;

    return base
        .copyWith(
          headlineSmall: base.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        )
        .apply(fontFamily: fontFamily);
  }
}
