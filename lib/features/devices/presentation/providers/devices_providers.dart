import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/cached.dart';
import '../../../../shared/devices/device_live_state.dart';
import '../../../../shared/devices/device_repository.dart';
import '../../../../shared/models/campus/campus_enums.dart';
import '../../../../shared/models/campus/campus_models.dart';
import '../../domain/device_filter.dart';

/// Todos os dispositivos (`GET /devices` não pagina: a lista vem inteira e
/// é cacheada; busca, filtros e páginas são no aparelho).
final allDevicesProvider = StreamProvider.autoDispose<Cached<List<Device>>>(
  (ref) => reconcileLiveDevices(
    ref,
    ref.watch(deviceRepositoryProvider).watchAll(),
    (devices) => devices,
  ),
  name: 'allDevicesProvider',
);

class DeviceFilterController extends Notifier<DeviceFilter> {
  @override
  DeviceFilter build() => const DeviceFilter();

  void setQuery(String query) => state = state.copyWith(query: query);

  void toggleStatus(DeviceStatus status) =>
      state = state.copyWith(statuses: _toggle(state.statuses, status));

  void toggleType(DeviceType type) =>
      state = state.copyWith(types: _toggle(state.types, type));

  void setAvailability(AvailabilityFilter availability) =>
      state = state.copyWith(availability: availability);

  /// Limpa os filtros do bottom sheet (mantém a busca).
  void clearFilters() => state = DeviceFilter(query: state.query);

  static Set<T> _toggle<T>(Set<T> set, T value) =>
      set.contains(value) ? ({...set}..remove(value)) : {...set, value};
}

final deviceFilterProvider =
    NotifierProvider<DeviceFilterController, DeviceFilter>(
      DeviceFilterController.new,
      name: 'deviceFilterProvider',
    );

/// Quantos itens a lista mostra (scroll infinito). Volta à primeira página
/// a cada mudança de busca/filtro.
class DeviceListLimit extends Notifier<int> {
  static const int pageSize = 30;

  @override
  int build() {
    ref.watch(deviceFilterProvider);
    return pageSize;
  }

  void loadMore() => state += pageSize;
}

final deviceListLimitProvider = NotifierProvider<DeviceListLimit, int>(
  DeviceListLimit.new,
  name: 'deviceListLimitProvider',
);

/// A página visível: estado ao vivo aplicado, filtros, ordenação e limite.
final visibleDevicesProvider =
    Provider.autoDispose<AsyncValue<Cached<DevicePage>>>((ref) {
      final all = ref.watch(allDevicesProvider);
      final live = ref.watch(deviceLiveStateProvider);
      final filter = ref.watch(deviceFilterProvider);
      final limit = ref.watch(deviceListLimitProvider);
      return all.whenData(
        (cached) => Cached(
          DevicePage.of(
            filterDevices(live.applyAll(cached.data), filter),
            limit,
          ),
          savedAt: cached.savedAt,
          offline: cached.offline,
        ),
      );
    }, name: 'visibleDevicesProvider');
