import '../network/api_exception.dart';
import 'local_cache.dart';

/// Um valor e sua origem: da rede agora ([savedAt] nulo) ou do cache local.
class Cached<T> {
  const Cached(this.data, {this.savedAt, this.offline = false});

  final T data;

  /// Quando o valor foi gravado no cache; `null` se acabou de vir da rede.
  final DateTime? savedAt;

  /// A rede falhou e este é o valor guardado (modo offline). Enquanto a
  /// rede ainda está respondendo, um valor do cache tem `offline: false`.
  final bool offline;

  /// O valor veio do cache (pode estar desatualizado).
  bool get isStale => savedAt != null;
}

/// Lê [key] do cache e depois da rede:
///
/// 1. se houver cache, emite o valor guardado (abertura rápida);
/// 2. busca na rede, grava o JSON no cache e emite o valor novo;
/// 3. se a rede falhar e havia cache, reemite o cache marcado `offline`;
///    sem cache, o erro (`ApiException`) segue para quem escuta.
///
/// Cache ilegível (formato antigo, por exemplo) é ignorado.
Stream<Cached<T>> cacheThenNetwork<T>({
  required LocalCache cache,
  required String key,
  required Future<Object?> Function() fetch,
  required T Function(Object? json) parse,
}) async* {
  Cached<T>? fromCache;
  final entry = await cache.read(key);
  if (entry != null) {
    try {
      fromCache = Cached(parse(entry.data), savedAt: entry.savedAt);
    } on Object {
      fromCache = null;
    }
    if (fromCache != null) yield fromCache;
  }

  final Object? json;
  try {
    json = await fetch();
  } on ApiException {
    if (fromCache == null) rethrow;
    yield Cached(fromCache.data, savedAt: fromCache.savedAt, offline: true);
    return;
  }
  final fresh = parse(json);
  await cache.write(key, json);
  yield Cached(fresh);
}
