import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_config.dart';
import 'push_messaging.dart';

/// [PushMessaging] sobre o `firebase_messaging`.
///
/// Usa o token de registro do FCM (`getToken`/`onTokenRefresh`/
/// `deleteToken`), depreciado no plugin 17 em favor do registro por
/// Firebase Installation ID (`register`/`onRegistered`). O backend (S5-T6)
/// envia com `sendEachForMulticast`, que só aceita tokens de registro —
/// migrar para FID tem de ser feito nos dois lados juntos.
class FirebasePushMessaging implements PushMessaging {
  /// [onMessage] e [onMessageOpenedApp] são os streams estáticos do plugin;
  /// injetáveis para teste.
  FirebasePushMessaging(
    this._messaging, {
    this._onMessage,
    this._onMessageOpenedApp,
  });

  final FirebaseMessaging _messaging;
  final Stream<RemoteMessage>? _onMessage;
  final Stream<RemoteMessage>? _onMessageOpenedApp;

  /// Lê o que o backend envia (S5-T6): `notification` + `data`.
  static PushMessage toPushMessage(RemoteMessage message) {
    String? data(String key) {
      final value = message.data[key];
      return value is String && value.isNotEmpty ? value : null;
    }

    return PushMessage(
      title: message.notification?.title ?? data('title'),
      body: message.notification?.body ?? data('body'),
      notificationId: data('notificationId'),
      link: data('link'),
    );
  }

  static PushPermission _map(NotificationSettings settings) =>
      switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => PushPermission.granted,
        AuthorizationStatus.denied ||
        AuthorizationStatus.deniedPermanently => PushPermission.denied,
        AuthorizationStatus.notDetermined => PushPermission.notDetermined,
      };

  @override
  Future<PushPermission> permission() async =>
      _map(await _messaging.getNotificationSettings());

  /// No Android 13+ também pede o `POST_NOTIFICATIONS`.
  @override
  Future<PushPermission> requestPermission() async =>
      _map(await _messaging.requestPermission());

  @override
  Future<String?> getToken() async {
    try {
      // ignore: deprecated_member_use
      return await _messaging.getToken();
    } on Exception {
      // Sem rede, sem Play Services ou sem APNs: tenta de novo na próxima
      // sessão.
      return null;
    }
  }

  @override
  // ignore: deprecated_member_use
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  @override
  Stream<PushMessage> get onForegroundMessage =>
      (_onMessage ?? FirebaseMessaging.onMessage).map(toPushMessage);

  @override
  Stream<PushMessage> get onMessageOpened =>
      (_onMessageOpenedApp ?? FirebaseMessaging.onMessageOpenedApp).map(
        toPushMessage,
      );

  @override
  Future<PushMessage?> initialMessage() async {
    try {
      final message = await _messaging.getInitialMessage();
      return message == null ? null : toPushMessage(message);
    } on Exception {
      return null;
    }
  }

  @override
  Future<void> deleteToken() async {
    try {
      // ignore: deprecated_member_use
      await _messaging.deleteToken();
    } on Exception {
      // Best-effort: o backend também apaga tokens que o FCM recusa.
    }
  }
}

/// Inicializa o Firebase com as opções da [FirebaseConfig] (sem
/// `google-services.json`/`GoogleService-Info.plist`) e devolve o push, ou
/// `null` se não houver config para esta plataforma ou a inicialização
/// falhar — o app segue sem push.
Future<PushMessaging?> initFirebasePush(
  FirebaseConfig? config, {
  TargetPlatform? platform,
  Future<void> Function(FirebaseOptions options)? initialize,
  FirebaseMessaging Function()? messaging,
}) async {
  final appId = config?.appIdFor(platform ?? defaultTargetPlatform);
  if (config == null || appId == null) return null;
  try {
    await (initialize ?? _initializeApp)(
      FirebaseOptions(
        apiKey: config.apiKey,
        appId: appId,
        messagingSenderId: config.messagingSenderId,
        projectId: config.projectId,
        iosBundleId: config.iosBundleId,
      ),
    );
    return FirebasePushMessaging(
      (messaging ?? () => FirebaseMessaging.instance)(),
    );
  } on Object catch (error) {
    debugPrint('Push desligado: Firebase não inicializou ($error).');
    return null;
  }
}

// coverage:ignore-start
Future<void> _initializeApp(FirebaseOptions options) =>
    Firebase.initializeApp(options: options);
// coverage:ignore-end
