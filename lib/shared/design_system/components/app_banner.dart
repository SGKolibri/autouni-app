import 'package:flutter/material.dart';

import '../tokens/app_palette.dart' show SemanticColorsX;
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'status_badge.dart';

/// Ação opcional de um [AppBanner] (ex.: "Tentar de novo").
class AppBannerAction {
  const AppBannerAction({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;
}

/// Faixa informativa inline para estados transversais: erro de carregamento,
/// offline, WebSocket desconectado, avisos.
class AppBanner extends StatelessWidget {
  const AppBanner({
    required this.message,
    this.tone = AppTone.info,
    this.title,
    this.icon,
    this.action,
    this.onDismiss,
    super.key,
  });

  /// Variante pronta para o banner de "tempo real indisponível" (S3-T6).
  AppBanner.wsDisconnected({VoidCallback? onRetry, Key? key})
    : this(
        key: key,
        message: 'Tempo real indisponível — tentando reconectar.',
        tone: AppTone.warning,
        icon: Icons.wifi_off,
        action: onRetry == null
            ? null
            : AppBannerAction(label: 'Tentar de novo', onPressed: onRetry),
      );

  final String message;
  final AppTone tone;
  final String? title;
  final IconData? icon;
  final AppBannerAction? action;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fg = tone.resolve(context);
    final bg = _surface(context);
    final resolvedIcon = icon ?? _defaultIcon;
    final resolvedAction = action;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: fg.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(resolvedIcon, size: 20, color: fg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: theme.textTheme.titleSmall?.copyWith(color: fg),
                  ),
                Text(
                  message,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (resolvedAction != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: TextButton(
                      onPressed: resolvedAction.onPressed,
                      style: TextButton.styleFrom(
                        foregroundColor: fg,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        minimumSize: const Size(0, 32),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(resolvedAction.label),
                    ),
                  ),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18),
              color: fg,
              visualDensity: VisualDensity.compact,
              tooltip: 'Dispensar',
            ),
        ],
      ),
    );
  }

  Color _surface(BuildContext context) {
    final semantic = context.semanticColors;
    return switch (tone) {
      AppTone.neutral => Theme.of(context).colorScheme.surfaceContainerHighest,
      AppTone.success => semantic.successSurface,
      AppTone.warning => semantic.warningSurface,
      AppTone.info => semantic.infoSurface,
      AppTone.danger => semantic.dangerSurface,
    };
  }

  IconData get _defaultIcon => switch (tone) {
    AppTone.neutral => Icons.info_outline,
    AppTone.success => Icons.check_circle_outline,
    AppTone.warning => Icons.warning_amber_rounded,
    AppTone.info => Icons.info_outline,
    AppTone.danger => Icons.error_outline,
  };
}
