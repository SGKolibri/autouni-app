import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/cached.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/devices/device_repository.dart';
import '../../../../shared/models/campus/campus_models.dart';
import '../../../../shared/widgets/cached_async_view.dart';
import '../../domain/automation_models.dart';

/// Dispositivos que podem ser alvo de automação (têm tópico MQTT).
final automationTargetsProvider =
    StreamProvider.autoDispose<Cached<List<Device>>>(
      (ref) => ref
          .watch(deviceRepositoryProvider)
          .watchAll()
          .map(
            (cached) => Cached(
              [
                for (final device in cached.data)
                  if (AutomationAction.canTarget(device)) device,
              ]..sort((a, b) => a.name.compareTo(b.name)),
              savedAt: cached.savedAt,
              offline: cached.offline,
            ),
          ),
      name: 'automationTargetsProvider',
    );

/// Abre a busca de dispositivos e devolve o escolhido.
Future<Device?> showDevicePicker(BuildContext context) =>
    showModalBottomSheet<Device>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const FractionallySizedBox(
        heightFactor: 0.85,
        child: DevicePickerSheet(),
      ),
    );

/// Lista pesquisável (nome ou local) — o campus tem centenas de
/// dispositivos.
class DevicePickerSheet extends ConsumerStatefulWidget {
  const DevicePickerSheet({super.key});

  @override
  ConsumerState<DevicePickerSheet> createState() => _DevicePickerSheetState();
}

class _DevicePickerSheetState extends ConsumerState<DevicePickerSheet> {
  String _query = '';

  bool _matches(Device device) {
    if (_query.isEmpty) return true;
    final needle = _query.toLowerCase();
    return device.name.toLowerCase().contains(needle) ||
        (device.locationLabel?.toLowerCase().contains(needle) ?? false);
  }

  @override
  Widget build(BuildContext context) {
    final targets = ref.watch(automationTargetsProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: TextField(
            key: const Key('device-picker-search'),
            autofocus: true,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Buscar por nome ou sala',
            ),
            onChanged: (value) => setState(() => _query = value.trim()),
          ),
        ),
        Expanded(
          child: CachedAsyncView<List<Device>>(
            value: targets,
            onRetry: () => ref.invalidate(automationTargetsProvider),
            builder: (context, devices) {
              final visible = devices.where(_matches).toList();
              if (visible.isEmpty) {
                return const AppEmptyState(
                  icon: Icons.search_off,
                  title: 'Nenhum dispositivo encontrado',
                  message: 'Só aparecem dispositivos ligados ao MQTT.',
                );
              }
              return ListView.builder(
                itemCount: visible.length,
                itemBuilder: (context, index) {
                  final device = visible[index];
                  return ListTile(
                    key: ValueKey('pick-${device.id}'),
                    title: Text(device.name),
                    subtitle: device.locationLabel == null
                        ? null
                        : Text(device.locationLabel!),
                    trailing: Text(device.type.label),
                    onTap: () => Navigator.of(context).pop(device),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
