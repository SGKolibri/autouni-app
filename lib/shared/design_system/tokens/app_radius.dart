import 'package:flutter/widgets.dart';

/// Raios de canto do design system.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;

  /// Cards e superfícies.
  static const double lg = 16;

  /// Bottom sheets e diálogos.
  static const double xl = 24;

  /// Pílulas / badges.
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius pillAll = BorderRadius.all(Radius.circular(pill));
}
