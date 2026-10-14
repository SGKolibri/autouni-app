import 'package:autouni_app/core/network/auth_token_store.dart';
import 'package:autouni_app/core/realtime/realtime_client.dart';
import 'package:autouni_app/core/realtime/realtime_providers.dart';
import 'package:autouni_app/core/realtime/realtime_socket.dart';
import 'package:autouni_app/shared/models/campus/campus_enums.dart';
import 'package:autouni_app/shared/realtime/device_events.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/fake_realtime_socket.dart';

class _Factory implements SocketFactory {
  final sockets = <FakeRealtimeSocket>[];

  @override
  RealtimeSocket create({
    required String uri,
    required Map<String, dynamic> auth,
  }) {
    final socket = FakeRealtimeSocket();
    sockets.add(socket);
    return socket;
  }
}

void main() {
  group('parseDeviceEvent', () {
    test('lê device:status', () {
      final event = parseDeviceEvent('device:status', {
        'deviceId': 'd1',
        'status': 'ON',
        'timestamp': '2026-10-14T10:00:00.000Z',
      }) as DeviceStatusChanged?;

      expect(event, isNotNull);
      expect(event!.deviceId, 'd1');
      expect(event.status, DeviceStatus.on);
      expect(event.timestamp, DateTime.utc(2026, 10, 14, 10));
    });

    test('lê device:online', () {
      final event =
          parseDeviceEvent('device:online', {
                'deviceId': 'd1',
                'online': false,
              })!
              as DeviceOnlineChanged;

      expect(event.online, isFalse);
      expect(event.timestamp, isNull);
    });

    for (final (name, data) in [
      ('device:status', 'texto'),
      ('device:status', {'status': 'ON'}),
      ('device:status', {'deviceId': 'd1'}),
      ('device:online', {'deviceId': 'd1', 'online': 'sim'}),
      ('energy:update', {'deviceId': 'd1'}),
    ]) {
      test('ignora payload malformado: $name $data', () {
        expect(parseDeviceEvent(name, data), isNull);
      });
    }
  });

  group('deviceEventsProvider', () {
    test('repassa os eventos do socket a vários ouvintes', () async {
      final factory = _Factory();
      final client = RealtimeClient(
        socketFactory: factory,
        tokenStore: InMemoryAuthTokenStore(accessToken: 'a'),
        url: 'ws://test',
      );
      addTearDown(client.dispose);
      final container = ProviderContainer.test(
        overrides: [realtimeClientProvider.overrideWithValue(client)],
      );
      final stream = container.read(deviceEventsProvider);
      final a = <DeviceEvent>[];
      final b = <DeviceEvent>[];
      stream.listen(a.add);
      stream.listen(b.add);
      await client.connect();

      final socket = factory.sockets.single;
      socket.serverEvent('device:status', {'deviceId': 'd1', 'status': 'OFF'});
      socket.serverEvent('device:online', {'deviceId': 'd2', 'online': true});
      socket.serverEvent('device:status', 'lixo');
      await Future<void>.delayed(Duration.zero);

      expect(a.map((e) => e.deviceId), ['d1', 'd2']);
      expect(b, hasLength(2));
    });

    test('solta os handlers ao ser descartado', () async {
      final factory = _Factory();
      final client = RealtimeClient(
        socketFactory: factory,
        tokenStore: InMemoryAuthTokenStore(accessToken: 'a'),
        url: 'ws://test',
      );
      addTearDown(client.dispose);
      final container = ProviderContainer.test(
        overrides: [realtimeClientProvider.overrideWithValue(client)],
      );
      container.read(deviceEventsProvider);
      await client.connect();
      expect(factory.sockets.single.hasHandler('device:status'), isTrue);

      container.dispose();

      expect(factory.sockets.single.hasHandler('device:status'), isFalse);
    });
  });
}
