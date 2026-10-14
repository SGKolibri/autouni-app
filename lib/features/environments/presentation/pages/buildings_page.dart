import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_paths.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/devices/device_counts.dart';
import '../../../../shared/devices/device_live_state.dart';
import '../../../../shared/widgets/cached_async_view.dart';
import '../../../../shared/widgets/live_top_bar.dart';
import '../../../../shared/widgets/realtime_status_banner.dart';
import '../providers/environments_providers.dart';
import '../widgets/location_card.dart';

/// Raiz da aba Ambientes: os prédios do campus.
class BuildingsPage extends ConsumerWidget {
  const BuildingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buildings = ref.watch(buildingsProvider);
    final live = ref.watch(deviceLiveStateProvider);

    return Scaffold(
      appBar: LiveTopBar(
        title: 'Ambientes',
        actions: [
          IconButton(
            tooltip: 'Todos os dispositivos',
            icon: const Icon(Icons.devices_other),
            onPressed: () => context.go(AppPaths.allDevices),
          ),
        ],
      ),
      body: Column(
        children: [
          const RealtimeStatusBanner(),
          Expanded(
            child: CachedAsyncView(
              value: buildings,
              onRetry: () => ref.invalidate(buildingsProvider),
              isEmpty: (list) => list.isEmpty,
              empty: AppEmptyState(
                icon: Icons.apartment,
                title: 'Nenhum prédio cadastrado',
                message: 'Os prédios cadastrados no AutoUni aparecem aqui.',
                actionLabel: 'Atualizar',
                onAction: () => ref.invalidate(buildingsProvider),
              ),
              builder: (context, list) => RefreshIndicator(
                onRefresh: () => ref.refresh(buildingsProvider.future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final building = list[index];
                    return LocationCard(
                      key: ValueKey('building-${building.id}'),
                      icon: Icons.apartment,
                      title: building.name,
                      subtitle: building.location,
                      counts: DeviceCounts.of(building.allDevices, live),
                      todayEnergyKwh: building.todayEnergyKwh,
                      onTap: () => context.go(AppPaths.building(building.id)),
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
