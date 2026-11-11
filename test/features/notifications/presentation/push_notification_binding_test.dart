import 'dart:async';

import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/push/push_messaging.dart';
import 'package:autouni_app/core/push/push_providers.dart';
import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/core/router/app_tab.dart';
import 'package:autouni_app/core/session/session_hooks.dart';
import 'package:autouni_app/features/notifications/data/notification_link_resolver.dart';
import 'package:autouni_app/features/notifications/data/notifications_repository.dart';
import 'package:autouni_app/features/notifications/domain/app_notification.dart';
import 'package:autouni_app/features/notifications/presentation/notification_opener.dart';
import 'package:autouni_app/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:autouni_app/features/notifications/presentation/push_notification_binding.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMessaging extends Mock implements PushMessaging {}

class _MockRepository extends Mock implements NotificationsRepository {}

class _MockResolver extends Mock implements NotificationLinkResolver {}

class _Session extends Notifier<String?> {
  @override
  String? build() => 'u1';

  void set(String? id) => state = id;
}

final _session = NotifierProvider<_Session, String?>(_Session.new);

class _Notice {
  _Notice(this.message, this.actionLabel, this.onAction);

  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
}

void main() {
  late _MockMessaging messaging;
  late _MockRepository repository;
  late _MockResolver resolver;
  late StreamController<PushMessage> foreground;
  late StreamController<PushMessage> opened;
  late List<String> went;
  late List<_Notice> notices;
  late ProviderContainer container;

  const tapped = PushMessage(
    title: 'Ar ligado fora do horário',
    body: 'Sala 101',
    notificationId: 'n1',
    link: '/devices/d1',
  );
  final deviceRoom = AppPaths.room('b1', 'f1', 'r1', deviceId: 'd1');

  ProviderContainer build({PushMessage? initial, bool signedIn = true}) {
    when(() => messaging.initialMessage()).thenAnswer((_) async => initial);
    final binding = Provider<void>(
      (ref) => bindPushNotifications(
        ref,
        go: went.add,
        notify: (message, {actionLabel, onAction}) =>
            notices.add(_Notice(message, actionLabel, onAction)),
      ),
    );
    final c = ProviderContainer.test(
      overrides: [
        pushMessagingProvider.overrideWithValue(messaging),
        notificationsRepositoryProvider.overrideWithValue(repository),
        notificationLinkResolverProvider.overrideWithValue(resolver),
        sessionUserIdProvider.overrideWith((ref) => ref.watch(_session)),
      ],
    );
    if (!signedIn) c.read(_session.notifier).set(null);
    c.listen(binding, (_, _) {});
    return c;
  }

  setUp(() {
    messaging = _MockMessaging();
    repository = _MockRepository();
    resolver = _MockResolver();
    foreground = StreamController<PushMessage>.broadcast();
    opened = StreamController<PushMessage>.broadcast();
    went = [];
    notices = [];
    when(() => messaging.onForegroundMessage)
        .thenAnswer((_) => foreground.stream);
    when(() => messaging.onMessageOpened).thenAnswer((_) => opened.stream);
    when(() => repository.markRead(any())).thenAnswer((_) async {});
    when(() => repository.watchMine())
        .thenAnswer((_) => Stream.value(const Cached(<AppNotification>[])));
    when(() => resolver.resolve('/devices/d1'))
        .thenAnswer((_) async => deviceRoom);
  });

  tearDown(() async {
    await foreground.close();
    await opened.close();
  });

  test('sem push configurado não faz nada', () async {
    final binding = Provider<void>(
      (ref) => bindPushNotifications(
        ref,
        go: went.add,
        notify: (_, {actionLabel, onAction}) {},
      ),
    );
    final c = ProviderContainer.test();
    c.listen(binding, (_, _) {});
    await pumpEventQueue();

    expect(went, isEmpty);
  });

  group('push tocado', () {
    test('abre o destino do link e marca a notificação como lida', () async {
      container = build();
      await pumpEventQueue();

      opened.add(tapped);
      await pumpEventQueue();

      expect(went, [deviceRoom]);
      verify(() => repository.markRead('n1')).called(1);
    });

    test('push sem link abre a central', () async {
      container = build();
      await pumpEventQueue();

      opened.add(const PushMessage(title: 'Aviso', notificationId: 'n2'));
      await pumpEventQueue();

      expect(went, [AppTab.notifications.path]);
    });

    test('link que não abre no app: central + aviso', () async {
      when(() => resolver.resolve('/reports/r1')).thenAnswer((_) async => null);
      container = build();
      await pumpEventQueue();

      opened.add(const PushMessage(title: 'Relatório', link: '/reports/r1'));
      await pumpEventQueue();

      expect(went, [AppTab.notifications.path]);
      expect(notices.single.message, unsupportedLinkMessage);
    });

    test('destino apagado: central + aviso com o erro', () async {
      when(() => resolver.resolve('/devices/d1'))
          .thenThrow(const NotFoundException(message: 'Device not found'));
      container = build();
      await pumpEventQueue();

      opened.add(tapped);
      await pumpEventQueue();

      expect(went, [AppTab.notifications.path]);
      expect(notices.single.message, contains('Device not found'));
    });

    test('push que abriu o app fechado também navega', () async {
      container = build(initial: tapped);
      await pumpEventQueue();

      expect(went, [deviceRoom]);
    });

    test('deslogado: guarda e abre depois do login', () async {
      container = build(initial: tapped, signedIn: false);
      await pumpEventQueue();
      expect(went, isEmpty);

      container.read(_session.notifier).set('u1');
      await pumpEventQueue();

      expect(went, [deviceRoom]);
    });

    test('falha ao marcar como lida não impede a navegação', () async {
      when(() => repository.markRead('n1')).thenThrow(const NetworkException());
      container = build();
      await pumpEventQueue();

      opened.add(tapped);
      await pumpEventQueue();

      expect(went, [deviceRoom]);
    });
  });

  group('push com o app aberto', () {
    test('avisa com "Ver" e recarrega a central', () async {
      container = build();
      final list = container.listen(notificationsProvider, (_, _) {});
      addTearDown(list.close);
      await pumpEventQueue();

      foreground.add(tapped);
      await pumpEventQueue();

      expect(notices.single.message, 'Ar ligado fora do horário');
      expect(notices.single.actionLabel, 'Ver');
      expect(went, isEmpty);
      verify(() => repository.watchMine()).called(2);

      notices.single.onAction!();
      await pumpEventQueue();
      expect(went, [deviceRoom]);
    });

    test('sem título usa o corpo; sem nada, "Novo alerta"', () async {
      container = build();
      await pumpEventQueue();

      foreground
        ..add(const PushMessage(body: 'Só corpo'))
        ..add(const PushMessage());
      await pumpEventQueue();

      expect(notices.map((n) => n.message), ['Só corpo', 'Novo alerta']);
    });
  });
}
