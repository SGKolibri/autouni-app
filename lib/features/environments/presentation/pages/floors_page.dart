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

/// Andares de um prédio.
class FloorsPage extends ConsumerWidget {
  const FloorsPage({required this.buildingId, super.key});

  final String buildingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildingName =
        ref.watch(buildingProvider(buildingId)).value?.data.name ?? 'Prédio';
    final floors = ref.watch(floorsProvider(buildingId));
    final live = ref.watch(deviceLiveStateProvider);

    return Scaffold(
      appBar: LiveTopBar(
        title: buildingName,
        actions: [
          IconButton(
            key: const Key('building-energy'),
            tooltip: 'Consumo de energia',
            icon: const Icon(Icons.bolt_outlined),
            onPressed: () => context.push(
              AppPaths.energyOf(
                level: 'building',
                id: buildingId,
                name: buildingName,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          LocationBreadcrumb(
            items: [
              BreadcrumbItem('Ambientes', path: AppTab.environments.path),
              BreadcrumbItem(buildingName),
            ],
          ),
          const RealtimeStatusBanner(),
          Expanded(
            child: CachedAsyncView(
              value: floors,
              onRetry: () => ref.invalidate(floorsProvider(buildingId)),
              isEmpty: (list) => list.isEmpty,
              empty: const AppEmptyState(
                icon: Icons.layers_outlined,
                title: 'Nenhum andar neste prédio',
              ),
              builder: (context, list) => RefreshIndicator(
                onRefresh: () => ref.refresh(floorsProvider(buildingId).future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final floor = list[index];
                    final rooms = floor.rooms.length;
                    return LocationCard(
                      key: ValueKey('floor-${floor.id}'),
                      icon: Icons.layers_outlined,
                      title: floor.displayName,
                      subtitle: rooms == 1 ? '1 sala' : '$rooms salas',
                      counts: DeviceCounts.of(floor.allDevices, live),
                      todayEnergyKwh: floor.todayEnergyKwh,
                      onTap: () =>
                          context.go(AppPaths.floor(buildingId, floor.id)),
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
