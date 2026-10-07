import 'package:flutter/material.dart';

import '../tokens/app_palette.dart' show SemanticColorsX;
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Tom semântico de um [StatusBadge] / componente com severidade.
enum AppTone { neutral, success, warning, info, danger }

/// Pílula de status: usada para status de dispositivo, tipo de notificação
/// (INFO/WARNING/ERROR/SUCCESS) e disponibilidade online/offline.
class StatusBadge extends StatelessWidget {
  const StatusBadge(
    this.label, {
    this.tone = AppTone.neutral,
    this.icon,
    this.showDot = false,
    this.dense = false,
    super.key,
  });

  /// Ponto colorido + rótulo, sem preenchimento — para "Online"/"Offline".
  const StatusBadge.availability(this.label, {required bool online, super.key})
    : tone = online ? AppTone.success : AppTone.neutral,
      icon = null,
      showDot = true,
      dense = true;

  final String label;
  final AppTone tone;
  final IconData? icon;
  final bool showDot;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _colors(context);
    final textStyle =
        (dense
                ? Theme.of(context).textTheme.labelSmall
                : Theme.of(context).textTheme.labelMedium)
            ?.copyWith(color: fg, fontWeight: FontWeight.w600);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.sm : AppSpacing.md,
        vertical: dense ? AppSpacing.xxs : AppSpacing.xs,
      ),
      decoration: BoxDecoration(color: bg, borderRadius: AppRadius.pillAll),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showDot) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppSpacing.xs),
          ] else if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(label, style: textStyle),
        ],
      ),
    );
  }

  (Color fg, Color bg) _colors(BuildContext context) {
    final semantic = context.semanticColors;
    final scheme = Theme.of(context).colorScheme;
    return switch (tone) {
      AppTone.neutral => (
        scheme.onSurfaceVariant,
        scheme.surfaceContainerHighest,
      ),
      AppTone.success => (semantic.success, semantic.successSurface),
      AppTone.warning => (semantic.warning, semantic.warningSurface),
      AppTone.info => (semantic.info, semantic.infoSurface),
      AppTone.danger => (semantic.danger, semantic.dangerSurface),
    };
  }
}

/// Cor de destaque de um [AppTone] (para ícones, textos e realces).
extension AppToneColor on AppTone {
  Color resolve(BuildContext context) {
    final semantic = context.semanticColors;
    return switch (this) {
      AppTone.neutral => Theme.of(context).colorScheme.onSurfaceVariant,
      AppTone.success => semantic.success,
      AppTone.warning => semantic.warning,
      AppTone.info => semantic.info,
      AppTone.danger => semantic.danger,
    };
  }
}
