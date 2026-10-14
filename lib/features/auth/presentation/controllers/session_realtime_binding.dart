import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/realtime/realtime_providers.dart';
import 'auth_controller.dart';

/// Liga o WebSocket à sessão: conecta quando há usuário logado e desconecta
/// no logout ou quando a sessão expira.
///
/// Precisa ficar vivo enquanto o app roda — o `AutoUniApp` o observa.
final sessionRealtimeBindingProvider = Provider<void>((ref) {
  ref.listen(authControllerProvider, (previous, next) {
    final client = ref.read(realtimeClientProvider);
    final wasLoggedIn = previous?.value != null;
    final isLoggedIn = next.value != null;
    if (isLoggedIn && !wasLoggedIn) {
      unawaited(client.connect());
    } else if (!isLoggedIn && wasLoggedIn && !next.isLoading) {
      unawaited(client.disconnect());
    }
  }, fireImmediately: true);
}, name: 'sessionRealtimeBindingProvider');
