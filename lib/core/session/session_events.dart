import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Avisos de sessão emitidos pela camada de rede para quem guarda o estado
/// de login (a feature de autenticação), sem a rede depender dela.
class SessionEvents {
  final _expired = StreamController<void>.broadcast();

  /// Dispara quando o refresh token foi recusado e a sessão acabou.
  Stream<void> get expired => _expired.stream;

  void notifyExpired() {
    if (!_expired.isClosed) _expired.add(null);
  }

  Future<void> dispose() => _expired.close();
}

final sessionEventsProvider = Provider<SessionEvents>((ref) {
  final events = SessionEvents();
  ref.onDispose(events.dispose);
  return events;
}, name: 'sessionEventsProvider');
