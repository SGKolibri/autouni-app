import 'package:autouni_app/core/realtime/realtime_socket.dart';

/// [RealtimeSocket] de teste: não abre conexão nenhuma. Registra as chamadas
/// e deixa o teste disparar os eventos do servidor (`serverConnect`, etc.).
class FakeRealtimeSocket implements RealtimeSocket {
  int connectCalls = 0;
  int disconnectCalls = 0;
  int disposeCalls = 0;
  bool get connected => _connected;
  bool _connected = false;

  final List<Map<String, dynamic>> authUpdates = <Map<String, dynamic>>[];
  final List<(String, dynamic)> emissions = <(String, dynamic)>[];
  final Map<String, void Function(dynamic)> _handlers = {};

  // --- gatilhos do "servidor" ---
  void serverConnect() {
    _connected = true;
    _handlers['connect']?.call(null);
  }

  void serverDisconnect([Object? reason]) {
    _connected = false;
    _handlers['disconnect']?.call(reason);
  }

  void serverConnectError([Object? data]) =>
      _handlers['connect_error']?.call(data);

  void serverReconnectAttempt([int attempt = 1]) =>
      _handlers['reconnect_attempt']?.call(attempt);

  void serverEvent(String event, [dynamic data]) =>
      _handlers[event]?.call(data);

  bool hasHandler(String event) => _handlers.containsKey(event);

  // --- RealtimeSocket ---
  @override
  void connect() => connectCalls++;

  @override
  void disconnect() {
    disconnectCalls++;
    _connected = false;
  }

  @override
  void dispose() => disposeCalls++;

  @override
  void updateAuth(Map<String, dynamic> auth) => authUpdates.add(auth);

  @override
  void onConnect(void Function(dynamic data) handler) =>
      _handlers['connect'] = handler;

  @override
  void onDisconnect(void Function(dynamic data) handler) =>
      _handlers['disconnect'] = handler;

  @override
  void onConnectError(void Function(dynamic data) handler) =>
      _handlers['connect_error'] = handler;

  @override
  void onReconnectAttempt(void Function(dynamic data) handler) =>
      _handlers['reconnect_attempt'] = handler;

  @override
  void on(String event, void Function(dynamic data) handler) =>
      _handlers[event] = handler;

  @override
  void off(String event) => _handlers.remove(event);

  @override
  void emit(String event, [dynamic data]) => emissions.add((event, data));
}
