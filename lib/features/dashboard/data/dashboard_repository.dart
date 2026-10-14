import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cache_providers.dart';
import '../../../core/cache/cached.dart';
import '../../../core/cache/local_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_providers.dart';
import '../../../shared/models/campus/campus_models.dart';
import '../domain/dashboard_models.dart';

abstract interface class DashboardRepository {
  /// Visão geral: prédios (com dispositivos), consumo de hoje e alertas.
  /// Cache primeiro; consumo e alertas são opcionais — se falharem, o
  /// dashboard abre com os prédios.
  Stream<Cached<DashboardOverview>> watchOverview();
}

class HttpDashboardRepository implements DashboardRepository {
  HttpDashboardRepository({required this._dio, required this._cache});

  static const String cacheKey = 'dashboard';

  final Dio _dio;
  final LocalCache _cache;

  @override
  Stream<Cached<DashboardOverview>> watchOverview() => cacheThenNetwork(
    cache: _cache,
    key: cacheKey,
    fetch: _fetch,
    parse: _parse,
  );

  Future<Object?> _fetch() async {
    final energy = _optional(
      _dio.getJson('/energy/stats', query: {'period': 'today'}),
    );
    final alerts = _optional(_dio.getJson('/notifications/me'));
    final buildings = await _dio.getJson('/buildings');
    return {
      'buildings': buildings,
      'energy': await energy,
      'alerts': await alerts,
    };
  }

  /// Falha de um bloco opcional vira `null` em vez de derrubar o dashboard.
  Future<Object?> _optional(Future<Object?> request) async {
    try {
      return await request;
    } on ApiException {
      return null;
    }
  }

  static DashboardOverview _parse(Object? json) => parseObject(json, (map) {
    final energy = map['energy'];
    final alerts = map['alerts'];
    return DashboardOverview(
      buildings: parseList(map['buildings'], Building.fromJson),
      energy: energy is Map<String, dynamic>
          ? EnergySummary.fromJson(energy)
          : null,
      alerts: alerts is List
          ? (parseList(alerts, DashboardAlert.fromJson)..sort(_newestFirst))
          : const [],
    );
  });

  static int _newestFirst(DashboardAlert a, DashboardAlert b) =>
      (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0));
}

final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => HttpDashboardRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(localCacheProvider),
  ),
  name: 'dashboardRepositoryProvider',
);
