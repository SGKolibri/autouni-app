import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive_ce.dart';

/// Preferências deste aparelho (valem para qualquer conta).
@immutable
class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.system,
    this.pushEnabled = true,
  });

  factory AppPreferences.fromJson(Map<String, dynamic> json) {
    final theme = json['themeMode'];
    final push = json['pushEnabled'];
    return AppPreferences(
      themeMode: ThemeMode.values.firstWhere(
        (mode) => mode.name == theme,
        orElse: () => ThemeMode.system,
      ),
      pushEnabled: push is bool ? push : true,
    );
  }

  final ThemeMode themeMode;

  /// O usuário quer receber alertas por push neste aparelho. Desligado, o
  /// app não registra o token (e remove o que houver).
  final bool pushEnabled;

  AppPreferences copyWith({ThemeMode? themeMode, bool? pushEnabled}) =>
      AppPreferences(
        themeMode: themeMode ?? this.themeMode,
        pushEnabled: pushEnabled ?? this.pushEnabled,
      );

  Map<String, dynamic> toJson() => {
    'themeMode': themeMode.name,
    'pushEnabled': pushEnabled,
  };

  @override
  bool operator ==(Object other) =>
      other is AppPreferences &&
      other.themeMode == themeMode &&
      other.pushEnabled == pushEnabled;

  @override
  int get hashCode => Object.hash(themeMode, pushEnabled);
}

/// Onde as preferências ficam. [load] é síncrono: o tema precisa estar
/// pronto no primeiro frame.
abstract interface class PreferencesStore {
  AppPreferences load();
  Future<void> save(AppPreferences preferences);
}

/// Implementação volátil, usada em testes e como default do provider.
class InMemoryPreferencesStore implements PreferencesStore {
  InMemoryPreferencesStore([this._preferences = const AppPreferences()]);

  AppPreferences _preferences;

  @override
  AppPreferences load() => _preferences;

  @override
  Future<void> save(AppPreferences preferences) async =>
      _preferences = preferences;
}

/// Persistida numa box do Hive aberta no bootstrap. Conteúdo ilegível vira
/// o padrão; falha ao gravar não derruba a tela (vale até fechar o app).
class HivePreferencesStore implements PreferencesStore {
  HivePreferencesStore(this._box);

  static const String boxName = 'autouni_preferences';
  static const String key = 'app';

  static Future<HivePreferencesStore> open() async =>
      HivePreferencesStore(await Hive.openBox<String>(boxName));

  final Box<String> _box;

  @override
  AppPreferences load() {
    try {
      final raw = _box.get(key);
      if (raw == null) return const AppPreferences();
      final json = jsonDecode(raw);
      return json is Map<String, dynamic>
          ? AppPreferences.fromJson(json)
          : const AppPreferences();
    } on Object {
      return const AppPreferences();
    }
  }

  @override
  Future<void> save(AppPreferences preferences) async {
    try {
      await _box.put(key, jsonEncode(preferences.toJson()));
    } on Object {
      // Fica só em memória até o app fechar.
    }
  }
}

/// Default volátil; o bootstrap sobrescreve com o [HivePreferencesStore].
final preferencesStoreProvider = Provider<PreferencesStore>(
  (ref) => InMemoryPreferencesStore(),
  name: 'preferencesStoreProvider',
);

class AppPreferencesNotifier extends Notifier<AppPreferences> {
  @override
  AppPreferences build() => ref.watch(preferencesStoreProvider).load();

  Future<void> setThemeMode(ThemeMode mode) =>
      _set(state.copyWith(themeMode: mode));

  Future<void> setPushEnabled(bool enabled) =>
      _set(state.copyWith(pushEnabled: enabled));

  Future<void> _set(AppPreferences next) async {
    if (next == state) return;
    state = next;
    await ref.read(preferencesStoreProvider).save(next);
  }
}

final appPreferencesProvider =
    NotifierProvider<AppPreferencesNotifier, AppPreferences>(
      AppPreferencesNotifier.new,
      name: 'appPreferencesProvider',
    );
