import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/cached.dart';
import '../../../../shared/devices/device_live_state.dart';
import '../../../../shared/models/campus/campus_enums.dart';
import '../../data/dashboard_repository.dart';
import '../../domain/dashboard_models.dart';

final dashboardOverviewProvider =
    StreamProvider.autoDispose<Cached<DashboardOverview>>(
      (ref) => reconcileLiveDevices(
        ref,
        ref.watch(dashboardRepositoryProvider).watchOverview(),
        (overview) => overview.allDevices,
      ),
      name: 'dashboardOverviewProvider',
    );

/// Contagens do campus já com o estado ao vivo (WebSocket e comandos).
class CampusDeviceSummary {
  const CampusDeviceSummary({
    required this.total,
    required this.online,
    required this.byStatus,
  });

  final int total;
  final int online;
  final Map<DeviceStatus, int> byStatus;

  int get on => byStatus[DeviceStatus.on] ?? 0;
  int get offline => total - online;
}

final campusDeviceSummaryProvider = Provider.autoDispose<CampusDeviceSummary?>((
  ref,
) {
  final overview = ref.watch(dashboardOverviewProvider).value?.data;
  if (overview == null) return null;
  final live = ref.watch(deviceLiveStateProvider);
  final byStatus = {for (final status in DeviceStatus.values) status: 0};
  var total = 0;
  var online = 0;
  for (final device in live.applyAll(overview.allDevices)) {
    total++;
    if (device.online) online++;
    byStatus[device.status] = byStatus[device.status]! + 1;
  }
  return CampusDeviceSummary(total: total, online: online, byStatus: byStatus);
}, name: 'campusDeviceSummaryProvider');
