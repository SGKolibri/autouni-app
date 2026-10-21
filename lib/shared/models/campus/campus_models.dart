import 'package:freezed_annotation/freezed_annotation.dart';

import 'campus_enums.dart';

part 'campus_models.freezed.dart';
part 'campus_models.g.dart';

/// Prédio, como em `GET /buildings` (com a árvore de andares, salas e
/// dispositivos e o resumo de consumo de hoje) ou `GET /buildings/:id`
/// (só os campos do prédio).
@freezed
abstract class Building with _$Building {
  const factory Building({
    required String id,
    required String name,
    String? description,
    @Default('') String location,
    @Default(<Floor>[]) List<Floor> floors,
    @Default(0) int totalDevices,
    @Default(0) int activeDevices,
    @Default(0) double todayEnergyKwh,
    DateTime? lastReadingAt,
  }) = _Building;

  factory Building.fromJson(Map<String, dynamic> json) =>
      _$BuildingFromJson(json);
}

/// Andar (`GET /floors/building/:id`, `GET /floors/:id`).
@freezed
abstract class Floor with _$Floor {
  const Floor._();

  const factory Floor({
    required String id,
    required String buildingId,
    required int number,
    String? name,
    Building? building,
    @Default(<Room>[]) List<Room> rooms,
    @Default(0) int totalDevices,
    @Default(0) int activeDevices,
    @Default(0) double todayEnergyKwh,
  }) = _Floor;

  factory Floor.fromJson(Map<String, dynamic> json) => _$FloorFromJson(json);

  /// Nome exibido: o cadastrado, ou derivado do número (0 = Térreo).
  String get displayName {
    final custom = name?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return number == 0 ? 'Térreo' : '$numberº andar';
  }
}

/// Sala (`GET /rooms/floor/:id`, `GET /rooms/:id`, `GET /rooms/:id/details`).
@freezed
abstract class Room with _$Room {
  const factory Room({
    required String id,
    required String floorId,
    required String name,
    @JsonKey(unknownEnumValue: RoomType.other)
    @Default(RoomType.other)
    RoomType type,
    Floor? floor,
    @Default(<Device>[]) List<Device> devices,
    @Default(0) int totalDevices,
    @Default(0) int activeDevices,
    @Default(0) double todayEnergyKwh,
  }) = _Room;

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);
}

/// Dispositivo (`GET /devices`, `GET /rooms/:id/details`, respostas de
/// controle). Potência, intensidade e temperatura vivem em [metadata].
@freezed
abstract class Device with _$Device {
  const Device._();

  const factory Device({
    required String id,
    required String name,
    required String roomId,
    @JsonKey(unknownEnumValue: DeviceType.other)
    @Default(DeviceType.other)
    DeviceType type,
    @JsonKey(unknownEnumValue: DeviceStatus.off)
    @Default(DeviceStatus.off)
    DeviceStatus status,

    /// Alcançável pelo broker MQTT. Offline = controle indisponível.
    @Default(false) bool online,

    /// Tópico MQTT base; comandos vão para `{mqttTopic}/command`.
    String? mqttTopic,
    Map<String, dynamic>? metadata,
    DateTime? lastSeen,
    Room? room,
  }) = _Device;

  factory Device.fromJson(Map<String, dynamic> json) => _$DeviceFromJson(json);

  bool get isOn => status == DeviceStatus.on;

  /// Brilho 0–100 (iluminação), se informado.
  int? get intensity => switch (metadata?['intensity']) {
    final num value => value.round().clamp(0, 100),
    _ => null,
  };

  /// Temperatura alvo em °C (ar-condicionado), se informada.
  double? get temperature => switch (metadata?['temperature']) {
    final num value => value.toDouble(),
    _ => null,
  };

  /// Potência nominal em watts (`power`/`powerRating` no metadata).
  double? get powerWatts =>
      switch (metadata?['power'] ?? metadata?['powerRating']) {
        final num value => value.toDouble(),
        _ => null,
      };

  /// "Sala · Andar · Prédio", quando a resposta trouxe a localização.
  String? get locationLabel {
    final room = this.room;
    if (room == null) return null;
    final floor = room.floor;
    return [
      room.name,
      if (floor != null) floor.displayName,
      if (floor?.building != null) floor!.building!.name,
    ].join(' · ');
  }
}
