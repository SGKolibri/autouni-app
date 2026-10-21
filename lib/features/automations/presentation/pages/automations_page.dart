import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_paths.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/rbac/app_permission.dart';
import '../../../../shared/rbac/permission_gate.dart';
import '../../../../shared/rbac/rbac_providers.dart';
import '../../../../shared/widgets/cached_async_view.dart';
import '../../domain/automation_models.dart';
import '../providers/automations_providers.dart';
import '../widgets/automation_tile.dart';

/// Aba Automações: lista com a chave "ativa" de cada uma e o botão de nova
/// automação (só para quem pode gerenciar).
class AutomationsPage extends ConsumerWidget {
  const AutomationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final automations = ref.watch(automationsProvider);
    final canManage = ref.watch(
      hasPermissionProvider(AppPermission.manageAutomations),
    );

    return Scaffold(
      appBar: const AppTopBar(title: 'Automações'),
      floatingActionButton: PermissionGate(
        permission: AppPermission.manageAutomations,
        child: FloatingActionButton.extended(
          key: const Key('automation-new'),
          onPressed: () => context.push(AppPaths.newAutomation),
          icon: const Icon(Icons.add),
          label: const Text('Nova'),
        ),
      ),
      body: CachedAsyncView<List<Automation>>(
        value: automations,
        onRetry: () => ref.invalidate(automationsProvider),
        isEmpty: (list) => list.isEmpty,
        empty: AppEmptyState(
          icon: Icons.bolt_outlined,
          title: 'Nenhuma automação',
          message: canManage
              ? 'Crie rotinas para ligar e desligar dispositivos sozinhas.'
              : 'Ainda não há rotinas cadastradas.',
          actionLabel: canManage ? 'Criar automação' : null,
          onAction: canManage
              ? () => context.push(AppPaths.newAutomation)
              : null,
        ),
        builder: (context, list) => RefreshIndicator(
          onRefresh: () => ref.refresh(automationsProvider.future),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              // espaço para o FAB não cobrir a última linha
              96,
            ),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final automation = list[index];
              return AutomationTile(
                automation: automation,
                onTap: () => context.push(AppPaths.automation(automation.id)),
              );
            },
          ),
        ),
      ),
    );
  }
}
