import 'package:flutter/foundation.dart';

/// Situação da permissão de notificações no sistema.
enum PushPermission {
  granted,

  /// Recusada. No Android 13+ o sistema ainda pode perguntar de novo.
  denied,

  /// O sistema ainda não perguntou.
  notDetermined,
}

/// Plataforma do aparelho, como o backend espera em `POST /push/tokens`.
enum PushPlatform {
  android('ANDROID'),
  ios('IOS'),
  web('WEB');

  const PushPlatform(this.apiValue);

  final String apiValue;

  /// `null` em plataformas sem push (desktop).
  static PushPlatform? of(TargetPlatform platform, {bool isWeb = false}) {
    if (isWeb) return web;
    return switch (platform) {
      TargetPlatform.android => android,
      TargetPlatform.iOS => ios,
      _ => null,
    };
  }

  /// A plataforma em que o app está rodando.
  static PushPlatform? get current => of(defaultTargetPlatform, isWeb: kIsWeb);
}

/// O plugin de push (FCM) visto pelo app — isola o `firebase_messaging` para
/// o resto do código (e os testes) não depender dele.
abstract interface class PushMessaging {
  Future<PushPermission> permission();

  /// Abre o pedido de permissão do sistema.
  Future<PushPermission> requestPermission();

  /// Token deste aparelho; `null` se o FCM não conseguiu gerar agora.
  Future<String?> getToken();

  /// Tokens novos gerados pelo FCM (o antigo deixa de valer).
  Stream<String> get onTokenRefresh;

  /// Invalida o token deste aparelho (logout): o FCM para de entregar nele.
  Future<void> deleteToken();
}
