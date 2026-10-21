import 'package:flutter/material.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/utils/formatters.dart';
import '../../domain/automation_models.dart';
import 'automation_enabled_switch.dart';

/// Ícone de cada tipo de gatilho.
IconData triggerIcon(TriggerType type) => switch (type) {
  TriggerType.schedule => Icons.schedule,
  TriggerType.manual => Icons.touch_app_outlined,
  TriggerType.condition => Icons.rule,
};

/// Linha da lista de automações: nome, quando roda, o que faz e a chave
/// "ativa".
class AutomationTile extends StatelessWidget {
  const AutomationTile({required this.automation, this.onTap, super.key});

  final Automation automation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lastRun = automation.lastRunAt;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('automation-${automation.id}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: AppRadius.smAll,
                ),
                child: Icon(
                  triggerIcon(automation.triggerType),
                  size: 20,
                  color: theme.colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      automation.name,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      automation.triggerSummary,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      automation.action.describe(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lastRun != null)
                      Text(
                        'Última execução: ${formatClock(lastRun)}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AutomationEnabledSwitch(automation: automation),
            ],
          ),
        ),
      ),
    );
  }
}
