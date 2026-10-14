import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/models/campus/campus_enums.dart';
import '../../domain/device_filter.dart';
import '../providers/devices_providers.dart';

Future<void> showDeviceFilterSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const DeviceFilterSheet(),
    );

/// Filtros da lista global: status, tipo e disponibilidade. Aplicam na hora;
/// o botão fecha mostrando quantos resultados há.
class DeviceFilterSheet extends ConsumerWidget {
  const DeviceFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final filter = ref.watch(deviceFilterProvider);
    final controller = ref.read(deviceFilterProvider.notifier);
    final total = ref.watch(visibleDevicesProvider).value?.data.total;

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          0,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Filtros', style: theme.textTheme.titleLarge),
                ),
                TextButton(
                  onPressed: filter.activeCount == 0
                      ? null
                      : controller.clearFilters,
                  child: const Text('Limpar'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            section(
              'Disponibilidade',
              SegmentedButton<AvailabilityFilter>(
                segments: [
                  for (final option in AvailabilityFilter.values)
                    ButtonSegment(value: option, label: Text(option.label)),
                ],
                selected: {filter.availability},
                onSelectionChanged: (selection) =>
                    controller.setAvailability(selection.single),
              ),
            ),
            section(
              'Status',
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final status in DeviceStatus.values)
                    FilterChip(
                      key: ValueKey('filter-status-${status.name}'),
                      label: Text(status.label),
                      selected: filter.statuses.contains(status),
                      onSelected: (_) => controller.toggleStatus(status),
                    ),
                ],
              ),
            ),
            section(
              'Tipo',
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  for (final type in DeviceType.values)
                    FilterChip(
                      key: ValueKey('filter-type-${type.name}'),
                      label: Text(type.label),
                      selected: filter.types.contains(type),
                      onSelected: (_) => controller.toggleType(type),
                    ),
                ],
              ),
            ),
            FilledButton(
              key: const Key('filter-apply'),
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                total == null
                    ? 'Ver resultados'
                    : total == 1
                    ? 'Ver 1 dispositivo'
                    : 'Ver $total dispositivos',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
