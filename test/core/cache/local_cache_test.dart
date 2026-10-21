import 'dart:io';

import 'package:autouni_app/core/cache/local_cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  final savedAt = DateTime.utc(2026, 10, 14, 9, 30);

  group('InMemoryLocalCache', () {
    test('grava, lê com a data e limpa', () async {
      final cache = InMemoryLocalCache(now: () => savedAt);

      expect(await cache.read('k'), isNull);
      await cache.write('k', {'a': 1});

      final entry = await cache.read('k');
      expect(entry?.data, {'a': 1});
      expect(entry?.savedAt, savedAt);

      await cache.clear();
      expect(await cache.read('k'), isNull);
    });
  });

  group('HiveLocalCache', () {
    late Directory dir;
    late Box<String> box;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('autouni_cache_test');
      Hive.init(dir.path);
      box = await Hive.openBox<String>(HiveLocalCache.boxName);
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('a entrada sobrevive a reabrir a box (restart do app)', () async {
      await HiveLocalCache(box, now: () => savedAt).write('buildings', [
        {'id': 'b1', 'name': 'Bloco A'},
      ]);
      await box.close();

      final reopened = HiveLocalCache(
        await Hive.openBox<String>(HiveLocalCache.boxName),
      );
      final entry = await reopened.read('buildings');

      expect(entry?.data, [
        {'id': 'b1', 'name': 'Bloco A'},
      ]);
      expect(entry?.savedAt, savedAt);
    });

    test('conteúdo corrompido é tratado como ausente', () async {
      await box.put('k', 'não é json');
      await box.put('sem-data', '{"data": 1}');

      final cache = HiveLocalCache(box);
      expect(await cache.read('k'), isNull);
      expect(await cache.read('sem-data'), isNull);
    });

    test('clear apaga todas as entradas', () async {
      final cache = HiveLocalCache(box);
      await cache.write('a', 1);
      await cache.write('b', 2);

      await cache.clear();

      expect(await cache.read('a'), isNull);
      expect(box.isEmpty, isTrue);
    });

    test('falhas da box (fechada) não vazam', () async {
      final cache = HiveLocalCache(box);
      await box.close();

      expect(await cache.read('a'), isNull);
      await cache.write('a', 1);
      await cache.clear();
    });
  });
}
