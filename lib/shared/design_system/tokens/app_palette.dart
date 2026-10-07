import 'package:flutter/material.dart';

/// Cores cruas do AutoUni. Fora do design system, consuma sempre via
/// `Theme.of(context).colorScheme` ou [SemanticColors]; estas constantes só
/// existem para montar os temas.
abstract final class AppPalette {
  // Marca — azul institucional.
  static const Color brand = Color(0xFF1E5AA8);
  static const Color brandDark = Color(0xFF16437D);
  static const Color brandLight = Color(0xFF4C86D6);

  // Neutros.
  static const Color ink = Color(0xFF161A1F);
  static const Color slate = Color(0xFF5B6672);
  static const Color mist = Color(0xFFE4E8EC);
  static const Color cloud = Color(0xFFF4F6F8);
  static const Color white = Color(0xFFFFFFFF);

  // Status.
  static const Color success = Color(0xFF1F9D57);
  static const Color warning = Color(0xFFC8860B);
  static const Color info = Color(0xFF2A6DB0);
  static const Color danger = Color(0xFFD1382C);

  static const Color successSurfaceLight = Color(0xFFE1F4E9);
  static const Color warningSurfaceLight = Color(0xFFFBEFD6);
  static const Color infoSurfaceLight = Color(0xFFE1ECF7);
  static const Color dangerSurfaceLight = Color(0xFFFBE4E2);

  static const Color successSurfaceDark = Color(0xFF12321F);
  static const Color warningSurfaceDark = Color(0xFF3A2C0C);
  static const Color infoSurfaceDark = Color(0xFF122A40);
  static const Color dangerSurfaceDark = Color(0xFF3B1512);
}

/// Cores semânticas que não cabem no [ColorScheme] do Material: status de
/// dispositivo/notificação e disponibilidade online/offline.
@immutable
class SemanticColors extends ThemeExtension<SemanticColors> {
  const SemanticColors({
    required this.success,
    required this.onSuccess,
    required this.successSurface,
    required this.warning,
    required this.onWarning,
    required this.warningSurface,
    required this.info,
    required this.onInfo,
    required this.infoSurface,
    required this.danger,
    required this.onDanger,
    required this.dangerSurface,
    required this.online,
    required this.offline,
  });

  final Color success;
  final Color onSuccess;
  final Color successSurface;
  final Color warning;
  final Color onWarning;
  final Color warningSurface;
  final Color info;
  final Color onInfo;
  final Color infoSurface;
  final Color danger;
  final Color onDanger;
  final Color dangerSurface;
  final Color online;
  final Color offline;

  static const SemanticColors light = SemanticColors(
    success: AppPalette.success,
    onSuccess: AppPalette.white,
    successSurface: AppPalette.successSurfaceLight,
    warning: AppPalette.warning,
    onWarning: AppPalette.white,
    warningSurface: AppPalette.warningSurfaceLight,
    info: AppPalette.info,
    onInfo: AppPalette.white,
    infoSurface: AppPalette.infoSurfaceLight,
    danger: AppPalette.danger,
    onDanger: AppPalette.white,
    dangerSurface: AppPalette.dangerSurfaceLight,
    online: AppPalette.success,
    offline: AppPalette.slate,
  );

  static const SemanticColors dark = SemanticColors(
    success: Color(0xFF54C98A),
    onSuccess: Color(0xFF04210F),
    successSurface: AppPalette.successSurfaceDark,
    warning: Color(0xFFE6B25A),
    onWarning: Color(0xFF241A03),
    warningSurface: AppPalette.warningSurfaceDark,
    info: Color(0xFF6BA6DD),
    onInfo: Color(0xFF04182B),
    infoSurface: AppPalette.infoSurfaceDark,
    danger: Color(0xFFEC7168),
    onDanger: Color(0xFF2A0906),
    dangerSurface: AppPalette.dangerSurfaceDark,
    online: Color(0xFF54C98A),
    offline: Color(0xFF8A94A0),
  );

  @override
  SemanticColors copyWith({
    Color? success,
    Color? onSuccess,
    Color? successSurface,
    Color? warning,
    Color? onWarning,
    Color? warningSurface,
    Color? info,
    Color? onInfo,
    Color? infoSurface,
    Color? danger,
    Color? onDanger,
    Color? dangerSurface,
    Color? online,
    Color? offline,
  }) {
    return SemanticColors(
      success: success ?? this.success,
      onSuccess: onSuccess ?? this.onSuccess,
      successSurface: successSurface ?? this.successSurface,
      warning: warning ?? this.warning,
      onWarning: onWarning ?? this.onWarning,
      warningSurface: warningSurface ?? this.warningSurface,
      info: info ?? this.info,
      onInfo: onInfo ?? this.onInfo,
      infoSurface: infoSurface ?? this.infoSurface,
      danger: danger ?? this.danger,
      onDanger: onDanger ?? this.onDanger,
      dangerSurface: dangerSurface ?? this.dangerSurface,
      online: online ?? this.online,
      offline: offline ?? this.offline,
    );
  }

  @override
  SemanticColors lerp(ThemeExtension<SemanticColors>? other, double t) {
    if (other is! SemanticColors) return this;
    return SemanticColors(
      success: Color.lerp(success, other.success, t)!,
      onSuccess: Color.lerp(onSuccess, other.onSuccess, t)!,
      successSurface: Color.lerp(successSurface, other.successSurface, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      onWarning: Color.lerp(onWarning, other.onWarning, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      info: Color.lerp(info, other.info, t)!,
      onInfo: Color.lerp(onInfo, other.onInfo, t)!,
      infoSurface: Color.lerp(infoSurface, other.infoSurface, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      onDanger: Color.lerp(onDanger, other.onDanger, t)!,
      dangerSurface: Color.lerp(dangerSurface, other.dangerSurface, t)!,
      online: Color.lerp(online, other.online, t)!,
      offline: Color.lerp(offline, other.offline, t)!,
    );
  }

  List<Object> get _fields => [
    success,
    onSuccess,
    successSurface,
    warning,
    onWarning,
    warningSurface,
    info,
    onInfo,
    infoSurface,
    danger,
    onDanger,
    dangerSurface,
    online,
    offline,
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! SemanticColors) return false;
    final mine = _fields;
    final theirs = other._fields;
    for (var i = 0; i < mine.length; i++) {
      if (mine[i] != theirs[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_fields);
}

/// Açúcar sintático: `context.semanticColors`.
extension SemanticColorsX on BuildContext {
  SemanticColors get semanticColors =>
      Theme.of(this).extension<SemanticColors>() ?? SemanticColors.light;
}
