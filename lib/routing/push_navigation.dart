import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/notifications/presentation/push_notification_binding.dart';
import 'app_router_provider.dart';

/// `ScaffoldMessenger` raiz, para avisos que não pertencem a uma tela (push
/// recebido com o app aberto).
final rootScaffoldMessengerKeyProvider =
    Provider<GlobalKey<ScaffoldMessengerState>>(
      (ref) => GlobalKey<ScaffoldMessengerState>(),
      name: 'rootScaffoldMessengerKeyProvider',
    );

/// Liga o push ao roteador do app (S6-T2). Precisa ficar vivo enquanto o app
/// roda — o `AutoUniApp` o observa.
final pushNavigationProvider = Provider<void>((ref) {
  final router = ref.watch(appRouterProvider);
  final messengerKey = ref.watch(rootScaffoldMessengerKeyProvider);
  bindPushNotifications(
    ref,
    go: router.go,
    notify: (message, {actionLabel, onAction}) {
      messengerKey.currentState
        ?..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(message),
            action: actionLabel == null || onAction == null
                ? null
                : SnackBarAction(label: actionLabel, onPressed: onAction),
          ),
        );
    },
  );
}, name: 'pushNavigationProvider');
