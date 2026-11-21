import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../shared/rbac/app_permission.dart';
import '../../../../shared/rbac/rbac_providers.dart';
import '../../data/alarm_settings_repository.dart';

/// Opções oferecidas no app. O web aceita qualquer valor de 0 a 1440; se a
/// organização usar um valor fora da lista, ele aparece como opção também.
const alarmReminderPresets = [0, 1, 5, 10, 15, 30, 60];

String describeAlarmReminder(int minutes) => switch (minutes) {
  0 => 'Desativado',
  1 => 'A cada 1 minuto',
  _ => 'A cada $minutes minutos',
};

/// Item dos Ajustes: intervalo do lembrete de alarme aberto. Quem não pode
/// alterar vê o valor atual, sem ação.
class AlarmReminderTile extends ConsumerWidget {
  const AlarmReminderTile({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref, int current) async {
    final options = {...alarmReminderPresets, current}.toList()..sort();
    final chosen = await showDialog<int>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Lembrete de alarme'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Repete o aviso enquanto o alarme estiver ativo e não for '
              'reconhecido. Vale para toda a organização.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          RadioGroup<int>(
            groupValue: current,
            onChanged: (value) => Navigator.of(context).pop(value),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final minutes in options)
                  RadioListTile<int>(
                    key: Key('alarm-reminder-option-$minutes'),
                    value: minutes,
                    title: Text(describeAlarmReminder(minutes)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    if (chosen == null || chosen == current || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context)..hideCurrentSnackBar();
    try {
      await ref
          .read(alarmSettingsRepositoryProvider)
          .setReminderMinutes(chosen);
      ref.invalidate(alarmReminderMinutesProvider);
      messenger.showSnackBar(
        SnackBar(content: Text('Lembrete: ${describeAlarmReminder(chosen)}.')),
      );
    } on ApiException {
      messenger.showSnackBar(
        const SnackBar(content: Text('Não foi possível salvar o lembrete.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final minutes = ref.watch(alarmReminderMinutesProvider);
    final canEdit = ref.watch(
      hasPermissionProvider(AppPermission.manageAlarmSettings),
    );
    final current = minutes.value;

    return ListTile(
      key: const Key('settings-alarm-reminder'),
      leading: const Icon(Icons.alarm),
      title: const Text('Lembrete de alarme'),
      subtitle: Text(switch (minutes) {
        AsyncData(:final value) =>
          canEdit
              ? describeAlarmReminder(value)
              : '${describeAlarmReminder(value)} · definido pela coordenação',
        AsyncError() => 'Não foi possível carregar',
        _ => 'Carregando…',
      }),
      trailing: canEdit && current != null
          ? const Icon(Icons.chevron_right)
          : null,
      onTap: canEdit && current != null
          ? () => _pick(context, ref, current)
          : null,
    );
  }
}
