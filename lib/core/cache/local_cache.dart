import 'dart:convert';

import 'package:hive_ce/hive_ce.dart';

/// Uma entrada do cache: o JSON guardado e quando foi gravado.
class CacheEntry {
  const CacheEntry({required this.data, required this.savedAt});

  final Object? data;
  final DateTime savedAt;
}

/// Cache local do último estado conhecido (abertura rápida e uso offline).
///
/// Guarda o JSON cru das respostas da API, não os modelos: assim o cache não
/// precisa de adapters e sempre passa pelo mesmo parse da rede. É
/// best-effort — falhas de disco nunca chegam a quem chama.
abstract interface class LocalCache {
  Future<CacheEntry?> read(String key);
  Future<void> write(String key, Object? data);

  /// Apaga tudo (logout: o cache tem dados do usuário).
  Future<void> clear();
}

/// Implementação volátil, usada em testes e como default do provider.
class InMemoryLocalCache implements LocalCache {
  InMemoryLocalCache({this._now = DateTime.now});

  final DateTime Function() _now;
  final Map<String, CacheEntry> _entries = {};

  @override
  Future<CacheEntry?> read(String key) async => _entries[key];

  @override
  Future<void> write(String key, Object? data) async {
    _entries[key] = CacheEntry(data: data, savedAt: _now());
  }

  @override
  Future<void> clear() async => _entries.clear();
}

/// Implementação persistida em uma box do Hive (`hive_ce`), com cada entrada
/// serializada como `{"savedAt": ..., "data": ...}`.
class HiveLocalCache implements LocalCache {
  HiveLocalCache(this._box, {this._now = DateTime.now});

  static const String boxName = 'autouni_cache';

  /// Abre a box do cache. Chame depois de `Hive.initFlutter()`.
  static Future<HiveLocalCache> open() async =>
      HiveLocalCache(await Hive.openBox<String>(boxName));

  final Box<String> _box;
  final DateTime Function() _now;

  @override
  Future<CacheEntry?> read(String key) async {
    try {
      final raw = _box.get(key);
      if (raw == null) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final savedAt = DateTime.tryParse('${decoded['savedAt']}');
      if (savedAt == null) return null;
      return CacheEntry(data: decoded['data'], savedAt: savedAt);
    } on Object {
      return null;
    }
  }

  @override
  Future<void> write(String key, Object? data) async {
    try {
      await _box.put(
        key,
        jsonEncode({'savedAt': _now().toIso8601String(), 'data': data}),
      );
    } on Object {
      // Sem cache desta vez; a resposta da rede segue valendo.
    }
  }

  @override
  Future<void> clear() async {
    try {
      await _box.clear();
    } on Object {
      // Nada a fazer.
    }
  }
}
