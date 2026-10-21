/// Superfície mínima de um socket que o [RealtimeClient] precisa.
///
/// Existe para manter `socket_io_client` fora da lógica de conexão/estado e
/// permitir testes com um fake (ver `test/support/fake_realtime_socket.dart`).
abstract interface class RealtimeSocket {
  /// Abre a conexão (auto-connect fica desligado no adapter real).
  void connect();

  /// Fecha a conexão sem descartar os listeners.
  void disconnect();

  /// Fecha e libera o socket definitivamente.
  void dispose();

  /// Atualiza o payload de autenticação usado nas próximas (re)conexões.
  void updateAuth(Map<String, dynamic> auth);

  void onConnect(void Function(dynamic data) handler);
  void onDisconnect(void Function(dynamic data) handler);
  void onConnectError(void Function(dynamic data) handler);

  /// `reconnect_attempt` do Manager do socket.io.
  void onReconnectAttempt(void Function(dynamic data) handler);

  void on(String event, void Function(dynamic data) handler);
  void off(String event);
  void emit(String event, [dynamic data]);
}

/// Cria [RealtimeSocket]s. O adapter real monta um `io(...)` do
/// `socket_io_client`; testes injetam uma factory que devolve fakes.
abstract interface class SocketFactory {
  RealtimeSocket create({
    required String uri,
    required Map<String, dynamic> auth,
  });
}
