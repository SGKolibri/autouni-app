import 'package:autouni_app/core/cache/local_cache.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/features/notifications/data/notification_link_resolver.dart';
import 'package:autouni_app/features/notifications/data/notifications_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/campus_fixtures.dart';
import '../../../support/fake_http_adapter.dart';

void main() {
  late Map<String, FakeResponse> responses;
  late FakeHttpAdapter adapter;
  late Dio dio;

  setUp(() {
    responses = {};
    adapter = FakeHttpAdapter(
      (options) =>
          responses['${options.method} ${options.path}'] ??
          FakeResponse(404, body: {'message': 'Não encontrado'}),
    );
    dio = Dio(BaseOptions(baseUrl: 'https://api.test'))
      ..httpClientAdapter = adapter;
  });

  group('HttpNotificationsRepository', () {
    late InMemoryLocalCache cache;
    late HttpNotificationsRepository repository;

    setUp(() {
      cache = InMemoryLocalCache();
      repository = HttpNotificationsRepository(
        dio: dio,
        cache: cache,
        userId: 'u1',
      );
    });

    test('lista as do usuário, mais recentes primeiro', () async {
      responses['GET /notifications/user/u1'] = FakeResponse(
        200,
        body: [
          {
            'id': 'velha',
            'type': 'INFO',
            'title': 'A',
            'createdAt': '2026-10-20T10:00:00.000Z',
          },
          {
            'id': 'nova',
            'type': 'ERROR',
            'title': 'B',
            'createdAt': '2026-10-21T10:00:00.000Z',
          },
        ],
      );

      final list = (await repository.watchMine().last).data;

      expect(list.map((n) => n.id), ['nova', 'velha']);
    });

    test('abre do cache sem rede', () async {
      responses['GET /notifications/user/u1'] = FakeResponse(
        200,
        body: [
          {'id': 'n1', 'type': 'INFO', 'title': 'A'},
        ],
      );
      await repository.watchMine().last;
      responses.clear();
      responses['GET /notifications/user/u1'] = FakeResponse(503);

      final values = await repository.watchMine().toList();

      expect(values.last.offline, isTrue);
      expect(values.last.data.single.id, 'n1');
    });

    test('marca uma como lida com PATCH /:id/read', () async {
      responses['PATCH /notifications/n1/read'] = FakeResponse(200);

      await repository.markRead('n1');

      expect(adapter.requests.single.method, 'PATCH');
      expect(adapter.requests.single.path, '/notifications/n1/read');
    });

    test(
      'marca todas com um PATCH /:id/read por alerta e devolve as falhas',
      () async {
        responses['PATCH /notifications/n1/read'] = FakeResponse(200);
        responses['PATCH /notifications/n3/read'] = FakeResponse(200);

        final failed = await repository.markAllRead(['n1', 'n2', 'n3']);

        expect(failed, ['n2']);
        expect(adapter.requests.map((r) => r.path).toSet(), {
          '/notifications/n1/read',
          '/notifications/n2/read',
          '/notifications/n3/read',
        });
        expect(adapter.requests.where((r) => r.path.contains('/me')), isEmpty);
      },
    );

    test('sem sessão, lista vazia e nenhuma request', () async {
      final anonymous = HttpNotificationsRepository(
        dio: dio,
        cache: cache,
        userId: null,
      );

      final values = await anonymous.watchMine().toList();

      expect(values.single.data, isEmpty);
      expect(adapter.requests, isEmpty);
    });
  });

  group('HttpNotificationLinkResolver', () {
    late HttpNotificationLinkResolver resolver;

    setUp(() => resolver = HttpNotificationLinkResolver(dio));

    test(
      'dispositivo → sala dele, com a ficha do dispositivo aberta',
      () async {
        responses['GET /devices/d1'] = FakeResponse(
          200,
          body: deviceJson(
            id: 'd1',
            roomId: 'r1',
            room: roomJson(
              id: 'r1',
              floorId: 'f1',
              floor: floorJson(id: 'f1', buildingId: 'b1'),
            ),
          ),
        );

        expect(
          await resolver.resolve('/devices/d1'),
          AppPaths.room('b1', 'f1', 'r1', deviceId: 'd1'),
        );
      },
    );

    test('sala → detalhe da sala', () async {
      responses['GET /rooms/r1/details'] = FakeResponse(
        200,
        body: roomJson(
          id: 'r1',
          floorId: 'f1',
          floor: floorJson(id: 'f1', buildingId: 'b1'),
        ),
      );

      expect(
        await resolver.resolve('/rooms/r1'),
        AppPaths.room('b1', 'f1', 'r1'),
      );
    });

    test('andar → salas do andar', () async {
      responses['GET /floors/f1'] = FakeResponse(
        200,
        body: floorJson(id: 'f1', buildingId: 'b1'),
      );

      expect(await resolver.resolve('/floors/f1'), AppPaths.floor('b1', 'f1'));
    });

    test('caminho direto não consulta a API', () async {
      expect(await resolver.resolve('/buildings/b1'), AppPaths.building('b1'));
      expect(await resolver.resolve('/reports/rep1'), AppPaths.report('rep1'));
      expect(adapter.requests, isEmpty);
    });

    test('sem suporte devolve null', () async {
      expect(await resolver.resolve('/users/x'), isNull);
      expect(adapter.requests, isEmpty);
    });

    test('dispositivo sem sala na resposta não tem para onde ir', () async {
      responses['GET /devices/d1'] = FakeResponse(
        200,
        body: deviceJson(id: 'd1'),
      );

      expect(await resolver.resolve('/devices/d1'), isNull);
    });

    test('entidade apagada: o erro da API segue para a tela', () async {
      await expectLater(
        resolver.resolve('/devices/sumiu'),
        throwsA(isA<NotFoundException>()),
      );
    });
  });
}
