import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config_provider.dart';
import '../network/network_providers.dart';
import 'realtime_client.dart';
import 'realtime_socket.dart';
import 'socket_io_adapter.dart';

/// Fábrica dos sockets (socket.io). Os testes de ponta a ponta trocam por
/// sockets em memória.
final socketFactoryProvider = Provider<SocketFactory>(
  (ref) => const SocketIoFactory(),
  name: 'socketFactoryProvider',
);

/// Cliente WebSocket da aplicação, já ligado à config e ao [authTokenStoreProvider].
final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient(
    socketFactory: ref.watch(socketFactoryProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
    url: ref.watch(appConfigProvider).wsBaseUrl,
  );
  ref.onDispose(client.dispose);
  return client;
}, name: 'realtimeClientProvider');

/// Estado atual da conexão em tempo real, recalculado a cada transição.
final realtimeStatusProvider = Provider<RealtimeConnectionStatus>((ref) {
  final client = ref.watch(realtimeClientProvider);
  final sub = client.statusStream.listen((_) => ref.invalidateSelf());
  ref.onDispose(sub.cancel);
  return client.status;
}, name: 'realtimeStatusProvider');
