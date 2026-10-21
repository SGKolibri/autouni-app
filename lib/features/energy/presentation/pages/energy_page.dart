import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_paths.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/utils/formatters.dart';
import '../../../../shared/widgets/cached_async_view.dart';
import '../../domain/energy_models.dart';
import '../providers/energy_providers.dart';
import '../widgets/energy_history_chart.dart';
import '../widgets/energy_ranking.dart';
import '../widgets/power_gauge.dart';

/// Consumo de energia de um escopo (campus, prédio, andar, sala ou
/// dispositivo): período, KPIs, histórico, potência e ranking do nível de
/// baixo — tocar no ranking desce um nível.
class EnergyPage extends ConsumerWidget {
  const EnergyPage({this.scope = const EnergyScope.campus(), super.key});

  final EnergyScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(energyPeriodProvider);
    final key = (scope, period);
    final overview = ref.watch(energyOverviewProvider(key));

    return Scaffold(
      appBar: const AppTopBar(title: 'Energia'),
      body: Column(
        children: [
          _ScopeHeader(scope: scope),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<EnergyPeriod>(
                key: const Key('energy-period'),
                showSelectedIcon: false,
                segments: [
                  for (final option in EnergyPeriod.values)
                    ButtonSegment(value: option, label: Text(option.label)),
                ],
                selected: {period},
                onSelectionChanged: (selection) => ref
                    .read(energyPeriodProvider.notifier)
                    .select(selection.single),
              ),
            ),
          ),
          Expanded(
            child: CachedAsyncView<EnergyOverview>(
              value: overview,
              onRetry: () => ref.invalidate(energyOverviewProvider(key)),
              loading: const _EnergySkeleton(),
              isEmpty: (data) => !data.stats.hasData && data.history.isEmpty,
              empty: AppEmptyState(
                icon: Icons.bolt_outlined,
                title: 'Sem consumo registrado',
                message:
                    'Nenhuma leitura de energia em ${scope.name} '
                    '(${period.label.toLowerCase()}).',
              ),
              builder: (context, data) => RefreshIndicator(
                onRefresh: () =>
                    ref.refresh(energyOverviewProvider(key).future),
                child: _EnergyContent(overview: data),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nível e nome do escopo, com atalho para voltar ao campus.
class _ScopeHeader extends StatelessWidget {
  const _ScopeHeader({required this.scope});

  final EnergyScope scope;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCampus = scope.level == EnergyLevel.general;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scope.level.label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  scope.name,
                  key: const Key('energy-scope-name'),
                  style: theme.textTheme.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!isCampus)
            TextButton.icon(
              key: const Key('energy-campus'),
              onPressed: () => context.push(AppPaths.energy()),
              icon: const Icon(Icons.public, size: 18),
              label: const Text('Campus'),
            ),
        ],
      ),
    );
  }
}

class _EnergyContent extends StatelessWidget {
  const _EnergyContent({required this.overview});

  final EnergyOverview overview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = overview.stats;
    final current = overview.currentKw;
    final peak = overview.peakKw;
    final rankingTitle = overview.scope.level.rankingTitle;
    final ranking = overview.ranking;

    Widget section(String title, Widget child) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: KpiGrid(
            children: [
              KpiCard(
                label: 'Consumo (${overview.period.label.toLowerCase()})',
                value: formatKwh(stats.totalKwh),
                icon: Icons.bolt,
              ),
              KpiCard(
                label: 'Potência agora',
                value: current == null ? '—' : formatKw(current),
                icon: Icons.speed,
              ),
              KpiCard(
                label: 'Pico do período',
                value: peak == null ? '—' : formatKw(peak),
                icon: Icons.trending_up,
              ),
              if (stats.totalDevices != null)
                KpiCard(
                  label: 'Dispositivos ligados',
                  value: '${stats.activeDevices ?? 0}/${stats.totalDevices}',
                  icon: Icons.power,
                )
              else
                KpiCard(
                  label: 'Média por leitura',
                  value: stats.avgWh == null ? '—' : formatWh(stats.avgWh!),
                  icon: Icons.analytics_outlined,
                ),
            ],
          ),
        ),
        section(
          overview.period == EnergyPeriod.today
              ? 'Consumo por hora (kWh)'
              : 'Consumo por dia (kWh)',
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: EnergyHistoryChart(
                points: overview.history,
                period: overview.period,
              ),
            ),
          ),
        ),
        section(
          'Potência',
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: PowerGauge(currentKw: current, peakKw: peak),
              ),
            ),
          ),
        ),
        if (rankingTitle != null)
          section(
            rankingTitle,
            Card(
              clipBehavior: Clip.antiAlias,
              child: ranking == null
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('Ranking indisponível no momento.'),
                    )
                  : EnergyRanking(
                      items: overview.sortedRanking,
                      onTap: (item) {
                        final child = overview.scope.childFor(item);
                        if (child != null) {
                          context.push(AppPaths.energy(child.toQuery()));
                        }
                      },
                    ),
            ),
          ),
      ],
    );
  }
}

class _EnergySkeleton extends StatelessWidget {
  const _EnergySkeleton();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Carregando',
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          KpiGrid(
            children: List.generate(
              4,
              (_) => const AppSkeleton(height: 96, radius: AppRadius.lg),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const AppSkeleton(height: 200, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.xl),
          const AppSkeleton(height: 140, radius: AppRadius.lg),
        ],
      ),
    );
  }
}
