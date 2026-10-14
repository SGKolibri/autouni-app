import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_paths.dart';
import '../../../../core/router/app_tab.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/devices/device_counts.dart';
import '../../../../shared/devices/device_live_state.dart';
import '../../../../shared/widgets/cached_async_view.dart';
import '../../../../shared/widgets/live_top_bar.dart';
import '../../../../shared/widgets/realtime_status_banner.dart';
import '../providers/environments_providers.dart';
import '../widgets/location_breadcrumb.dart';
import '../widgets/location_card.dart';

/// Salas de um andar.
class RoomsPage extends ConsumerWidget {
  const RoomsPage({required this.buildingId, required this.floorId, super.key});

  final String buildingId;
  final String floorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final floor = ref.watch(floorProvider(floorId)).value?.data;
    final buildingName =
        floor?.building?.name ??
        ref.watch(buildingProvider(buildingId)).value?.data.name ??
        'Prédio';
    final floorName = floor?.displayName ?? 'Andar';
    final rooms = ref.watch(roomsProvider(floorId));
    final live = ref.watch(deviceLiveStateProvider);

    return Scaffold(
      appBar: LiveTopBar(title: floorName),
      body: Column(
        children: [
          LocationBreadcrumb(
            items: [
              BreadcrumbItem('Ambientes', path: AppTab.environments.path),
              BreadcrumbItem(buildingName, path: AppPaths.building(buildingId)),
              BreadcrumbItem(floorName),
            ],
          ),
          const RealtimeStatusBanner(),
          Expanded(
            child: CachedAsyncView(
              value: rooms,
              onRetry: () => ref.invalidate(roomsProvider(floorId)),
              isEmpty: (list) => list.isEmpty,
              empty: const AppEmptyState(
                icon: Icons.meeting_room_outlined,
                title: 'Nenhuma sala neste andar',
              ),
              builder: (context, list) => RefreshIndicator(
                onRefresh: () => ref.refresh(roomsProvider(floorId).future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final room = list[index];
                    return LocationCard(
                      key: ValueKey('room-${room.id}'),
                      icon: Icons.meeting_room_outlined,
                      title: room.name,
                      subtitle: room.type.label,
                      counts: DeviceCounts.of(room.devices, live),
                      todayEnergyKwh: room.todayEnergyKwh,
                      onTap: () => context.go(
                        AppPaths.room(buildingId, floorId, room.id),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
