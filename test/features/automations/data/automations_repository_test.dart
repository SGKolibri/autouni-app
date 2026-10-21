import 'package:autouni_app/core/cache/local_cache.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/features/automations/data/automations_repository.dart';
import 'package:autouni_app/features/automations/domain/automation_models.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/automation_fixtures.dart';
import '../../../support/fake_http_adapter.dart';

void main() {
  late InMemoryLocalCache cache;
  late FakeResponse Function(RequestOptions) handler;
  late FakeHttpAdapter adapter;
  late HttpAutomationsRepository repository;

  setUp(() {
    cache = InMemoryLocalCache();
    handler = (_) => FakeResponse(404);
    adapter = FakeHttpAdapter((options) => handler(options));
    repository = HttpAutomationsRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://api.test'))
        ..httpClientAdapter = adapter,
      cache: cache,
    );
  });

  RequestOptions last() => adapter.requests.last;

  const draft = AutomationDraft(
    name: 'Desligar luzes',
    description: '',
    triggerType: TriggerType.schedule,
    cron: '0 22 * * *',
    action: AutomationAction(topic: 't/command', payload: {'state': 'OFF'}),
  );

  group('leitura (cache primeiro)', () {
    test('lista as automações', () async {
      handler = (_) => FakeResponse(
        200,
        body: [
          automationJson(id: 'a1'),
          automationJson(id: 'a2'),
        ],
      );

      final list = (await repository.watchAll().last).data;

      expect(list.map((a) => a.id), ['a1', 'a2']);
      expect(last().path, '/automations');
    });

    test('uma automação', () async {
      handler = (_) => FakeResponse(200, body: automationJson(id: 'a9'));

      final automation = (await repository.watchOne('a9').last).data;

      expect(automation.id, 'a9');
      expect(last().path, '/automations/a9');
    });

    test('histórico com limite', () async {
      handler = (_) => FakeResponse(
        200,
        body: [
          {
            'id': 'h1',
            'runAt': '2026-10-20T22:00:00.000Z',
            'success': true,
            'logs': 'ok',
          },
        ],
      );

      final runs = (await repository.watchHistory('a1').last).data;

      expect(runs.single.success, isTrue);
      expect(last().path, '/automations/a1/history');
      expect(last().queryParameters, {'limit': 50});
    });

    test('lista abre do cache sem rede', () async {
      handler = (_) => FakeResponse(200, body: [automationJson()]);
      await repository.watchAll().last;
      handler = (_) => FakeResponse(503);

      final values = await repository.watchAll().toList();

      expect(values.last.offline, isTrue);
      expect(values.last.data, hasLength(1));
    });
  });

  group('escrita', () {
    test('cria com POST', () async {
      handler = (_) => FakeResponse(201, body: automationJson(id: 'novo'));

      final created = await repository.create(draft);

      expect(created.id, 'novo');
      expect(last().method, 'POST');
      expect(last().path, '/automations');
      expect(last().data, draft.toJson());
    });

    test('edita com PUT', () async {
      handler = (_) => FakeResponse(200, body: automationJson(id: 'a1'));

      await repository.update('a1', draft);

      expect(last().method, 'PUT');
      expect(last().path, '/automations/a1');
      expect(last().data, draft.toJson());
    });

    test('ativa/desativa com PATCH /toggle', () async {
      handler = (_) =>
          FakeResponse(200, body: automationJson(id: 'a1', enabled: false));

      final toggled = await repository.setEnabled('a1', enabled: false);

      expect(toggled.enabled, isFalse);
      expect(last().method, 'PATCH');
      expect(last().path, '/automations/a1/toggle');
      expect(last().data, {'enabled': false});
    });

    test('executa com POST /execute', () async {
      handler = (_) =>
          FakeResponse(200, body: {'message': 'Automation executed'});

      await repository.execute('a1');

      expect(last().method, 'POST');
      expect(last().path, '/automations/a1/execute');
    });

    test('exclui com DELETE (204)', () async {
      handler = (_) => FakeResponse(204, body: '');

      await repository.delete('a1');

      expect(last().method, 'DELETE');
      expect(last().path, '/automations/a1');
    });

    test('erros do backend chegam como ApiException', () async {
      handler = (_) =>
          FakeResponse(400, body: {'message': 'Invalid cron expression: bad'});

      await expectLater(
        repository.create(draft),
        throwsA(
          isA<BadRequestException>().having(
            (e) => e.message,
            'message',
            'Invalid cron expression: bad',
          ),
        ),
      );
    });
  });
}
