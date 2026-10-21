import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_paths.dart';
import '../../../../core/router/app_tab.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/rbac/app_permission.dart';
import '../../../../shared/rbac/permission_gate.dart';
import '../../../../shared/utils/error_messages.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/cached_async_view.dart';
import '../../domain/automation_models.dart';
import '../providers/automations_providers.dart';
import '../widgets/automation_enabled_switch.dart';
import '../widgets/automation_tile.dart';

/// Detalhe de uma automação: o que faz e quando, ações (executar, editar,
/// excluir) e o histórico de execuções.
class AutomationDetailPage extends ConsumerWidget {
  const AutomationDetailPage({required this.automationId, super.key});

  final String automationId;

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Key confirmKey,
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            key: confirmKey,
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  )
                : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<void> _execute(
    BuildContext context,
    WidgetRef ref,
    Automation automation,
  ) async {
    final confirmed = await _confirm(
      context,
      title: 'Executar agora?',
      message: '${automation.action.describe()} agora, fora do horário.',
      confirmLabel: 'Executar',
      confirmKey: const Key('confirm-execute'),
    );
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final outcome = await ref
        .read(automationsControllerProvider)
        .execute(automation);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            outcome.isSuccess
                ? 'Automação executada.'
                : outcome.message ?? 'Não foi possível executar.',
          ),
        ),
      );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Automation automation,
  ) async {
    final confirmed = await _confirm(
      context,
      title: 'Excluir automação?',
      message:
          '"${automation.name}" e o histórico de execuções serão apagados. '
          'Esta ação não pode ser desfeita.',
      confirmLabel: 'Excluir',
      confirmKey: const Key('confirm-delete'),
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final outcome = await ref
        .read(automationsControllerProvider)
        .delete(automation);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            outcome.isSuccess
                ? 'Automação excluída.'
                : outcome.message ?? 'Não foi possível excluir.',
          ),
        ),
      );
    if (outcome.isSuccess) {
      router.canPop() ? router.pop() : router.go(AppTab.automations.path);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(automationProvider(automationId));
    final automation = value.value?.data;

    return Scaffold(
      appBar: AppTopBar(
        title: automation?.name ?? 'Automação',
        actions: [
          if (automation != null)
            PermissionGate(
              permission: AppPermission.manageAutomations,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('automation-edit'),
                    tooltip: 'Editar',
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        context.push(AppPaths.editAutomation(automationId)),
                  ),
                  IconButton(
                    key: const Key('automation-delete'),
                    tooltip: 'Excluir',
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(context, ref, automation),
                  ),
                ],
              ),
            ),
        ],
      ),
      body: CachedAsyncView<Automation>(
        value: value,
        onRetry: () => ref.invalidate(automationProvider(automationId)),
        builder: (context, automation) => RefreshIndicator(
          onRefresh: () {
            ref.invalidate(automationHistoryProvider(automationId));
            return ref.refresh(automationProvider(automationId).future);
          },
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              _SummaryCard(automation: automation),
              const SizedBox(height: AppSpacing.md),
              PermissionGate(
                permission: AppPermission.manageAutomations,
                child: Consumer(
                  builder: (context, ref, _) {
                    final enabled = ref
                        .watch(automationEnabledOverridesProvider)
                        .enabledOf(automation);
                    return FilledButton.icon(
                      key: const Key('automation-execute'),
                      onPressed: enabled
                          ? () => _execute(context, ref, automation)
                          : null,
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        enabled
                            ? 'Executar agora'
                            : 'Ative para executar agora',
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Histórico de execuções',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              _History(automationId: automationId),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.automation});

  final Automation automation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final description = automation.description?.trim();
    final lastRun = automation.lastRunAt;

    Widget row(IconData icon, String label, String value, {Key? key}) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: theme.textTheme.labelSmall),
                    Text(value, key: key, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Automação ativa',
                    style: theme.textTheme.titleSmall,
                  ),
                ),
                AutomationEnabledSwitch(automation: automation),
              ],
            ),
            if (description != null && description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(description, style: theme.textTheme.bodyMedium),
            ],
            const Divider(height: AppSpacing.xl),
            row(
              triggerIcon(automation.triggerType),
              'Quando',
              automation.triggerSummary,
              key: const Key('automation-trigger'),
            ),
            row(
              Icons.power_settings_new,
              'O que faz',
              automation.action.describe(),
              key: const Key('automation-action'),
            ),
            row(
              Icons.history,
              'Última execução',
              lastRun == null ? 'Nunca executada' : formatDateTime(lastRun),
            ),
            if (automation.creatorName != null)
              row(Icons.person_outline, 'Criada por', automation.creatorName!),
          ],
        ),
      ),
    );
  }
}

class _History extends ConsumerWidget {
  const _History({required this.automationId});

  final String automationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final history = ref.watch(automationHistoryProvider(automationId));
    final runs = history.value?.data;

    if (runs == null) {
      if (history.hasError) {
        return AppBanner(
          tone: AppTone.danger,
          message: describeError(history.error),
          action: AppBannerAction(
            label: 'Tentar de novo',
            onPressed: () =>
                ref.invalidate(automationHistoryProvider(automationId)),
          ),
        );
      }
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (runs.isEmpty) {
      return Text(
        'Nenhuma execução ainda.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Card(
      child: Column(
        children: [
          for (final run in runs)
            ListTile(
              key: ValueKey('run-${run.id}'),
              leading: Icon(
                run.success ? Icons.check_circle : Icons.error,
                color: (run.success ? AppTone.success : AppTone.danger).resolve(
                  context,
                ),
              ),
              title: Text(run.success ? 'Sucesso' : 'Falhou'),
              subtitle: Text(
                [
                  formatDateTime(run.runAt),
                  if (!run.success && (run.logs?.isNotEmpty ?? false))
                    run.logs!,
                ].join('\n'),
              ),
              isThreeLine: !run.success && (run.logs?.isNotEmpty ?? false),
            ),
        ],
      ),
    );
  }
}
