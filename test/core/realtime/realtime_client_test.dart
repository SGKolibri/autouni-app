import 'package:autouni_app/core/network/auth_token_store.dart';
import 'package:autouni_app/core/realtime/realtime_client.dart';
import 'package:autouni_app/core/realtime/realtime_socket.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_realtime_socket.dart';

class _RecordingFactory implements SocketFactory {
  final List<({String uri, Map<String, dynamic> auth})> calls = [];
  final List<FakeRealtimeSocket> sockets = [];

  @override
  RealtimeSocket create({
    required String uri,
    required Map<String, dynamic> auth,
  }) {
    calls.add((uri: uri, auth: auth));
    final socket = FakeRealtimeSocket();
    sockets.add(socket);
    return socket;
  }
}

void main() {
  late _RecordingFactory factory;
  late InMemoryAuthTokenStore store;
  late RealtimeClient client;

  RealtimeClient build({bool Function(Object?)? isAuthError}) {
    final c = RealtimeClient(
      socketFactory: factory,
      tokenStore: store,
      url: 'wss://rt.test',
      isAuthError: isAuthError,
    );
    addTearDown(c.dispose);
    return c;
  }

  FakeRealtimeSocket socket() => factory.sockets.last;

  setUp(() {
    factory = _RecordingFactory();
    store = InMemoryAuthTokenStore(accessToken: 'jwt-1', refreshToken: 'r');
    client = build();
  });

  test(
    'connect() cria o socket com a URL e o JWT no payload de auth',
    () async {
      await client.connect();

      expect(factory.calls.single.uri, 'wss://rt.test');
      expect(factory.calls.single.auth, {'token': 'jwt-1'});
      expect(socket().connectCalls, 1);
      expect(client.status, RealtimeConnectionStatus.connecting);
    },
  );

  test('onConnect leva a status connected', () async {
    final transitions = expectLater(
      client.statusStream,
      emitsInOrder([
        RealtimeConnectionStatus.connecting,
        RealtimeConnectionStatus.connected,
      ]),
    );

    await client.connect();
    socket().serverConnect();

    expect(client.status, RealtimeConnectionStatus.connected);
    await transitions;
  });

  test('sem access token não cria socket e marca unauthorized', () async {
    await store.clear();

    await client.connect();

    expect(factory.calls, isEmpty);
    expect(client.status, RealtimeConnectionStatus.unauthorized);
  });

  test('connect() é idempotente enquanto há socket vivo', () async {
    await client.connect();
    await client.connect();

    expect(factory.calls, hasLength(1));
  });

  test('queda não solicitada leva a reconnecting', () async {
    await client.connect();
    socket().serverConnect();

    socket().serverDisconnect('transport close');

    expect(client.status, RealtimeConnectionStatus.reconnecting);
  });

  test(
    'disconnect() manual descarta o socket e não volta a reconnecting',
    () async {
      await client.connect();
      socket().serverConnect();
      final s = socket();

      await client.disconnect();

      expect(s.disposeCalls, 1);
      expect(client.status, RealtimeConnectionStatus.idle);

      s.serverDisconnect('late event');
      expect(client.status, RealtimeConnectionStatus.idle);
    },
  );

  test('onReconnectAttempt injeta um token fresco via updateAuth', () async {
    await client.connect();
    socket().serverConnect();

    await store.saveTokens(accessToken: 'jwt-2', refreshToken: 'r2');
    socket().serverReconnectAttempt(2);
    await Future<void>.delayed(Duration.zero);

    expect(socket().authUpdates.last, {'token': 'jwt-2'});
    expect(client.status, RealtimeConnectionStatus.reconnecting);
  });

  test(
    'connect_error de autenticação vira unauthorized e para as tentativas',
    () async {
      await client.connect();

      socket().serverConnectError({
        'message': 'Authentication error: invalid token',
      });

      expect(client.status, RealtimeConnectionStatus.unauthorized);
      expect(socket().disconnectCalls, greaterThanOrEqualTo(1));
    },
  );

  test(
    'connect_error nao-auth mantem reconnecting; socket.io segue retentando',
    () async {
      await client.connect();

      socket().serverConnectError({'message': 'timeout'});

      expect(client.status, RealtimeConnectionStatus.reconnecting);
      expect(socket().disconnectCalls, 0);
    },
  );

  test('isAuthError customizado é respeitado', () async {
    client = build(isAuthError: (e) => e == 'kick');
    await client.connect();

    socket().serverConnectError('kick');

    expect(client.status, RealtimeConnectionStatus.unauthorized);
  });

  group('ciclo de vida', () {
    test('paused desconecta o socket mas mantém o desejo de conexão', () async {
      await client.connect();
      socket().serverConnect();
      final s = socket();

      client.handleAppLifecycleState(AppLifecycleState.paused);

      expect(s.disposeCalls, 1);
      expect(client.status, RealtimeConnectionStatus.idle);
    });

    test('resumed depois de paused reconecta com um socket novo', () async {
      await client.connect();
      socket().serverConnect();
      client.handleAppLifecycleState(AppLifecycleState.paused);

      await store.saveTokens(accessToken: 'jwt-3', refreshToken: 'r3');
      client.handleAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(factory.calls, hasLength(2));
      expect(factory.calls.last.auth, {'token': 'jwt-3'});
      expect(socket().connectCalls, 1);
    });

    test('resumed sem nunca ter conectado não faz nada', () async {
      client.handleAppLifecycleState(AppLifecycleState.resumed);
      await Future<void>.delayed(Duration.zero);

      expect(factory.calls, isEmpty);
    });

    test('inactive é ignorado', () async {
      await client.connect();
      socket().serverConnect();

      client.handleAppLifecycleState(AppLifecycleState.inactive);

      expect(socket().disposeCalls, 0);
      expect(client.status, RealtimeConnectionStatus.connected);
    });
  });

  test('on/emit delegam ao socket subjacente', () async {
    await client.connect();
    socket().serverConnect();

    final received = <dynamic>[];
    client.on('device.status', received.add);
    socket().serverEvent('device.status', {'id': 1});
    client.emit('subscribe', {'room': 'a'});

    expect(received.single, {'id': 1});
    expect(socket().emissions.single.$1, 'subscribe');
    expect(socket().emissions.single.$2, {'room': 'a'});
  });

  test('dispose() fecha o stream e descarta o socket', () async {
    await client.connect();
    final s = socket();

    await client.dispose();

    expect(s.disposeCalls, 1);
    // segundo dispose não explode
    await client.dispose();
  });
}
