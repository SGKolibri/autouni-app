// Construtor com nomes públicos p/ os callers; campos privados. Um formal
// `this._x` daria o mesmo, mantemos assim junto dos demais inicializadores.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:flutter/widgets.dart' show AppLifecycleState;

import '../network/auth_token_store.dart';
import 'realtime_socket.dart';

/// Estado da conexão em tempo real, consumível pela UI (banner de
/// ws-desconectado na S3-T6).
enum RealtimeConnectionStatus {
  /// Sem conexão e sem tentativa em curso (nunca conectou ou desconectou
  /// manualmente / por ir para background).
  idle,

  /// Primeira conexão em andamento.
  connecting,

  /// Conectado e autenticado.
  connected,

  /// Caiu e o socket.io está retentando.
  reconnecting,

  /// O servidor recusou o JWT — precisa de novo login antes de reconectar.
  unauthorized,
}

/// Detecta, pelo payload de `connect_error`, se a falha foi de autenticação.
typedef AuthErrorDetector = bool Function(Object? error);

bool _defaultIsAuthError(Object? error) {
  final text = switch (error) {
    Map map => (map['message'] ?? map['data'] ?? map).toString(),
    _ => error.toString(),
  }.toLowerCase();
  return text.contains('auth') ||
      text.contains('unauthorized') ||
      text.contains('forbidden') ||
      text.contains('token') ||
      text.contains('401');
}

/// Cliente WebSocket autenticado por JWT.
///
/// Responsabilidades:
/// - anexar o access token (`{token: ...}`) na conexão e renová-lo a cada
///   tentativa de reconexão;
/// - traduzir os eventos do socket para [RealtimeConnectionStatus];
/// - parar de tentar quando o servidor recusa o token (→ [unauthorized]);
/// - soltar a conexão em background e retomá-la em foreground
///   ([handleAppLifecycleState]).
///
/// Assinaturas de eventos (`on`/`emit`) sobrevivem a reconexões: são
/// reaplicadas em cada socket novo.
class RealtimeClient {
  RealtimeClient({
    required SocketFactory socketFactory,
    required AuthTokenStore tokenStore,
    required String url,
    AuthErrorDetector? isAuthError,
  }) : _factory = socketFactory,
       _tokenStore = tokenStore,
       _url = url,
       _isAuthError = isAuthError ?? _defaultIsAuthError;

  final SocketFactory _factory;
  final AuthTokenStore _tokenStore;
  final String _url;
  final AuthErrorDetector _isAuthError;

  final _statusController =
      StreamController<RealtimeConnectionStatus>.broadcast();
  final Map<String, void Function(dynamic)> _subscriptions = {};

  RealtimeSocket? _socket;
  bool _wantConnected = false;
  bool _disposed = false;
  var _status = RealtimeConnectionStatus.idle;

  RealtimeConnectionStatus get status => _status;
  Stream<RealtimeConnectionStatus> get statusStream => _statusController.stream;

  /// Abre a conexão. Idempotente enquanto houver um socket vivo.
  Future<void> connect() async {
    if (_disposed || _socket != null) return;
    _wantConnected = true;

    final token = await _tokenStore.readAccessToken();
    if (_disposed) return;
    if (token == null || token.isEmpty) {
      _setStatus(RealtimeConnectionStatus.unauthorized);
      return;
    }

    final socket = _factory.create(uri: _url, auth: {'token': token});
    _socket = socket;

    socket.onConnect((_) => _setStatus(RealtimeConnectionStatus.connected));
    socket.onDisconnect((_) {
      if (_wantConnected && _socket == socket) {
        _setStatus(RealtimeConnectionStatus.reconnecting);
      }
    });
    socket.onConnectError((data) {
      if (_socket != socket) return;
      if (_isAuthError(data)) {
        _wantConnected = false;
        _teardownSocket();
        _setStatus(RealtimeConnectionStatus.unauthorized);
      } else {
        _setStatus(RealtimeConnectionStatus.reconnecting);
      }
    });
    socket.onReconnectAttempt((_) => _refreshAuth(socket));

    _subscriptions.forEach(socket.on);

    _setStatus(RealtimeConnectionStatus.connecting);
    socket.connect();
  }

  /// Desconexão manual: não reconecta até `connect()` ser chamado de novo.
  Future<void> disconnect() async {
    _wantConnected = false;
    _teardownSocket();
    _setStatus(RealtimeConnectionStatus.idle);
  }

  /// Liga o ciclo de vida do app à conexão: solta em background, retoma em
  /// foreground. `inactive` é transiente e ignorado.
  void handleAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        if (_socket != null) {
          _teardownSocket();
          _setStatus(RealtimeConnectionStatus.idle);
        }
      case AppLifecycleState.resumed:
        if (_wantConnected && _socket == null) {
          unawaited(connect());
        }
      case AppLifecycleState.inactive:
        break;
    }
  }

  void on(String event, void Function(dynamic data) handler) {
    _subscriptions[event] = handler;
    _socket?.on(event, handler);
  }

  void off(String event) {
    _subscriptions.remove(event);
    _socket?.off(event);
  }

  /// Emite um evento; descartado silenciosamente se não há socket.
  void emit(String event, [dynamic data]) => _socket?.emit(event, data);

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _wantConnected = false;
    _teardownSocket();
    await _statusController.close();
  }

  Future<void> _refreshAuth(RealtimeSocket socket) async {
    if (_socket == socket) {
      _setStatus(RealtimeConnectionStatus.reconnecting);
    }
    final token = await _tokenStore.readAccessToken();
    if (_socket == socket && token != null && token.isNotEmpty) {
      socket.updateAuth({'token': token});
    }
  }

  void _teardownSocket() {
    final socket = _socket;
    if (socket == null) return;
    _socket = null;
    socket.disconnect();
    socket.dispose();
  }

  void _setStatus(RealtimeConnectionStatus status) {
    if (_disposed) return;
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }
}
