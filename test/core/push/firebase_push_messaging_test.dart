// O adaptador usa a API de token de registro de propósito (ver
// FirebasePushMessaging); os mocks precisam dos mesmos membros.
// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:autouni_app/core/config/firebase_config.dart';
import 'package:autouni_app/core/push/firebase_push_messaging.dart';
import 'package:autouni_app/core/push/push_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

NotificationSettings _settings(AuthorizationStatus status) =>
    NotificationSettings(
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.notSupported,
      authorizationStatus: status,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.notSupported,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      showPreviews: AppleShowPreviewSetting.always,
      timeSensitive: AppleNotificationSetting.notSupported,
      criticalAlert: AppleNotificationSetting.notSupported,
      sound: AppleNotificationSetting.enabled,
      providesAppNotificationSettings: AppleNotificationSetting.notSupported,
    );

void main() {
  late _MockFirebaseMessaging firebase;
  late FirebasePushMessaging messaging;

  setUp(() {
    firebase = _MockFirebaseMessaging();
    messaging = FirebasePushMessaging(firebase);
  });

  group('permissão', () {
    for (final (status, expected) in [
      (AuthorizationStatus.authorized, PushPermission.granted),
      (AuthorizationStatus.provisional, PushPermission.granted),
      (AuthorizationStatus.denied, PushPermission.denied),
      (AuthorizationStatus.deniedPermanently, PushPermission.denied),
      (AuthorizationStatus.notDetermined, PushPermission.notDetermined),
    ]) {
      test('${status.name} → ${expected.name}', () async {
        when(() => firebase.getNotificationSettings())
            .thenAnswer((_) async => _settings(status));

        expect(await messaging.permission(), expected);
      });
    }

    test(
      'pedir permissão chama o prompt do sistema (alerta, badge, som)',
      () async {
        when(() => firebase.requestPermission())
            .thenAnswer((_) async => _settings(AuthorizationStatus.authorized));

        expect(await messaging.requestPermission(), PushPermission.granted);
        verify(() => firebase.requestPermission()).called(1);
      },
    );
  });

  group('token', () {
    test('devolve o token do FCM', () async {
      when(() => firebase.getToken()).thenAnswer((_) async => 'fcm-1');

      expect(await messaging.getToken(), 'fcm-1');
    });

    test('falha do plugin (sem rede, sem APNs) vira null', () async {
      when(() => firebase.getToken()).thenThrow(
        FirebaseException(plugin: 'messaging', message: 'apns-token-not-set'),
      );

      expect(await messaging.getToken(), isNull);
    });

    test('repassa a renovação do token', () async {
      final refresh = StreamController<String>();
      addTearDown(refresh.close);
      when(() => firebase.onTokenRefresh).thenAnswer((_) => refresh.stream);

      final next = messaging.onTokenRefresh.first;
      refresh.add('fcm-2');

      expect(await next, 'fcm-2');
    });

    test('apagar o token ignora falha do plugin', () async {
      when(
        () => firebase.deleteToken(),
      ).thenThrow(FirebaseException(plugin: 'messaging', message: 'offline'));

      await expectLater(messaging.deleteToken(), completes);
    });
  });

  group('mensagens', () {
    const remote = RemoteMessage(
      notification: RemoteNotification(title: 'Consumo alto', body: 'Bloco A'),
      data: {'notificationId': 'n1', 'type': 'WARNING', 'link': '/devices/d1'},
    );
    const expected = PushMessage(
      title: 'Consumo alto',
      body: 'Bloco A',
      notificationId: 'n1',
      link: '/devices/d1',
    );

    test('lê notification + data do backend', () {
      expect(FirebasePushMessaging.toPushMessage(remote), expected);
    });

    test('só data: título e corpo vêm de data; link vazio vira null', () {
      expect(
        FirebasePushMessaging.toPushMessage(
          const RemoteMessage(
            data: {
              'title': 'T',
              'body': 'B',
              'notificationId': 'n2',
              'link': '',
            },
          ),
        ),
        const PushMessage(title: 'T', body: 'B', notificationId: 'n2'),
      );
    });

    test('repassa os pushes com o app aberto e os tocados', () async {
      final foreground = StreamController<RemoteMessage>();
      final opened = StreamController<RemoteMessage>();
      addTearDown(foreground.close);
      addTearDown(opened.close);
      messaging = FirebasePushMessaging(
        firebase,
        onMessage: foreground.stream,
        onMessageOpenedApp: opened.stream,
      );

      final first = messaging.onForegroundMessage.first;
      foreground.add(remote);
      expect(await first, expected);

      final tapped = messaging.onMessageOpened.first;
      opened.add(remote);
      expect(await tapped, expected);
    });

    test('push que abriu o app fechado', () async {
      when(() => firebase.getInitialMessage()).thenAnswer((_) async => remote);

      expect(await messaging.initialMessage(), expected);
    });

    test('sem push inicial, ou falha do plugin, devolve null', () async {
      when(() => firebase.getInitialMessage()).thenAnswer((_) async => null);
      expect(await messaging.initialMessage(), isNull);

      when(() => firebase.getInitialMessage())
          .thenThrow(FirebaseException(plugin: 'messaging'));
      expect(await messaging.initialMessage(), isNull);
    });
  });

  group('initFirebasePush', () {
    const config = FirebaseConfig(
      apiKey: 'key',
      projectId: 'autouni',
      messagingSenderId: '123',
      androidAppId: '1:123:android:abc',
      iosBundleId: 'br.autouni.app',
    );

    test('sem config, push desligado sem inicializar nada', () async {
      var initialized = false;

      final result = await initFirebasePush(
        null,
        platform: TargetPlatform.android,
        initialize: (_) async => initialized = true,
        messaging: () => firebase,
      );

      expect(result, isNull);
      expect(initialized, isFalse);
    });

    test('plataforma sem app id fica sem push', () async {
      final result = await initFirebasePush(
        config,
        platform: TargetPlatform.iOS,
        initialize: (_) async {},
        messaging: () => firebase,
      );

      expect(result, isNull);
    });

    test('inicializa o Firebase com as opções da plataforma', () async {
      FirebaseOptions? used;

      final result = await initFirebasePush(
        config,
        platform: TargetPlatform.android,
        initialize: (options) async => used = options,
        messaging: () => firebase,
      );

      expect(result, isA<FirebasePushMessaging>());
      expect(used!.apiKey, 'key');
      expect(used!.appId, '1:123:android:abc');
      expect(used!.messagingSenderId, '123');
      expect(used!.projectId, 'autouni');
      expect(used!.iosBundleId, 'br.autouni.app');
    });

    test('erro ao inicializar não derruba o app: push desligado', () async {
      final result = await initFirebasePush(
        config,
        platform: TargetPlatform.android,
        initialize: (_) => throw FirebaseException(plugin: 'core'),
        messaging: () => firebase,
      );

      expect(result, isNull);
    });
  });

  group('PushPlatform', () {
    test('valor da API por plataforma', () {
      expect(PushPlatform.of(TargetPlatform.android), PushPlatform.android);
      expect(PushPlatform.of(TargetPlatform.iOS), PushPlatform.ios);
      expect(PushPlatform.of(TargetPlatform.linux), isNull);
      expect(
        PushPlatform.of(TargetPlatform.iOS, isWeb: true),
        PushPlatform.web,
      );
      expect(PushPlatform.android.apiValue, 'ANDROID');
      expect(PushPlatform.ios.apiValue, 'IOS');
      expect(PushPlatform.web.apiValue, 'WEB');
    });
  });
}
