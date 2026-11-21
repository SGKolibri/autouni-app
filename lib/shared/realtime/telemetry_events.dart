import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/realtime/realtime_providers.dart';

/// Nomes dos eventos de telemetria emitidos pelo `RealtimeGateway`.
abstract final class TelemetryEventNames {
  static const String energy = 'energy:update';
  static const String sensor = 'sensor:update';
  static const String alarm = 'sensor:alarm';
  static const String occupancy = 'room:occupancy';

  static const List<String> all = [energy, sensor, alarm, occupancy];
}

double? _num(Object? v) => v is num ? v.toDouble() : null;

/// Última medição elétrica do device. `powerW` é potência instantânea (W);
/// `energyWh` é a energia do intervalo desde a leitura anterior.
class LiveEnergy {
  const LiveEnergy({
    required this.timestamp,
    this.powerW,
    this.energyWh,
    this.voltage,
    this.current,
    this.frequency,
    this.powerFactor,
  });

  final DateTime timestamp;
  final double? powerW;
  final double? energyWh;
  final double? voltage;
  final double? current;
  final double? frequency;
  final double? powerFactor;
}

/// Última leitura de sensor. [kind]: GAS_MQ2, GAS_MQ135 ou MOTION.
class LiveSensor {
  const LiveSensor({
    required this.kind,
    required this.value,
    required this.timestamp,
    this.unit,
  });

  final String kind;
  final double value;
  final String? unit;
  final DateTime timestamp;

  bool get isMotion => kind == 'MOTION';
}

/// Alarme de gás aberto. [level]: WARNING ou CRITICAL.
class LiveAlarm {
  const LiveAlarm({
    required this.id,
    required this.level,
    required this.value,
    required this.threshold,
  });

  final String id;
  final String level;
  final double value;
  final double threshold;

  bool get isCritical => level == 'CRITICAL';
}

class LiveTelemetry {
  const LiveTelemetry({
    this.energy = const {},
    this.sensors = const {},
    this.alarms = const {},
    this.occupancy = const {},
  });

  final Map<String, LiveEnergy> energy; // deviceId ->
  final Map<String, LiveSensor> sensors; // deviceId ->
  final Map<String, LiveAlarm> alarms; // deviceId -> alarme aberto
  final Map<String, bool> occupancy; // roomId -> ocupada

  LiveTelemetry copyWith({
    Map<String, LiveEnergy>? energy,
    Map<String, LiveSensor>? sensors,
    Map<String, LiveAlarm>? alarms,
    Map<String, bool>? occupancy,
  }) => LiveTelemetry(
    energy: energy ?? this.energy,
    sensors: sensors ?? this.sensors,
    alarms: alarms ?? this.alarms,
    occupancy: occupancy ?? this.occupancy,
  );
}

/// Aplica um evento ao estado; devolve o mesmo estado se o payload não servir.
LiveTelemetry reduceTelemetry(LiveTelemetry s, String event, Object? data) {
  if (data is! Map) return s;
  final ts = DateTime.tryParse('${data['timestamp']}') ?? DateTime.now();

  switch (event) {
    case TelemetryEventNames.energy:
      final id = data['deviceId'];
      if (id is! String) return s;
      return s.copyWith(
        energy: {
          ...s.energy,
          id: LiveEnergy(
            timestamp: ts,
            powerW: _num(data['power']),
            energyWh: _num(data['energy']),
            voltage: _num(data['voltage']),
            current: _num(data['current']),
            frequency: _num(data['frequency']),
            powerFactor: _num(data['powerFactor']),
          ),
        },
      );
    case TelemetryEventNames.sensor:
      final id = data['deviceId'];
      final kind = data['kind'];
      final value = _num(data['value']);
      if (id is! String || kind is! String || value == null) return s;
      return s.copyWith(
        sensors: {
          ...s.sensors,
          id: LiveSensor(
            kind: kind,
            value: value,
            unit: data['unit'] as String?,
            timestamp: ts,
          ),
        },
      );
    case TelemetryEventNames.alarm:
      final id = data['deviceId'];
      final alarm = data['alarm'];
      if (id is! String || alarm is! Map) return s;
      final alarms = {...s.alarms};
      if (data['state'] == 'cleared' || alarm['clearedAt'] != null) {
        alarms.remove(id);
      } else {
        alarms[id] = LiveAlarm(
          id: '${alarm['id']}',
          level: '${alarm['level']}',
          value: _num(alarm['value']) ?? 0,
          threshold: _num(alarm['threshold']) ?? 0,
        );
      }
      return s.copyWith(alarms: alarms);
    case TelemetryEventNames.occupancy:
      final roomId = data['roomId'];
      final occupied = data['occupied'];
      if (roomId is! String || occupied is! bool) return s;
      return s.copyWith(occupancy: {...s.occupancy, roomId: occupied});
  }
  return s;
}

/// Telemetria ao vivo (energia, gás, presença). Único dono dos eventos
/// `energy:update`, `sensor:update`, `sensor:alarm` e `room:occupancy`.
class TelemetryLiveState extends Notifier<LiveTelemetry> {
  @override
  LiveTelemetry build() {
    final client = ref.watch(realtimeClientProvider);
    for (final name in TelemetryEventNames.all) {
      client.on(name, (data) => state = reduceTelemetry(state, name, data));
    }
    ref.onDispose(() {
      for (final name in TelemetryEventNames.all) {
        client.off(name);
      }
    });
    return const LiveTelemetry();
  }
}

final telemetryLiveProvider =
    NotifierProvider<TelemetryLiveState, LiveTelemetry>(
      TelemetryLiveState.new,
      name: 'telemetryLiveProvider',
    );
