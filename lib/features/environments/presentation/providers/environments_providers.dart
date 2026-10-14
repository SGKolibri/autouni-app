import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/cached.dart';
import '../../../../shared/devices/device_counts.dart';
import '../../../../shared/devices/device_live_state.dart';
import '../../../../shared/models/campus/campus_models.dart';
import '../../data/environments_repository.dart';

/// Prédios (raiz da aba Ambientes).
final buildingsProvider = StreamProvider.autoDispose<Cached<List<Building>>>(
  (ref) => reconcileLiveDevices(
    ref,
    ref.watch(environmentsRepositoryProvider).watchBuildings(),
    (buildings) => buildings.expand((building) => building.allDevices),
  ),
  name: 'buildingsProvider',
);

/// Dados do prédio (título e breadcrumb).
final buildingProvider = StreamProvider.autoDispose
    .family<Cached<Building>, String>(
      (ref, buildingId) =>
          ref.watch(environmentsRepositoryProvider).watchBuilding(buildingId),
      name: 'buildingProvider',
    );

/// Andares de um prédio.
final floorsProvider = StreamProvider.autoDispose
    .family<Cached<List<Floor>>, String>(
      (ref, buildingId) => reconcileLiveDevices(
        ref,
        ref.watch(environmentsRepositoryProvider).watchFloors(buildingId),
        (floors) => floors.expand((floor) => floor.allDevices),
      ),
      name: 'floorsProvider',
    );

/// Dados do andar, com o prédio (título e breadcrumb).
final floorProvider = StreamProvider.autoDispose.family<Cached<Floor>, String>(
  (ref, floorId) =>
      ref.watch(environmentsRepositoryProvider).watchFloor(floorId),
  name: 'floorProvider',
);

/// Salas de um andar.
final roomsProvider = StreamProvider.autoDispose
    .family<Cached<List<Room>>, String>(
      (ref, floorId) => reconcileLiveDevices(
        ref,
        ref.watch(environmentsRepositoryProvider).watchRooms(floorId),
        (rooms) => rooms.expand((room) => room.devices),
      ),
      name: 'roomsProvider',
    );

/// Sala com dispositivos, andar e prédio (detalhe da sala).
final roomDetailsProvider = StreamProvider.autoDispose
    .family<Cached<Room>, String>(
      (ref, roomId) => reconcileLiveDevices(
        ref,
        ref.watch(environmentsRepositoryProvider).watchRoom(roomId),
        (room) => room.devices,
      ),
      name: 'roomDetailsProvider',
    );
