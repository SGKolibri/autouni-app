// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'campus_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Building _$BuildingFromJson(Map<String, dynamic> json) => _Building(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  location: json['location'] as String? ?? '',
  floors:
      (json['floors'] as List<dynamic>?)
          ?.map((e) => Floor.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Floor>[],
  totalDevices: (json['totalDevices'] as num?)?.toInt() ?? 0,
  activeDevices: (json['activeDevices'] as num?)?.toInt() ?? 0,
  todayEnergyKwh: (json['todayEnergyKwh'] as num?)?.toDouble() ?? 0,
  lastReadingAt: json['lastReadingAt'] == null
      ? null
      : DateTime.parse(json['lastReadingAt'] as String),
);

Map<String, dynamic> _$BuildingToJson(_Building instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'location': instance.location,
  'floors': instance.floors,
  'totalDevices': instance.totalDevices,
  'activeDevices': instance.activeDevices,
  'todayEnergyKwh': instance.todayEnergyKwh,
  'lastReadingAt': instance.lastReadingAt?.toIso8601String(),
};

_Floor _$FloorFromJson(Map<String, dynamic> json) => _Floor(
  id: json['id'] as String,
  buildingId: json['buildingId'] as String,
  number: (json['number'] as num).toInt(),
  name: json['name'] as String?,
  building: json['building'] == null
      ? null
      : Building.fromJson(json['building'] as Map<String, dynamic>),
  rooms:
      (json['rooms'] as List<dynamic>?)
          ?.map((e) => Room.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Room>[],
  totalDevices: (json['totalDevices'] as num?)?.toInt() ?? 0,
  activeDevices: (json['activeDevices'] as num?)?.toInt() ?? 0,
  todayEnergyKwh: (json['todayEnergyKwh'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$FloorToJson(_Floor instance) => <String, dynamic>{
  'id': instance.id,
  'buildingId': instance.buildingId,
  'number': instance.number,
  'name': instance.name,
  'building': instance.building,
  'rooms': instance.rooms,
  'totalDevices': instance.totalDevices,
  'activeDevices': instance.activeDevices,
  'todayEnergyKwh': instance.todayEnergyKwh,
};

_Room _$RoomFromJson(Map<String, dynamic> json) => _Room(
  id: json['id'] as String,
  floorId: json['floorId'] as String,
  name: json['name'] as String,
  type:
      $enumDecodeNullable(
        _$RoomTypeEnumMap,
        json['type'],
        unknownValue: RoomType.other,
      ) ??
      RoomType.other,
  floor: json['floor'] == null
      ? null
      : Floor.fromJson(json['floor'] as Map<String, dynamic>),
  devices:
      (json['devices'] as List<dynamic>?)
          ?.map((e) => Device.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <Device>[],
  totalDevices: (json['totalDevices'] as num?)?.toInt() ?? 0,
  activeDevices: (json['activeDevices'] as num?)?.toInt() ?? 0,
  todayEnergyKwh: (json['todayEnergyKwh'] as num?)?.toDouble() ?? 0,
);

Map<String, dynamic> _$RoomToJson(_Room instance) => <String, dynamic>{
  'id': instance.id,
  'floorId': instance.floorId,
  'name': instance.name,
  'type': _$RoomTypeEnumMap[instance.type]!,
  'floor': instance.floor,
  'devices': instance.devices,
  'totalDevices': instance.totalDevices,
  'activeDevices': instance.activeDevices,
  'todayEnergyKwh': instance.todayEnergyKwh,
};

const _$RoomTypeEnumMap = {
  RoomType.classroom: 'CLASSROOM',
  RoomType.lab: 'LAB',
  RoomType.office: 'OFFICE',
  RoomType.auditorium: 'AUDITORIUM',
  RoomType.library: 'LIBRARY',
  RoomType.other: 'OTHER',
};

_Device _$DeviceFromJson(Map<String, dynamic> json) => _Device(
  id: json['id'] as String,
  name: json['name'] as String,
  roomId: json['roomId'] as String,
  type:
      $enumDecodeNullable(
        _$DeviceTypeEnumMap,
        json['type'],
        unknownValue: DeviceType.other,
      ) ??
      DeviceType.other,
  status:
      $enumDecodeNullable(
        _$DeviceStatusEnumMap,
        json['status'],
        unknownValue: DeviceStatus.off,
      ) ??
      DeviceStatus.off,
  online: json['online'] as bool? ?? false,
  mqttTopic: json['mqttTopic'] as String?,
  metadata: json['metadata'] as Map<String, dynamic>?,
  lastSeen: json['lastSeen'] == null
      ? null
      : DateTime.parse(json['lastSeen'] as String),
  room: json['room'] == null
      ? null
      : Room.fromJson(json['room'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DeviceToJson(_Device instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'roomId': instance.roomId,
  'type': _$DeviceTypeEnumMap[instance.type]!,
  'status': _$DeviceStatusEnumMap[instance.status]!,
  'online': instance.online,
  'mqttTopic': instance.mqttTopic,
  'metadata': instance.metadata,
  'lastSeen': instance.lastSeen?.toIso8601String(),
  'room': instance.room,
};

const _$DeviceTypeEnumMap = {
  DeviceType.light: 'LIGHT',
  DeviceType.ac: 'AC',
  DeviceType.projector: 'PROJECTOR',
  DeviceType.speaker: 'SPEAKER',
  DeviceType.lock: 'LOCK',
  DeviceType.sensor: 'SENSOR',
  DeviceType.other: 'OTHER',
};

const _$DeviceStatusEnumMap = {
  DeviceStatus.on: 'ON',
  DeviceStatus.off: 'OFF',
  DeviceStatus.standby: 'STANDBY',
  DeviceStatus.error: 'ERROR',
};
