import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cache_providers.dart';
import '../../../core/cache/cached.dart';
import '../../../core/cache/local_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';
import '../domain/automation_models.dart';

/// CRUD, execução e histórico de automações (`/automations`).
abstract interface class AutomationsRepository {
  Stream<Cached<List<Automation>>> watchAll();

  Stream<Cached<Automation>> watchOne(String id);

  /// Execuções mais recentes primeiro.
  Stream<Cached<List<AutomationRun>>> watchHistory(String id);

  Future<Automation> create(AutomationDraft draft);

  Future<Automation> update(String id, AutomationDraft draft);

  Future<Automation> setEnabled(String id, {required bool enabled});

  /// Executa agora, fora do horário. O backend recusa automação desativada.
  Future<void> execute(String id);

  Future<void> delete(String id);
}

class HttpAutomationsRepository implements AutomationsRepository {
  HttpAutomationsRepository({required this._dio, required this._cache});

  /// Quantas execuções o histórico mostra.
  static const int historyLimit = 50;

  final Dio _dio;
  final LocalCache _cache;

  Stream<Cached<T>> _watch<T>(
    String path,
    T Function(Object?) parse, {
    Map<String, dynamic>? query,
  }) => cacheThenNetwork(
    cache: _cache,
    key: 'GET $path',
    fetch: () => _dio.getJson(path, query: query),
    parse: parse,
  );

  @override
  Stream<Cached<List<Automation>>> watchAll() =>
      _watch('/automations', (json) => parseList(json, Automation.fromJson));

  @override
  Stream<Cached<Automation>> watchOne(String id) => _watch(
    '/automations/$id',
    (json) => parseObject(json, Automation.fromJson),
  );

  @override
  Stream<Cached<List<AutomationRun>>> watchHistory(String id) => _watch(
    '/automations/$id/history',
    (json) => parseList(json, AutomationRun.fromJson),
    query: {'limit': historyLimit},
  );

  @override
  Future<Automation> create(AutomationDraft draft) async => parseObject(
    await _dio.postJson('/automations', data: draft.toJson()),
    Automation.fromJson,
  );

  @override
  Future<Automation> update(String id, AutomationDraft draft) async =>
      parseObject(
        await _dio.putJson('/automations/$id', data: draft.toJson()),
        Automation.fromJson,
      );

  @override
  Future<Automation> setEnabled(String id, {required bool enabled}) async =>
      parseObject(
        await _dio.patchJson(
          '/automations/$id/toggle',
          data: {'enabled': enabled},
        ),
        Automation.fromJson,
      );

  @override
  Future<void> execute(String id) => _dio.postJson('/automations/$id/execute');

  @override
  Future<void> delete(String id) => _dio.deleteJson('/automations/$id');
}

final automationsRepositoryProvider = Provider<AutomationsRepository>(
  (ref) => HttpAutomationsRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(localCacheProvider),
  ),
  name: 'automationsRepositoryProvider',
);
