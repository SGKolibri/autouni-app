import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/rbac/app_permission.dart';
import '../../../../shared/rbac/permission_gate.dart';
import '../../domain/automation_models.dart';
import '../providers/automations_providers.dart';

/// Chave "ativa" de uma automação, com atualização otimista. Para quem não
/// pode gerenciar automações (VIEWER) vira só um selo de status.
class AutomationEnabledSwitch extends ConsumerWidget {
  const AutomationEnabledSwitch({required this.automation, super.key});

  final Automation automation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overrides = ref.watch(automationEnabledOverridesProvider);
    final enabled = overrides.enabledOf(automation);

    return PermissionGate(
      permission: AppPermission.manageAutomations,
      fallback: StatusBadge(
        enabled ? 'Ativa' : 'Pausada',
        key: ValueKey('automation-status-${automation.id}'),
        tone: enabled ? AppTone.success : AppTone.neutral,
        dense: true,
      ),
      child: Semantics(
        label: enabled ? 'Desativar automação' : 'Ativar automação',
        child: Switch(
          key: ValueKey('automation-switch-${automation.id}'),
          value: enabled,
          onChanged: overrides.isPending(automation.id)
              ? null
              : (value) async {
                  final messenger = ScaffoldMessenger.of(context);
                  final outcome = await ref
                      .read(automationsControllerProvider)
                      .setEnabled(automation, enabled: value);
                  final message = outcome.message;
                  if (!outcome.isSuccess && message != null) {
                    messenger
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(content: Text(message)));
                  }
                },
        ),
      ),
    );
  }
}
