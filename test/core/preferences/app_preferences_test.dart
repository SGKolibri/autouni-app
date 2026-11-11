import 'dart:io';

import 'package:autouni_app/core/preferences/app_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  group('AppPreferences', () {
    test('padrão: tema do sistema e push ligado', () {
      const prefs = AppPreferences();
      expect(prefs.themeMode, ThemeMode.system);
      expect(prefs.pushEnabled, isTrue);
    });

    test('JSON de ida e volta', () {
      const prefs = AppPreferences(
        themeMode: ThemeMode.dark,
        pushEnabled: false,
      );
      expect(AppPreferences.fromJson(prefs.toJson()), prefs);
    });

    test('JSON ilegível cai no padrão campo a campo', () {
      expect(
        AppPreferences.fromJson(const {'themeMode': 'neon', 'pushEnabled': 1}),
        const AppPreferences(),
      );
    });
  });

  group('HivePreferencesStore (preferências persistem — S6-T5)', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('autouni_prefs_test');
      Hive.init(dir.path);
    });

    tearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });

    test('sobrevivem a fechar e reabrir o app', () async {
      final store = await HivePreferencesStore.open();
      await store.save(
        const AppPreferences(themeMode: ThemeMode.light, pushEnabled: false),
      );
      await Hive.close();

      final reopened = await HivePreferencesStore.open();

      expect(
        reopened.load(),
        const AppPreferences(themeMode: ThemeMode.light, pushEnabled: false),
      );
    });

    test('caixa vazia ou corrompida dá o padrão', () async {
      final box = await Hive.openBox<String>(HivePreferencesStore.boxName);
      final store = HivePreferencesStore(box);
      expect(store.load(), const AppPreferences());

      await box.put(HivePreferencesStore.key, 'lixo');
      expect(store.load(), const AppPreferences());
    });

    test('caixa fechada não derruba quem grava', () async {
      final store = await HivePreferencesStore.open();
      await Hive.close();

      await store.save(const AppPreferences(themeMode: ThemeMode.dark));
      expect(store.load(), const AppPreferences());
    });
  });

  group('appPreferencesProvider', () {
    test('lê do store e grava cada mudança', () async {
      final store = InMemoryPreferencesStore(
        const AppPreferences(themeMode: ThemeMode.dark),
      );
      final container = ProviderContainer.test(
        overrides: [preferencesStoreProvider.overrideWithValue(store)],
      );

      expect(container.read(appPreferencesProvider).themeMode, ThemeMode.dark);

      await container
          .read(appPreferencesProvider.notifier)
          .setThemeMode(ThemeMode.light);
      await container
          .read(appPreferencesProvider.notifier)
          .setPushEnabled(false);

      expect(
        store.load(),
        const AppPreferences(themeMode: ThemeMode.light, pushEnabled: false),
      );
      expect(
        container.read(appPreferencesProvider),
        const AppPreferences(themeMode: ThemeMode.light, pushEnabled: false),
      );
    });
  });
}
