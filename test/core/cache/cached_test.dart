import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/cache/local_cache.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final savedAt = DateTime.utc(2026, 10, 14, 8);
  late InMemoryLocalCache cache;

  setUp(() => cache = InMemoryLocalCache(now: () => savedAt));

  int parse(Object? json) => (json! as Map)['n'] as int;

  Stream<Cached<int>> load(Future<Object?> Function() fetch) =>
      cacheThenNetwork(cache: cache, key: 'k', fetch: fetch, parse: parse);

  test('sem cache: emite só o valor da rede e o grava', () async {
    final values = await load(() async => {'n': 2}).toList();

    expect(values.map((v) => (v.data, v.isStale)), [(2, false)]);
    expect((await cache.read('k'))?.data, {'n': 2});
  });

  test('com cache: emite o guardado primeiro e depois o da rede', () async {
    await cache.write('k', {'n': 1});

    final values = await load(() async => {'n': 2}).toList();

    expect(values.map((v) => (v.data, v.isStale, v.offline)), [
      (1, true, false),
      (2, false, false),
    ]);
    expect(values.first.savedAt, savedAt);
  });

  test(
    'sem rede e com cache: termina no valor guardado (leitura offline)',
    () async {
      await cache.write('k', {'n': 1});

      final values = await load(() async => throw const NetworkException())
          .toList();

      expect(values.map((v) => (v.data, v.isStale, v.offline)), [
        (1, true, false),
        (1, true, true),
      ]);
    },
  );

  test('sem rede e sem cache: o erro chega a quem escuta', () async {
    await expectLater(
      load(() async => throw const NetworkException()),
      emitsError(isA<NetworkException>()),
    );
  });

  test('cache ilegível é ignorado', () async {
    await cache.write('k', 'formato antigo');

    final values = await load(() async => {'n': 3}).toList();

    expect(values.map((v) => v.data), [3]);
  });
}
