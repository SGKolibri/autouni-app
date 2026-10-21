import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'push_messaging.dart';

/// Plugin de push, ou `null` quando o push está desligado (sem Firebase
/// configurado, plataforma sem suporte ou falha ao inicializar).
///
/// O bootstrap sobrescreve com o resultado de `initFirebasePush`.
final pushMessagingProvider = Provider<PushMessaging?>(
  (ref) => null,
  name: 'pushMessagingProvider',
);
