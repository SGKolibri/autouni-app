import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../shared/design_system/design_system.dart';
import 'app_tab.dart';

/// Tela provisória de uma aba, substituída pela página real de cada feature
/// nas próximas sprints.
class TabPlaceholderPage extends StatelessWidget {
  TabPlaceholderPage({required this.tab}) : super(key: keyFor(tab));

  final AppTab tab;

  static Key keyFor(AppTab tab) => ValueKey('tab-page-${tab.name}');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppTopBar(title: tab.label),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              tab.icon,
              size: AppSpacing.xxxl,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Em construção', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

/// Destino de qualquer rota desconhecida (inclusive deep links inválidos).
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const AppTopBar(title: 'AutoUni'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Página não encontrada', style: theme.textTheme.titleMedium),
              const SizedBox(height: AppSpacing.lg),
              FilledButton(
                onPressed: () => context.go(AppTab.dashboard.path),
                child: const Text('Voltar ao início'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
