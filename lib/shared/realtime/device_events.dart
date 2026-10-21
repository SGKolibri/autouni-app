import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/realtime/realtime_providers.dart';
import '../models/campus/campus_enums.dart';

/// Evento de dispositivo vindo do WebSocket.
sealed class DeviceEvent {
  const DeviceEvent({required this.deviceId, this.timestamp});

  final String deviceId;
  final DateTime? timestamp;
}

/// `device:status` — `{ deviceId, status, timestamp }`.
class DeviceStatusChanged extends DeviceEvent {
  const DeviceStatusChanged({
    required super.deviceId,
    required this.status,
    super.timestamp,
  });

  final DeviceStatus status;
}

/// `device:online` — `{ deviceId, online, timestamp }`.
class DeviceOnlineChanged extends DeviceEvent {
  const DeviceOnlineChanged({
    required super.deviceId,
    required this.online,
    super.timestamp,
  });

  final bool online;
}

/// Nomes dos eventos emitidos pelo `RealtimeGateway` do backend.
abstract final class DeviceEventNames {
  static const String status = 'device:status';
  static const String online = 'device:online';
}

/// Converte o payload de um evento; `null` se vier malformado.
DeviceEvent? parseDeviceEvent(String event, Object? data) {
  if (data is! Map) return null;
  final deviceId = data['deviceId'];
  if (deviceId is! String || deviceId.isEmpty) return null;
  final timestamp = DateTime.tryParse('${data['timestamp']}');

  switch (event) {
    case DeviceEventNames.status:
      final raw = data['status'];
      if (raw is! String) return null;
      return DeviceStatusChanged(
        deviceId: deviceId,
        status: DeviceStatus.fromApi(raw),
        timestamp: timestamp,
      );
    case DeviceEventNames.online:
      final online = data['online'];
      if (online is! bool) return null;
      return DeviceOnlineChanged(
        deviceId: deviceId,
        online: online,
        timestamp: timestamp,
      );
  }
  return null;
}

/// Fluxo único dos eventos de dispositivo.
///
/// O `RealtimeClient` guarda um handler por evento, então este provider é o
/// único dono de `device:status`/`device:online` e redistribui para quantos
/// ouvintes houver (listas, dashboard, controle).
final deviceEventsProvider = Provider<Stream<DeviceEvent>>((ref) {
  final client = ref.watch(realtimeClientProvider);
  final controller = StreamController<DeviceEvent>.broadcast();

  for (final name in [DeviceEventNames.status, DeviceEventNames.online]) {
    client.on(name, (data) {
      final event = parseDeviceEvent(name, data);
      if (event != null && !controller.isClosed) controller.add(event);
    });
  }
  ref.onDispose(() {
    client
      ..off(DeviceEventNames.status)
      ..off(DeviceEventNames.online);
    unawaited(controller.close());
  });
  return controller.stream;
}, name: 'deviceEventsProvider');
