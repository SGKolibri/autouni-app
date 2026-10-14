import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cache_providers.dart';
import '../../../core/cache/cached.dart';
import '../../../core/cache/local_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../shared/models/campus/campus_models.dart';

/// Hierarquia do campus: prédios → andares → salas. Cada leitura emite o
/// cache primeiro (abertura rápida/offline) e depois a resposta da rede.
abstract interface class EnvironmentsRepository {
  /// `GET /buildings` — prédios com a árvore e o consumo de hoje.
  Stream<Cached<List<Building>>> watchBuildings();

  /// `GET /buildings/:id` — só os dados do prédio (nome, local).
  Stream<Cached<Building>> watchBuilding(String buildingId);

  /// `GET /floors/building/:id` — andares com salas e dispositivos.
  Stream<Cached<List<Floor>>> watchFloors(String buildingId);

  /// `GET /floors/:id` — o andar com o prédio.
  Stream<Cached<Floor>> watchFloor(String floorId);

  /// `GET /rooms/floor/:id` — salas com dispositivos e consumo.
  Stream<Cached<List<Room>>> watchRooms(String floorId);

  /// `GET /rooms/:id/details` — a sala com andar, prédio, dispositivos e
  /// consumo de hoje.
  Stream<Cached<Room>> watchRoom(String roomId);
}

class HttpEnvironmentsRepository implements EnvironmentsRepository {
  HttpEnvironmentsRepository({required this._dio, required this._cache});

  final Dio _dio;
  final LocalCache _cache;

  Stream<Cached<T>> _watch<T>(String path, T Function(Object?) parse) =>
      cacheThenNetwork(
        cache: _cache,
        key: 'GET $path',
        fetch: () => _dio.getJson(path),
        parse: parse,
      );

  @override
  Stream<Cached<List<Building>>> watchBuildings() =>
      _watch('/buildings', (json) => parseList(json, Building.fromJson));

  @override
  Stream<Cached<Building>> watchBuilding(String buildingId) => _watch(
    '/buildings/$buildingId',
    (json) => parseObject(json, Building.fromJson),
  );

  @override
  Stream<Cached<List<Floor>>> watchFloors(String buildingId) => _watch(
    '/floors/building/$buildingId',
    (json) => parseList(json, Floor.fromJson),
  );

  @override
  Stream<Cached<Floor>> watchFloor(String floorId) =>
      _watch('/floors/$floorId', (json) => parseObject(json, Floor.fromJson));

  @override
  Stream<Cached<List<Room>>> watchRooms(String floorId) =>
      _watch('/rooms/floor/$floorId', (json) => parseList(json, Room.fromJson));

  @override
  Stream<Cached<Room>> watchRoom(String roomId) => _watch(
    '/rooms/$roomId/details',
    (json) => parseObject(json, Room.fromJson),
  );
}

final environmentsRepositoryProvider = Provider<EnvironmentsRepository>(
  (ref) => HttpEnvironmentsRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(localCacheProvider),
  ),
  name: 'environmentsRepositoryProvider',
);
