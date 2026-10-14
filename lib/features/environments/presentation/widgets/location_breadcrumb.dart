import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/design_system.dart';

/// Um nível do caminho. Sem [path], é o nível atual (não navegável).
class BreadcrumbItem {
  const BreadcrumbItem(this.label, {this.path});

  final String label;
  final String? path;
}

/// "Ambientes › Bloco A › 1º andar › Sala 101": o caminho completo até a
/// tela atual, com cada nível anterior tocável.
class LocationBreadcrumb extends StatelessWidget {
  const LocationBreadcrumb({required this.items, super.key});

  final List<BreadcrumbItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const Key('location-breadcrumb'),
      scrollDirection: Axis.horizontal,
      reverse: true,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0)
              Icon(
                Icons.chevron_right,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            _Crumb(item: items[i]),
          ],
        ],
      ),
    );
  }
}

class _Crumb extends StatelessWidget {
  const _Crumb({required this.item});

  final BreadcrumbItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final path = item.path;
    if (path == null) {
      return Text(
        item.label,
        style: theme.textTheme.labelLarge,
        semanticsLabel: 'Você está em ${item.label}',
      );
    }
    return InkWell(
      borderRadius: AppRadius.smAll,
      onTap: () => context.go(path),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.xxs,
        ),
        child: Text(
          item.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
