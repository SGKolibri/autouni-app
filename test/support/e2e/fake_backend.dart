import 'dart:async';
import 'dart:convert';

import 'package:autouni_app/core/push/push_messaging.dart';
import 'package:autouni_app/core/realtime/realtime_socket.dart';
import 'package:dio/dio.dart';

import '../fake_jwt.dart';

/// Backend do AutoUni em memória para os testes de ponta a ponta: responde
/// às rotas que o app usa (com o mesmo formato do NestJS), guarda estado
/// entre chamadas e emite os eventos do WebSocket como o `RealtimeGateway`.
///
/// O app roda inteiro de verdade (interceptors, repositórios, providers e
/// telas); só o transporte é trocado.
class FakeBackend implements HttpClientAdapter {
  FakeBackend() {
    socketFactory = FakeSocketFactory(this);
  }

  late final FakeSocketFactory socketFactory;

  /// Requests recebidas, na ordem (`"POST /devices/d1/control"`).
  final List<String> log = [];

  /// Rotas pedidas que o backend falso não conhece (ajuda a depurar).
  final List<String> unhandled = [];

  final Map<String, Map<String, Object?>> users = {
    'u1': {
      'id': 'u1',
      'email': 'admin@autouni.edu.br',
      'name': 'Administrador Sistema',
      'role': 'ADMIN',
      'phone': '62999990000',
      '_password': 'Admin@123',
    },
    'u2': {
      'id': 'u2',
      'email': 'viewer@autouni.edu.br',
      'name': 'Visualizador',
      'role': 'VIEWER',
      '_password': 'View@123',
    },
  };

  final Map<String, Map<String, Object?>> devices = {
    'd1': _device('d1', 'Luminária da frente', 'LIGHT', 'OFF', {
      'power': 40,
      'intensity': 80,
    }),
    'd2': _device('d2', 'Ar-condicionado', 'AC', 'ON', {
      'power': 1500,
      'temperature': 23,
    }),
    'd3': _device('d3', 'Projetor', 'PROJECTOR', 'OFF', {}, online: false),
  };

  final List<Map<String, Object?>> notifications = [
    {
      'id': 'n1',
      'userId': 'u1',
      'type': 'WARNING',
      'title': 'Ar ligado fora do horário',
      'message': 'O ar-condicionado da Sala 101 está ligado.',
      'read': false,
      'link': '/devices/d2',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    },
  ];

  /// Tokens de push registrados (`POST /push/tokens`).
  final Set<String> pushTokens = {};

  static Map<String, Object?> _device(
    String id,
    String name,
    String type,
    String status,
    Map<String, Object?> metadata, {
    bool online = true,
  }) => {
    'id': id,
    'name': name,
    'roomId': 'r1',
    'type': type,
    'status': status,
    'online': online,
    'metadata': metadata,
  };

  static const _building = {
    'id': 'b1',
    'name': 'Bloco A',
    'location': 'Campus I',
  };
  static const _floor = {'id': 'f1', 'buildingId': 'b1', 'number': 1};
  static const _room = {
    'id': 'r1',
    'floorId': 'f1',
    'name': 'Sala 101',
    'type': 'CLASSROOM',
  };

  List<Map<String, Object?>> get _roomDevices => devices.values.toList();

  int get _active => devices.values.where((d) => d['status'] == 'ON').length;

  Map<String, Object?> get _roomJson => {
    ..._room,
    'devices': _roomDevices,
    'totalDevices': devices.length,
    'activeDevices': _active,
    'todayEnergyKwh': 3.5,
  };

  Map<String, Object?> get _floorJson => {
    ..._floor,
    'rooms': [_roomJson],
    'totalDevices': devices.length,
    'activeDevices': _active,
    'todayEnergyKwh': 3.5,
  };

  Map<String, Object?> get _buildingJson => {
    ..._building,
    'floors': [_floorJson],
    'totalDevices': devices.length,
    'activeDevices': _active,
    'todayEnergyKwh': 3.5,
  };

  String _token(Map<String, Object?> user, Duration ttl) => fakeJwt({
    'sub': user['id'],
    'email': user['email'],
    'name': user['name'],
    'role': user['role'],
    'exp': jwtSeconds(DateTime.now().add(ttl)),
  });

  Map<String, Object?> _public(Map<String, Object?> user) => {
    for (final entry in user.entries)
      if (!entry.key.startsWith('_')) entry.key: entry.value,
  };

  (int, Object?) _handle(String method, String path, Object? body) {
    final data = body is Map ? body : const {};
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    switch ((method, segments)) {
      case ('POST', ['auth', 'login']):
        final user = users.values
            .where((u) => u['email'] == data['email'])
            .firstOrNull;
        if (user == null || user['_password'] != data['password']) {
          return (401, {'statusCode': 401, 'message': 'Credenciais inválidas'});
        }
        return (
          200,
          {
            'user': _public(user),
            'accessToken': _token(user, const Duration(minutes: 15)),
            'refreshToken': _token(user, const Duration(days: 7)),
          },
        );
      case ('POST', ['auth', 'logout']):
        return (200, {'message': 'Logout realizado com sucesso'});
      case ('POST', ['push', 'tokens']):
        pushTokens.add('${data['token']}');
        return (201, {'ok': true});
      case ('DELETE', ['push', 'tokens']):
        pushTokens.remove('${data['token']}');
        return (200, {'ok': true});
      case ('GET', ['users', final id]):
        final user = users[id];
        return user == null ? (404, null) : (200, _public(user));
      case ('GET', ['buildings']):
        return (200, [_buildingJson]);
      case ('GET', ['buildings', 'b1']):
        return (200, _building);
      case ('GET', ['floors', 'building', 'b1']):
        return (200, [_floorJson]);
      case ('GET', ['floors', 'f1']):
        return (200, {..._floor, 'building': _building});
      case ('GET', ['rooms', 'floor', 'f1']):
        return (200, [_roomJson]);
      case ('GET', ['rooms', 'r1', 'details']):
        return (
          200,
          {
            ..._roomJson,
            'floor': {..._floor, 'building': _building},
          },
        );
      case ('GET', ['devices']):
        return (200, _roomDevices);
      case ('GET', ['devices', final id]):
        final device = devices[id];
        return device == null
            ? (404, {'message': 'Device not found'})
            : (
                200,
                {
                  ...device,
                  'room': {
                    ..._room,
                    'floor': {..._floor, 'building': _building},
                  },
                },
              );
      case ('POST', ['devices', final id, 'control']):
        final device = devices[id];
        if (device == null) return (404, {'message': 'Device not found'});
        final status = switch (data['command']) {
          'on' => 'ON',
          'off' => 'OFF',
          _ => device['status'] == 'ON' ? 'OFF' : 'ON',
        };
        device['status'] = status;
        // Como o backend real: grava, emite pelo WebSocket e responde.
        socketFactory.emit('device:status', {
          'deviceId': id,
          'status': status,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        });
        return (200, {...device, 'pending': false});
      case ('GET', ['energy', 'stats']):
        return (200, {'todayEnergyKwh': 3.5, 'hasData': true});
      case ('GET', ['notifications', 'user', final userId]):
        return (
          200,
          [
            for (final n in notifications)
              if (n['userId'] == userId) n,
          ],
        );
      case ('PATCH', ['notifications', final id, 'read']):
        final notification = notifications
            .where((n) => n['id'] == id)
            .firstOrNull;
        if (notification == null) return (404, null);
        notification['read'] = true;
        return (200, notification);
      case ('GET', ['automations']):
      case ('GET', ['reports', 'creator', _]):
        return (200, <Object>[]);
    }
    unhandled.add('$method $path');
    return (404, {'statusCode': 404, 'message': 'Cannot $method $path'});
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    log.add('${options.method} ${options.path}');
    final (status, body) = _handle(options.method, options.path, options.data);
    return ResponseBody.fromString(
      body == null ? '' : jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Sockets do backend falso: conectam sozinhos e recebem os eventos que o
/// [FakeBackend] emite.
class FakeSocketFactory implements SocketFactory {
  FakeSocketFactory(this.backend);

  final FakeBackend backend;
  final List<FakeAutoSocket> sockets = [];

  void emit(String event, Object? data) {
    for (final socket in List.of(sockets)) {
      socket.serverEvent(event, data);
    }
  }

  @override
  RealtimeSocket create({
    required String uri,
    required Map<String, dynamic> auth,
  }) {
    final socket = FakeAutoSocket(this);
    sockets.add(socket);
    return socket;
  }
}

/// Socket que conecta sozinho e só entrega eventos enquanto conectado.
class FakeAutoSocket implements RealtimeSocket {
  FakeAutoSocket(this._factory);

  final FakeSocketFactory _factory;
  final Map<String, void Function(dynamic)> _handlers = {};
  bool _connected = false;

  void serverEvent(String event, Object? data) {
    if (_connected) _handlers[event]?.call(data);
  }

  @override
  void connect() {
    scheduleMicrotask(() {
      _connected = true;
      _handlers['connect']?.call(null);
    });
  }

  @override
  void disconnect() => _connected = false;

  @override
  void dispose() {
    _connected = false;
    _factory.sockets.remove(this);
  }

  @override
  void updateAuth(Map<String, dynamic> auth) {}

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
  void emit(String event, [dynamic data]) {}
}

/// Push (FCM) falso: permissão concedida, token fixo e pushes disparados
/// pelo teste.
class FakePushMessaging implements PushMessaging {
  final _foreground = StreamController<PushMessage>.broadcast();
  final _opened = StreamController<PushMessage>.broadcast();

  static const String token = 'fcm-e2e';

  /// Simula tocar num push na bandeja com o app em segundo plano.
  void tap(PushMessage message) => _opened.add(message);

  /// Simula um push chegando com o app aberto.
  void receive(PushMessage message) => _foreground.add(message);

  @override
  Future<PushPermission> permission() async => PushPermission.granted;

  @override
  Future<PushPermission> requestPermission() async => PushPermission.granted;

  @override
  Future<String?> getToken() async => token;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<void> deleteToken() async {}

  @override
  Stream<PushMessage> get onForegroundMessage => _foreground.stream;

  @override
  Stream<PushMessage> get onMessageOpened => _opened.stream;

  @override
  Future<PushMessage?> initialMessage() async => null;
}
