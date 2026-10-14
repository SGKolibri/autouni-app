import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'local_cache.dart';

/// Cache local do último estado.
///
/// Default volátil, seguro para testes; o bootstrap sobrescreve com o
/// [HiveLocalCache] já aberto.
final localCacheProvider = Provider<LocalCache>(
  (ref) => InMemoryLocalCache(),
  name: 'localCacheProvider',
);
