import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Quando o usuário tocou em "Agora não" no convite para ativar alertas,
/// neste aparelho. Vale entre contas e sobrevive ao logout.
abstract interface class PushPromptStore {
  Future<DateTime?> dismissedAt();

  /// `null` limpa.
  Future<void> setDismissedAt(DateTime? when);
}

/// Implementação volátil, usada em testes e como default do provider.
class InMemoryPushPromptStore implements PushPromptStore {
  DateTime? _dismissedAt;

  @override
  Future<DateTime?> dismissedAt() async => _dismissedAt;

  @override
  Future<void> setDismissedAt(DateTime? when) async => _dismissedAt = when;
}

/// Persistida no armazenamento seguro, que o app já usa (sem dependência
/// nova só para uma data).
class SecurePushPromptStore implements PushPromptStore {
  SecurePushPromptStore([this._storage = const FlutterSecureStorage()]);

  static const String dismissedAtKey = 'autouni.push.prompt_dismissed_at';

  final FlutterSecureStorage _storage;

  @override
  Future<DateTime?> dismissedAt() async {
    try {
      final raw = await _storage.read(key: dismissedAtKey);
      return raw == null ? null : DateTime.tryParse(raw);
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<void> setDismissedAt(DateTime? when) => when == null
      ? _storage.delete(key: dismissedAtKey)
      : _storage.write(
          key: dismissedAtKey,
          value: when.toUtc().toIso8601String(),
        );
}

/// Default volátil; o bootstrap sobrescreve com o [SecurePushPromptStore].
final pushPromptStoreProvider = Provider<PushPromptStore>(
  (ref) => InMemoryPushPromptStore(),
  name: 'pushPromptStoreProvider',
);
