import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';

/// Bloco cinza no formato do conteúdo que ainda está carregando.
///
/// Estático de propósito: sem animação infinita, não trava `pumpAndSettle`
/// nem consome bateria em listas longas.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({
    this.width,
    this.height = 16,
    this.radius = AppRadius.sm,
    super.key,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Lista de linhas-esqueleto (ícone + duas linhas de texto), usada no
/// carregamento de listas.
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({this.itemCount = 6, super.key});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
        itemBuilder: (_, _) => const Row(
          children: [
            AppSkeleton(width: 40, height: 40, radius: AppRadius.pill),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSkeleton(height: 14),
                  SizedBox(height: AppSpacing.sm),
                  AppSkeleton(width: 120, height: 12),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado vazio: ícone, título, explicação e ação opcional.
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CenteredState(
      children: [
        Icon(icon, size: AppSpacing.xxxl, color: theme.colorScheme.outline),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        if (message != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ],
    );
  }
}

/// Estado de erro de carregamento, com "Tentar de novo".
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.message,
    this.title = 'Não foi possível carregar',
    this.onRetry,
    super.key,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _CenteredState(
      children: [
        Icon(
          Icons.cloud_off_outlined,
          size: AppSpacing.xxxl,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Tentar de novo'),
          ),
        ],
      ],
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
