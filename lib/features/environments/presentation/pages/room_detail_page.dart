import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/router/app_paths.dart';
import '../../../../core/router/app_tab.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/devices/device_controller.dart';
import '../../../../shared/devices/device_counts.dart';
import '../../../../shared/devices/device_live_state.dart';
import '../../../../shared/devices/live_device_row.dart';
import '../../../../shared/models/campus/campus_models.dart';
import '../../../../shared/rbac/app_permission.dart';
import '../../../../shared/rbac/permission_gate.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/cached_async_view.dart';
import '../../../../shared/widgets/live_top_bar.dart';
import '../../../../shared/widgets/realtime_status_banner.dart';
import '../providers/environments_providers.dart';
import '../widgets/location_breadcrumb.dart';

/// Detalhe da sala: KPIs, dispositivos com controle e "Desligar todos".
class RoomDetailPage extends ConsumerWidget {
  const RoomDetailPage({
    required this.buildingId,
    required this.floorId,
    required this.roomId,
    super.key,
  });

  final String buildingId;
  final String floorId;
  final String roomId;

  Future<void> _turnOffAll(
    BuildContext context,
    WidgetRef ref,
    Room room,
    int onlineOn,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Desligar todos?'),
        content: Text(
          onlineOn == 1
              ? 'O dispositivo ligado em ${room.name} será desligado.'
              : 'Os $onlineOn dispositivos ligados em ${room.name} serão '
                    'desligados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Desligar'),
          ),
        ],
      ),
    );
    if (!(confirmed ?? false) || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final outcome = await ref
        .read(deviceControllerProvider)
        .turnOffAll(room.devices);
    final message = switch (outcome) {
      BulkOutcome(:final error?) => error,
      BulkOutcome(requested: 0) => 'Nenhum dispositivo ligado para desligar.',
      BulkOutcome(failedIds: []) =>
        outcome.succeeded == 1
            ? '1 dispositivo desligado.'
            : '${outcome.succeeded} dispositivos desligados.',
      _ =>
        '${outcome.succeeded} de ${outcome.requested} desligados; '
            '${outcome.failedIds.length} não responderam.',
    };
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(roomDetailsProvider(roomId));
    final room = details.value?.data;
    final floor = room?.floor;
    final live = ref.watch(deviceLiveStateProvider);
    final devices = live.applyAll(room?.devices ?? const []);
    final onlineOn = devices.where((d) => d.isOn && d.online).length;

    return Scaffold(
      appBar: LiveTopBar(
        title: room?.name ?? 'Sala',
        actions: [
          if (room != null)
            PermissionGate(
              permission: AppPermission.bulkControlDevices,
              child: IconButton(
                key: const Key('room-turn-off-all'),
                tooltip: 'Desligar todos',
                icon: const Icon(Icons.power_settings_new),
                onPressed: onlineOn == 0
                    ? null
                    : () => _turnOffAll(context, ref, room, onlineOn),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          LocationBreadcrumb(
            items: [
              BreadcrumbItem('Ambientes', path: AppTab.environments.path),
              BreadcrumbItem(
                floor?.building?.name ?? 'Prédio',
                path: AppPaths.building(buildingId),
              ),
              BreadcrumbItem(
                floor?.displayName ?? 'Andar',
                path: AppPaths.floor(buildingId, floorId),
              ),
              BreadcrumbItem(room?.name ?? 'Sala'),
            ],
          ),
          const RealtimeStatusBanner(),
          Expanded(
            child: CachedAsyncView(
              value: details,
              onRetry: () => ref.invalidate(roomDetailsProvider(roomId)),
              builder: (context, room) => RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(roomDetailsProvider(roomId).future),
                child: _RoomContent(room: room),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomContent extends ConsumerWidget {
  const _RoomContent({required this.room});

  final Room room;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(deviceLiveStateProvider);
    final counts = DeviceCounts.of(room.devices, live);
    final devices = [...room.devices]..sort((a, b) => a.name.compareTo(b.name));

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.6,
            children: [
              KpiCard(
                label: 'Ligados',
                value: '${counts.on}/${counts.total}',
                icon: Icons.power,
              ),
              KpiCard(
                label: 'Online',
                value: '${counts.online}/${counts.total}',
                icon: Icons.wifi,
              ),
              KpiCard(
                label: 'Consumo hoje',
                value: formatKwh(room.todayEnergyKwh),
                icon: Icons.bolt,
              ),
              KpiCard(
                label: 'Tipo',
                value: room.type.label,
                icon: Icons.meeting_room_outlined,
              ),
            ],
          ),
        ),
        if (devices.isEmpty)
          const SizedBox(
            height: 240,
            child: AppEmptyState(
              icon: Icons.devices_other,
              title: 'Nenhum dispositivo nesta sala',
            ),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              'Dispositivos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          for (final device in devices) LiveDeviceRow(device: device),
        ],
      ],
    );
  }
}
