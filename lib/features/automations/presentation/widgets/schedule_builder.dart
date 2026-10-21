import 'package:flutter/material.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../domain/schedule.dart';

/// Construtor de agenda: dias da semana (chips) + horário. Controlado: quem
/// usa guarda o [value] e recebe cada mudança em [onChanged].
class ScheduleBuilder extends StatelessWidget {
  const ScheduleBuilder({
    required this.value,
    required this.onChanged,
    this.showErrors = false,
    super.key,
  });

  final WeeklySchedule value;
  final ValueChanged<WeeklySchedule> onChanged;

  /// Mostra "Escolha pelo menos um dia." (depois de tentar salvar).
  final bool showErrors;

  /// Ordem dos chips: segunda a domingo, como no calendário brasileiro.
  static const List<Weekday> order = [
    Weekday.monday,
    Weekday.tuesday,
    Weekday.wednesday,
    Weekday.thursday,
    Weekday.friday,
    Weekday.saturday,
    Weekday.sunday,
  ];

  void _toggle(Weekday day) {
    final days = {...value.days};
    days.contains(day) ? days.remove(day) : days.add(day);
    onChanged(
      WeeklySchedule(days: days, hour: value.hour, minute: value.minute),
    );
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: value.hour, minute: value.minute),
      helpText: 'Horário da automação',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    onChanged(
      WeeklySchedule(
        days: value.days,
        hour: picked.hour,
        minute: picked.minute,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = showErrors ? value.validationError : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Dias', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            for (final day in order)
              FilterChip(
                key: ValueKey('day-${day.name}'),
                label: Text(day.shortLabel),
                selected: value.days.contains(day),
                showCheckmark: false,
                onSelected: (_) => _toggle(day),
              ),
          ],
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Text('Horário', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          key: const Key('schedule-time'),
          onPressed: () => _pickTime(context),
          icon: const Icon(Icons.access_time),
          label: Text(formatTime(value.hour, value.minute)),
        ),
        const SizedBox(height: AppSpacing.md),
        if (value.isValid)
          Text(
            '${value.describe()} · cron ${value.toCron()}',
            key: const Key('schedule-preview'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
