import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/push/push_messaging.dart';
import '../../../core/push/push_providers.dart';
import '../../../core/router/app_tab.dart';
import '../../../core/session/session_hooks.dart';
import '../data/notifications_repository.dart';
import 'notification_opener.dart';
import 'providers/notifications_providers.dart';

/// Aviso dentro do app (SnackBar), com ação opcional.
typedef PushNotice = void Function(
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
});

/// Liga o push à navegação. Chamado no `build` de um provider que vive com o
/// app (ver `routing/push_navigation.dart`):
///
/// - push tocado (em segundo plano ou com o app fechado) → marca como lida e
///   abre o destino do `link`; sem link, abre a central. Deslogado, guarda e
///   abre depois do login;
/// - push com o app aberto → recarrega a central e avisa com "Ver".
void bindPushNotifications(
  Ref ref, {
  required void Function(String location) go,
  required PushNotice notify,
}) {
  final messaging = ref.watch(pushMessagingProvider);
  if (messaging == null) return;

  PushMessage? pending;

  Future<void> markRead(String id) async {
    try {
      await ref.read(notificationsRepositoryProvider).markRead(id);
    } on ApiException {
      // Fica não lida; o usuário vê na central.
    }
    if (ref.mounted) ref.invalidate(notificationsProvider);
  }

  Future<void> open(PushMessage message) async {
    final id = message.notificationId;
    if (id != null) unawaited(markRead(id));
    final link = message.link;
    if (link == null) {
      go(AppTab.notifications.path);
      return;
    }
    final error = await openNotificationLink(ref, link, go);
    if (error != null) {
      go(AppTab.notifications.path);
      notify(error);
    }
  }

  void opened(PushMessage message) {
    if (ref.read(sessionUserIdProvider) == null) {
      pending = message;
      return;
    }
    unawaited(open(message));
  }

  void received(PushMessage message) {
    ref.invalidate(notificationsProvider);
    notify(
      message.title ?? message.body ?? 'Novo alerta',
      actionLabel: 'Ver',
      onAction: () => unawaited(open(message)),
    );
  }

  final subscriptions = [
    messaging.onMessageOpened.listen(opened),
    messaging.onForegroundMessage.listen(received),
  ];
  ref.onDispose(() {
    for (final subscription in subscriptions) {
      unawaited(subscription.cancel());
    }
  });

  ref.listen(sessionUserIdProvider, (_, userId) {
    final message = pending;
    if (userId == null || message == null) return;
    pending = null;
    unawaited(open(message));
  });

  unawaited(
    messaging.initialMessage().then((message) {
      if (message != null && ref.mounted) opened(message);
    }),
  );
}
