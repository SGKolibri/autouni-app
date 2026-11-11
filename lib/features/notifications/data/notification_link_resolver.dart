import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/router/app_paths.dart';
import '../../../shared/models/campus/campus_models.dart';
import '../domain/notification_link.dart';

/// Traduz o `link` de uma notificação para um caminho do app.
abstract interface class NotificationLinkResolver {
  /// `null` quando o destino ainda não abre no app. Erros da API (ex.:
  /// dispositivo apagado) chegam como `ApiException`.
  Future<String?> resolve(String link);
}

class HttpNotificationLinkResolver implements NotificationLinkResolver {
  HttpNotificationLinkResolver(this._dio);

  final Dio _dio;

  @override
  Future<String?> resolve(String link) async => switch (classifyLink(link)) {
    LinkLocation(:final location) => location,
    LinkUnsupported() => null,
    LinkLookup(entity: LinkEntity.device, :final id) => _device(id),
    LinkLookup(entity: LinkEntity.room, :final id) => _room(id),
    LinkLookup(entity: LinkEntity.floor, :final id) => _floor(id),
  };

  /// A sala do dispositivo, com a ficha dele aberta.
  Future<String?> _device(String id) async {
    final device = parseObject(
      await _dio.getJson('/devices/$id'),
      Device.fromJson,
    );
    final floor = device.room?.floor;
    if (floor == null) return null;
    return AppPaths.room(
      floor.buildingId,
      floor.id,
      device.roomId,
      deviceId: device.id,
    );
  }

  Future<String?> _room(String id) async {
    final room = parseObject(
      await _dio.getJson('/rooms/$id/details'),
      Room.fromJson,
    );
    final floor = room.floor;
    if (floor == null) return null;
    return AppPaths.room(floor.buildingId, room.floorId, room.id);
  }

  Future<String?> _floor(String id) async {
    final floor = parseObject(
      await _dio.getJson('/floors/$id'),
      Floor.fromJson,
    );
    return AppPaths.floor(floor.buildingId, floor.id);
  }
}

final notificationLinkResolverProvider = Provider<NotificationLinkResolver>(
  (ref) => HttpNotificationLinkResolver(ref.watch(dioProvider)),
  name: 'notificationLinkResolverProvider',
);
