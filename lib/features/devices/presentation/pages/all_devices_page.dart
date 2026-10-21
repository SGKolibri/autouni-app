import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/devices/live_device_row.dart';
import '../../../../shared/widgets/cached_async_view.dart';
import '../../../../shared/widgets/live_top_bar.dart';
import '../../../../shared/widgets/realtime_status_banner.dart';
import '../../domain/device_filter.dart';
import '../providers/devices_providers.dart';
import '../widgets/device_filter_sheet.dart';

/// Lista global de dispositivos: busca, filtros e scroll infinito.
class AllDevicesPage extends ConsumerStatefulWidget {
  const AllDevicesPage({super.key});

  @override
  ConsumerState<AllDevicesPage> createState() => _AllDevicesPageState();
}

class _AllDevicesPageState extends ConsumerState<AllDevicesPage> {
  late final TextEditingController _search;

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: ref.read(deviceFilterProvider).query);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _clearAll() {
    _search.clear();
    ref.read(deviceFilterProvider.notifier)
      ..setQuery('')
      ..clearFilters();
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(deviceFilterProvider);
    final page = ref.watch(visibleDevicesProvider);
    final total = page.value?.data.total;

    return Scaffold(
      appBar: const LiveTopBar(title: 'Dispositivos'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: TextField(
              key: const Key('devices-search'),
              controller: _search,
              textInputAction: TextInputAction.search,
              onChanged: ref.read(deviceFilterProvider.notifier).setQuery,
              decoration: InputDecoration(
                hintText: 'Buscar por nome, sala ou prédio',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: filter.query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar busca',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _search.clear();
                          ref.read(deviceFilterProvider.notifier).setQuery('');
                        },
                      ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    total == null
                        ? ''
                        : total == 1
                        ? '1 dispositivo'
                        : '$total dispositivos',
                    key: const Key('devices-count'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton.icon(
                  key: const Key('devices-filter'),
                  onPressed: () => showDeviceFilterSheet(context),
                  icon: Badge(
                    isLabelVisible: filter.activeCount > 0,
                    label: Text('${filter.activeCount}'),
                    child: const Icon(Icons.tune),
                  ),
                  label: const Text('Filtros'),
                ),
              ],
            ),
          ),
          const RealtimeStatusBanner(),
          Expanded(
            child: CachedAsyncView<DevicePage>(
              value: page,
              onRetry: () => ref.invalidate(allDevicesProvider),
              isEmpty: (data) => data.total == 0,
              empty: filter.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.devices_other,
                      title: 'Nenhum dispositivo cadastrado',
                    )
                  : AppEmptyState(
                      icon: Icons.search_off,
                      title: 'Nenhum dispositivo encontrado',
                      message: 'Tente outra busca ou ajuste os filtros.',
                      actionLabel: 'Limpar busca e filtros',
                      onAction: _clearAll,
                    ),
              builder: (context, data) => RefreshIndicator(
                onRefresh: () => ref.refresh(allDevicesProvider.future),
                child: ListView.builder(
                  key: const Key('devices-list'),
                  itemCount: data.items.length + (data.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= data.items.length) {
                      return const _LoadMore();
                    }
                    final device = data.items[index];
                    return LiveDeviceRow(device: device, showLocation: true);
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

/// Fim da página: ao aparecer, pede a próxima.
class _LoadMore extends ConsumerStatefulWidget {
  const _LoadMore();

  @override
  ConsumerState<_LoadMore> createState() => _LoadMoreState();
}

class _LoadMoreState extends ConsumerState<_LoadMore> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(deviceListLimitProvider.notifier).loadMore();
    });
  }

  @override
  Widget build(BuildContext context) => const Padding(
    key: Key('devices-load-more'),
    padding: EdgeInsets.all(AppSpacing.lg),
    child: Center(
      child: SizedBox.square(
        dimension: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    ),
  );
}
