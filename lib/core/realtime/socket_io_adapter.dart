import 'package:socket_io_client/socket_io_client.dart' as io;

import 'realtime_socket.dart';

/// Factory de produção: monta um `socket_io_client` só com transporte
/// WebSocket, auto-connect desligado (quem conecta é o [RealtimeClient]) e o
/// payload de auth inicial.
class SocketIoFactory implements SocketFactory {
  const SocketIoFactory();

  @override
  RealtimeSocket create({
    required String uri,
    required Map<String, dynamic> auth,
  }) {
    final socket = io.io(
      uri,
      io.OptionBuilder()
          .setTransports(const ['websocket'])
          .disableAutoConnect()
          .enableForceNew()
          .setAuth(auth)
          .build(),
    );
    return SocketIoAdapter(socket);
  }
}

/// Adapta a API do `socket_io_client` para [RealtimeSocket].
class SocketIoAdapter implements RealtimeSocket {
  SocketIoAdapter(this._socket);

  final io.Socket _socket;

  @override
  void connect() => _socket.connect();

  @override
  void disconnect() => _socket.disconnect();

  @override
  void dispose() => _socket.dispose();

  @override
  void updateAuth(Map<String, dynamic> auth) => _socket.auth = auth;

  @override
  void onConnect(void Function(dynamic data) handler) =>
      _socket.onConnect(handler);

  @override
  void onDisconnect(void Function(dynamic data) handler) =>
      _socket.onDisconnect(handler);

  @override
  void onConnectError(void Function(dynamic data) handler) =>
      _socket.onConnectError(handler);

  @override
  void onReconnectAttempt(void Function(dynamic data) handler) =>
      _socket.onReconnectAttempt(handler);

  @override
  void on(String event, void Function(dynamic data) handler) =>
      _socket.on(event, handler);

  @override
  void off(String event) => _socket.off(event);

  @override
  void emit(String event, [dynamic data]) {
    if (data == null) {
      _socket.emit(event);
    } else {
      _socket.emit(event, data);
    }
  }
}
