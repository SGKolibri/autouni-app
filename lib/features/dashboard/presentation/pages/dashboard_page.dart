import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_paths.dart';
import '../../../../core/router/app_tab.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/devices/device_counts.dart';
import '../../../../shared/devices/device_live_state.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/cached_async_view.dart';
import '../../../../shared/widgets/live_top_bar.dart';
import '../../../../shared/widgets/realtime_status_banner.dart';
import '../../domain/dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/alert_tile.dart';
import '../widgets/status_donut.dart';

/// Aba Início: KPIs do campus, status dos dispositivos, prédios e alertas
/// recentes — com as contagens ao vivo pelo WebSocket.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  /// Quantos alertas recentes aparecem.
  static const int recentAlerts = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overview = ref.watch(dashboardOverviewProvider);

    return Scaffold(
      appBar: const LiveTopBar(title: 'Início'),
      body: Column(
        children: [
          const RealtimeStatusBanner(),
          Expanded(
            child: CachedAsyncView<DashboardOverview>(
              value: overview,
              onRetry: () => ref.invalidate(dashboardOverviewProvider),
              loading: const _DashboardSkeleton(),
              builder: (context, data) => RefreshIndicator(
                onRefresh: () => ref.refresh(dashboardOverviewProvider.future),
                child: _DashboardContent(overview: data),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summary = ref.watch(campusDeviceSummaryProvider);
    final live = ref.watch(deviceLiveStateProvider);
    final energy = overview.energy;
    final alerts = overview.alerts.take(DashboardPage.recentAlerts).toList();

    Widget sectionTitle(String title, {Widget? action}) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          ?action,
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
            0,
          ),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.45,
            children: [
              KpiCard(
                label: 'Dispositivos ligados',
                value: '${summary?.on ?? 0}/${summary?.total ?? 0}',
                icon: Icons.power,
                onTap: () => context.go(AppPaths.allDevices),
              ),
              KpiCard(
                label: 'Online',
                value: '${summary?.online ?? 0}/${summary?.total ?? 0}',
                icon: Icons.wifi,
                trend: (summary?.offline ?? 0) > 0
                    ? KpiTrend(
                        label: '${summary!.offline} offline',
                        direction: KpiTrendDirection.down,
                      )
                    : null,
                onTap: () => context.go(AppPaths.allDevices),
              ),
              KpiCard(
                label: 'Consumo hoje',
                value: energy == null ? '—' : formatKwh(energy.todayEnergyKwh),
                icon: Icons.bolt,
              ),
              KpiCard(
                label: 'Alertas não lidos',
                value: '${overview.unreadAlerts}',
                icon: Icons.notifications_outlined,
                onTap: () => context.go(AppTab.notifications.path),
              ),
            ],
          ),
        ),
        sectionTitle('Status dos dispositivos'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: StatusDonut(byStatus: summary?.byStatus ?? const {}),
            ),
          ),
        ),
        sectionTitle(
          'Prédios',
          action: TextButton(
            onPressed: () => context.go(AppTab.environments.path),
            child: const Text('Ver ambientes'),
          ),
        ),
        if (overview.buildings.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Nenhum prédio cadastrado.'),
          ),
        for (final building in overview.buildings)
          Card(
            margin: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Builder(
              builder: (context) {
                final counts = DeviceCounts.of(building.allDevices, live);
                return ListTile(
                  key: ValueKey('dashboard-building-${building.id}'),
                  leading: const Icon(Icons.apartment),
                  title: Text(building.name),
                  subtitle: Text(
                    '${counts.on}/${counts.total} ligados · '
                    '${formatKwh(building.todayEnergyKwh)} hoje',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(AppPaths.building(building.id)),
                );
              },
            ),
          ),
        sectionTitle(
          'Alertas recentes',
          action: TextButton(
            onPressed: () => context.go(AppTab.notifications.path),
            child: const Text('Ver todos'),
          ),
        ),
        if (alerts.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text('Nenhum alerta recente.'),
          )
        else
          Card(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              children: [for (final alert in alerts) AlertTile(alert: alert)],
            ),
          ),
      ],
    );
  }
}

/// Esqueleto no formato do dashboard (KPIs + blocos).
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            childAspectRatio: 1.45,
            children: List.generate(
              4,
              (_) => const AppSkeleton(height: 96, radius: AppRadius.lg),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const AppSkeleton(height: 164, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.xl),
          const AppSkeleton(height: 64, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.sm),
          const AppSkeleton(height: 64, radius: AppRadius.lg),
        ],
      ),
    );
  }
}
