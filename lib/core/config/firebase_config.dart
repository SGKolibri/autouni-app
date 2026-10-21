import 'package:flutter/foundation.dart';

/// Credenciais públicas do app no Firebase (push via FCM), vindas de
/// `--dart-define` — nada versionado no repositório.
///
/// Sem config completa o push fica desligado e o resto do app segue igual.
@immutable
class FirebaseConfig {
  const FirebaseConfig({
    required this.apiKey,
    required this.projectId,
    required this.messagingSenderId,
    this.androidAppId,
    this.iosAppId,
    this.iosBundleId,
  });

  /// Lê os defines (`FIREBASE_*`). Valores vazios contam como ausentes;
  /// devolve `null` se faltar algo comum ou não houver nenhum app id.
  static FirebaseConfig? fromDefines({
    required String apiKey,
    required String projectId,
    required String messagingSenderId,
    required String androidAppId,
    required String iosAppId,
    required String iosBundleId,
  }) {
    String? clean(String value) {
      final trimmed = value.trim();
      return trimmed.isEmpty ? null : trimmed;
    }

    final key = clean(apiKey);
    final project = clean(projectId);
    final sender = clean(messagingSenderId);
    final android = clean(androidAppId);
    final ios = clean(iosAppId);
    if (key == null || project == null || sender == null) return null;
    if (android == null && ios == null) return null;
    return FirebaseConfig(
      apiKey: key,
      projectId: project,
      messagingSenderId: sender,
      androidAppId: android,
      iosAppId: ios,
      iosBundleId: clean(iosBundleId),
    );
  }

  final String apiKey;
  final String projectId;
  final String messagingSenderId;
  final String? androidAppId;
  final String? iosAppId;
  final String? iosBundleId;

  /// App id da [platform]; `null` onde não há app registrado.
  String? appIdFor(TargetPlatform platform) => switch (platform) {
    TargetPlatform.android => androidAppId,
    TargetPlatform.iOS => iosAppId,
    _ => null,
  };

  @override
  bool operator ==(Object other) =>
      other is FirebaseConfig &&
      other.apiKey == apiKey &&
      other.projectId == projectId &&
      other.messagingSenderId == messagingSenderId &&
      other.androidAppId == androidAppId &&
      other.iosAppId == iosAppId &&
      other.iosBundleId == iosBundleId;

  @override
  int get hashCode => Object.hash(
    apiKey,
    projectId,
    messagingSenderId,
    androidAppId,
    iosAppId,
    iosBundleId,
  );
}
