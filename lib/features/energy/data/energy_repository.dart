import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cache_providers.dart';
import '../../../core/cache/cached.dart';
import '../../../core/cache/local_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_providers.dart';
import '../domain/energy_models.dart';

abstract interface class EnergyRepository {
  /// KPIs, histórico e ranking de [scope] em [period]. Cache primeiro; o
  /// ranking é opcional — se falhar, a tela abre sem ele.
  Stream<Cached<EnergyOverview>> watchOverview(
    EnergyScope scope,
    EnergyPeriod period,
  );
}

class HttpEnergyRepository implements EnergyRepository {
  HttpEnergyRepository({
    required this._dio,
    required this._cache,
    this._now = DateTime.now,
  });

  final Dio _dio;
  final LocalCache _cache;
  final DateTime Function() _now;

  @override
  Stream<Cached<EnergyOverview>> watchOverview(
    EnergyScope scope,
    EnergyPeriod period,
  ) => cacheThenNetwork(
    cache: _cache,
    key: 'energy:${scope.level.apiValue}:${scope.id ?? '-'}:${period.apiValue}',
    fetch: () => _fetch(scope, period),
    parse: (json) => _parse(json, scope, period),
  );

  Future<Object?> _fetch(EnergyScope scope, EnergyPeriod period) async {
    final scoped = {
      'period': period.apiValue,
      'level': scope.level.apiValue,
      'id': ?scope.id,
    };
    final ranking = scope.level.child == null
        ? Future<Object?>.value()
        : _optional(_dio.getJson('/energy/comparison', query: scoped));
    // Future.wait trata o erro das duas: nenhuma falha fica sem dono.
    final required = await Future.wait([
      _fetchStats(scope, period),
      _dio.getJson('/energy/history', query: scoped),
    ]);
    return {
      'stats': required[0],
      'history': required[1],
      'ranking': await ranking,
    };
  }

  /// O campus aceita `period`; as rotas por nível só aceitam `from`/`to`.
  Future<Object?> _fetchStats(EnergyScope scope, EnergyPeriod period) {
    final segment = switch (scope.level) {
      EnergyLevel.general => null,
      EnergyLevel.building => 'buildings',
      EnergyLevel.floor => 'floors',
      EnergyLevel.room => 'rooms',
      EnergyLevel.device => 'devices',
    };
    if (segment == null) {
      return _dio.getJson('/energy/stats', query: {'period': period.apiValue});
    }
    final now = _now();
    return _dio.getJson(
      '/energy/$segment/${scope.id}/stats',
      query: {
        'from': period.startOf(now).toUtc().toIso8601String(),
        'to': now.toUtc().toIso8601String(),
      },
    );
  }

  Future<Object?> _optional(Future<Object?> request) async {
    try {
      return await request;
    } on ApiException {
      return null;
    }
  }

  static EnergyOverview _parse(
    Object? json,
    EnergyScope scope,
    EnergyPeriod period,
  ) => parseObject(json, (map) {
    final history = map['history'];
    final ranking = map['ranking'];
    return EnergyOverview(
      scope: scope,
      period: period,
      stats: parseObject(map['stats'], EnergyStats.fromJson),
      history: parseList(
        history is Map ? history['history'] : null,
        EnergyHistoryPoint.fromJson,
      ),
      ranking: ranking is Map && ranking['comparison'] is List
          ? parseList(ranking['comparison'], EnergyRankingItem.fromJson)
          : null,
    );
  });
}

final energyRepositoryProvider = Provider<EnergyRepository>(
  (ref) => HttpEnergyRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(localCacheProvider),
  ),
  name: 'energyRepositoryProvider',
);
