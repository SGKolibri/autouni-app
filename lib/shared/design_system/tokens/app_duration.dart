/// Durações de animação padronizadas.
abstract final class AppDuration {
  /// Feedback imediato (ripple, toggle otimista).
  static const Duration fast = Duration(milliseconds: 120);

  /// Transições de componente (expand/collapse, banner).
  static const Duration medium = Duration(milliseconds: 240);

  /// Transições de tela.
  static const Duration slow = Duration(milliseconds: 360);
}
