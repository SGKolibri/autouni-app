import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cache/cache_providers.dart';
import '../../core/cache/cached.dart';
import '../../core/cache/local_cache.dart';
import '../../core/network/api_client.dart';
import '../../core/network/network_providers.dart';
import '../models/campus/campus_models.dart';
import 'device_commands.dart';

/// Acesso aos dispositivos: lista global e comandos.
abstract interface class DeviceRepository {
  /// `GET /devices` (com a localização de cada um), cache primeiro.
  Stream<Cached<List<Device>>> watchAll();

  /// `POST /devices/:id/control`. [intensity] (0–100) e [temperature] (°C)
  /// seguem no payload MQTT quando presentes.
  Future<ControlResult> control(
    String deviceId, {
    required DeviceCommand command,
    int? intensity,
    double? temperature,
  });

  /// `POST /devices/bulk-control`.
  Future<BulkControlResult> bulkControl(
    List<String> deviceIds, {
    required DeviceCommand command,
  });
}

class HttpDeviceRepository implements DeviceRepository {
  HttpDeviceRepository({required this._dio, required this._cache});

  static const String allDevicesCacheKey = 'devices';

  final Dio _dio;
  final LocalCache _cache;

  @override
  Stream<Cached<List<Device>>> watchAll() => cacheThenNetwork(
    cache: _cache,
    key: allDevicesCacheKey,
    fetch: () => _dio.getJson('/devices'),
    parse: (json) => parseList(json, Device.fromJson),
  );

  @override
  Future<ControlResult> control(
    String deviceId, {
    required DeviceCommand command,
    int? intensity,
    double? temperature,
  }) async {
    final json = await _dio.postJson(
      '/devices/$deviceId/control',
      data: {
        'command': command.apiValue,
        'intensity': ?intensity,
        'temperature': ?temperature,
      },
    );
    return parseObject(
      json,
      (map) => ControlResult(
        device: Device.fromJson(map),
        pending: map['pending'] == true,
      ),
    );
  }

  @override
  Future<BulkControlResult> bulkControl(
    List<String> deviceIds, {
    required DeviceCommand command,
  }) async {
    final json = await _dio.postJson(
      '/devices/bulk-control',
      data: {'deviceIds': deviceIds, 'command': command.apiValue},
    );
    return parseObject(json, BulkControlResult.fromJson);
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>(
  (ref) => HttpDeviceRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(localCacheProvider),
  ),
  name: 'deviceRepositoryProvider',
);
