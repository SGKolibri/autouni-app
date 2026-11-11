import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/cache/cache_providers.dart';
import '../../../core/cache/cached.dart';
import '../../../core/cache/local_cache.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/network_providers.dart';
import '../../../core/session/session_hooks.dart';
import '../../../shared/models/campus/campus_models.dart';
import '../domain/report_models.dart';
import '../domain/report_request.dart';

/// Relatórios do usuário logado.
///
/// `GET /reports/me` do backend passa o payload do JWT inteiro como id do
/// criador e responde 500; a lista vem de `GET /reports/creator/:userId`.
abstract interface class ReportsRepository {
  /// Mais recentes primeiro. Cache primeiro.
  Stream<Cached<List<Report>>> watchMine();

  /// Só a rede (acompanhar a geração), gravando o cache.
  Future<List<Report>> fetchMine();

  /// `GET /reports/:id`.
  Future<Report> fetch(String id);

  /// `POST /reports`: entra na fila como `PENDING`.
  Future<Report> create(ReportRequest request);

  /// Prédios para o filtro de localização (`GET /buildings`, cacheado).
  Future<List<Building>> buildings();

  /// `GET /reports/:id/download` (só `COMPLETED`).
  Future<DownloadedFile> download(String id);
}

class HttpReportsRepository implements ReportsRepository {
  HttpReportsRepository({
    required this._dio,
    required this._cache,
    required this._userId,
  });

  static String cacheKeyFor(String userId) => 'reports:creator:$userId';

  /// A mesma chave da aba Ambientes: um prédio carregado lá já serve aqui.
  static const String buildingsCacheKey = 'GET /buildings';

  final Dio _dio;
  final LocalCache _cache;
  final String? _userId;

  String get _requireUser =>
      _userId ??
      (throw const UnauthorizedException(
        message: 'Sessão expirada. Entre novamente.',
      ));

  @override
  Stream<Cached<List<Report>>> watchMine() {
    final userId = _userId;
    if (userId == null) return Stream.value(const Cached(<Report>[]));
    return cacheThenNetwork(
      cache: _cache,
      key: cacheKeyFor(userId),
      fetch: () => _dio.getJson('/reports/creator/$userId'),
      parse: _parseList,
    );
  }

  @override
  Future<List<Report>> fetchMine() async {
    final userId = _requireUser;
    final json = await _dio.getJson('/reports/creator/$userId');
    final reports = _parseList(json);
    await _cache.write(cacheKeyFor(userId), json);
    return reports;
  }

  @override
  Future<Report> fetch(String id) async =>
      parseObject(await _dio.getJson('/reports/$id'), Report.fromJson);

  @override
  Future<Report> create(ReportRequest request) async => parseObject(
    await _dio.postJson(
      '/reports',
      data: request.toJson(createdById: _requireUser),
    ),
    Report.fromJson,
  );

  @override
  Future<List<Building>> buildings() async {
    final values = await cacheThenNetwork(
      cache: _cache,
      key: buildingsCacheKey,
      fetch: () => _dio.getJson('/buildings'),
      parse: (json) => parseList(json, Building.fromJson),
    ).toList();
    final buildings = [...values.last.data]
      ..sort((a, b) => a.name.compareTo(b.name));
    return buildings;
  }

  @override
  Future<DownloadedFile> download(String id) =>
      _dio.getBytes('/reports/$id/download');

  static List<Report> _parseList(Object? json) =>
      parseList(json, Report.fromJson)..sort(
        (a, b) =>
            (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)),
      );
}

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => HttpReportsRepository(
    dio: ref.watch(dioProvider),
    cache: ref.watch(localCacheProvider),
    userId: ref.watch(sessionUserIdProvider),
  ),
  name: 'reportsRepositoryProvider',
);
