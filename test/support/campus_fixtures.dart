import 'package:autouni_app/shared/models/campus/campus_enums.dart';
import 'package:autouni_app/shared/models/campus/campus_models.dart';

/// JSON de dispositivo no formato do backend.
Map<String, dynamic> deviceJson({
  String id = 'd1',
  String name = 'Luminária 1',
  String roomId = 'r1',
  String type = 'LIGHT',
  String status = 'OFF',
  bool online = true,
  Map<String, dynamic>? metadata,
  Map<String, dynamic>? room,
}) => {
  'id': id,
  'name': name,
  'roomId': roomId,
  'type': type,
  'status': status,
  'online': online,
  'metadata': ?metadata,
  'room': ?room,
};

/// Dispositivo de teste.
Device device({
  String id = 'd1',
  String name = 'Luminária 1',
  String roomId = 'r1',
  DeviceType type = DeviceType.light,
  DeviceStatus status = DeviceStatus.off,
  bool online = true,
  Map<String, dynamic>? metadata,
  Room? room,
}) => Device(
  id: id,
  name: name,
  roomId: roomId,
  type: type,
  status: status,
  online: online,
  metadata: metadata,
  room: room,
);

Map<String, dynamic> roomJson({
  String id = 'r1',
  String floorId = 'f1',
  String name = 'Sala 101',
  String type = 'CLASSROOM',
  List<Map<String, dynamic>> devices = const [],
  Map<String, dynamic>? floor,
  int totalDevices = 0,
  int activeDevices = 0,
  double todayEnergyKwh = 0,
}) => {
  'id': id,
  'floorId': floorId,
  'name': name,
  'type': type,
  'devices': devices,
  'floor': ?floor,
  'totalDevices': totalDevices,
  'activeDevices': activeDevices,
  'todayEnergyKwh': todayEnergyKwh,
};

Map<String, dynamic> floorJson({
  String id = 'f1',
  String buildingId = 'b1',
  int number = 1,
  String? name,
  List<Map<String, dynamic>> rooms = const [],
  Map<String, dynamic>? building,
  int totalDevices = 0,
  int activeDevices = 0,
}) => {
  'id': id,
  'buildingId': buildingId,
  'number': number,
  'name': name,
  'rooms': rooms,
  'building': ?building,
  'totalDevices': totalDevices,
  'activeDevices': activeDevices,
};

Map<String, dynamic> buildingJson({
  String id = 'b1',
  String name = 'Bloco A',
  String location = 'Campus I',
  List<Map<String, dynamic>> floors = const [],
  int totalDevices = 0,
  int activeDevices = 0,
  double todayEnergyKwh = 0,
}) => {
  'id': id,
  'name': name,
  'location': location,
  'floors': floors,
  'totalDevices': totalDevices,
  'activeDevices': activeDevices,
  'todayEnergyKwh': todayEnergyKwh,
};
