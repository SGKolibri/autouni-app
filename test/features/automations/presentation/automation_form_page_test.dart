import 'dart:convert';

import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/features/automations/data/automations_repository.dart';
import 'package:autouni_app/features/automations/domain/automation_models.dart';
import 'package:autouni_app/features/automations/presentation/pages/automation_form_page.dart';
import 'package:autouni_app/shared/devices/device_repository.dart';
import 'package:autouni_app/shared/models/campus/campus_models.dart';
import 'package:autouni_app/shared/models/user_role.dart';
import 'package:autouni_app/shared/rbac/rbac_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/automation_fixtures.dart';
import '../../../support/pump_router_app.dart';

class _MockRepository extends Mock implements AutomationsRepository {}

class _MockDeviceRepository extends Mock implements DeviceRepository {}

const _lamp = Device(
  id: 'd1',
  name: 'Luminária 101',
  roomId: 'r1',
  mqttTopic: 'bloco-a/101/lum',
);
const _ac = Device(
  id: 'd2',
  name: 'Ar 102',
  roomId: 'r2',
  mqttTopic: 'bloco-a/102/ac',
);
const _sensor = Device(id: 'd3', name: 'Sensor sem MQTT', roomId: 'r1');

void main() {
  late _MockRepository repository;
  late _MockDeviceRepository devices;
  AutomationDraft? sent;

  setUpAll(
    () => registerFallbackValue(
      const AutomationDraft(
        name: '',
        description: '',
        triggerType: TriggerType.manual,
        cron: null,
        action: AutomationAction(),
      ),
    ),
  );

  setUp(() {
    sent = null;
    repository = _MockRepository();
    devices = _MockDeviceRepository();
    when(() => devices.watchAll())
        .thenAnswer((_) => Stream.value(const Cached([_sensor, _lamp, _ac])));
    when(() => repository.create(any())).thenAnswer((invocation) async {
      sent = invocation.positionalArguments.single as AutomationDraft;
      return Automation.fromJson(automationJson(id: 'nova'));
    });
    when(() => repository.update(any(), any())).thenAnswer((invocation) async {
      sent = invocation.positionalArguments[1] as AutomationDraft;
      return Automation.fromJson(automationJson(id: 'a1'));
    });
    when(() => repository.watchAll())
        .thenAnswer((_) => Stream.value(const Cached(<Automation>[])));
  });

  Future<GoRouter> pumpForm(
    WidgetTester tester, {
    String? editId,
    UserRole role = UserRole.technician,
  }) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (_, router) = await tester.pumpRouterApp(
      initialLocation: '/automations',
      routes: [
        GoRoute(
          path: '/automations',
          builder: (_, _) => const Scaffold(body: Text('lista')),
          routes: [
            GoRoute(path: 'new', builder: (_, _) => const AutomationFormPage()),
            GoRoute(
              path: ':id',
              builder: (_, state) =>
                  Scaffold(body: Text('detalhe ${state.pathParameters['id']}')),
              routes: [
                GoRoute(
                  path: 'edit',
                  builder: (_, state) => AutomationFormPage(
                    automationId: state.pathParameters['id'],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
      overrides: [
        automationsRepositoryProvider.overrideWithValue(repository),
        deviceRepositoryProvider.overrideWithValue(devices),
        currentUserRoleProvider.overrideWithValue(role),
      ],
    );
    router.push(
      editId == null ? AppPaths.newAutomation : AppPaths.editAutomation(editId),
    );
    await tester.pumpAndSettle();
    return router;
  }

  Future<void> pickDevice(WidgetTester tester, String id) async {
    await tester.tap(find.byKey(const Key('automation-device')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('pick-$id')));
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    await tester.ensureVisible(find.byKey(const Key('automation-save')));
    await tester.tap(find.byKey(const Key('automation-save')));
    await tester.pumpAndSettle();
  }

  group('criar (S5-T4)', () {
    testWidgets('agenda pelo construtor + dispositivo vira cron e ação MQTT', (
      tester,
    ) async {
      final router = await pumpForm(tester);

      await tester.enterText(
        find.byKey(const Key('automation-name')),
        'Desligar luz à noite',
      );
      expect(find.text('Seg a Sex às 22:00 · cron 0 22 * * 1-5'), findsOne);
      // adiciona o sábado
      await tester.tap(find.byKey(const ValueKey('day-saturday')));
      await tester.pump();
      expect(find.text('Seg a Sáb às 22:00 · cron 0 22 * * 1-6'), findsOne);

      await pickDevice(tester, 'd1');
      expect(find.text('Luminária 101'), findsOneWidget);
      await save(tester);

      expect(sent!.toJson(), {
        'name': 'Desligar luz à noite',
        'description': '',
        'triggerType': 'SCHEDULE',
        'cron': '0 22 * * 1-6',
        'action': jsonEncode({
          'type': 'mqtt',
          'topic': 'bloco-a/101/lum/command',
          'payload': {'state': 'OFF'},
          'deviceId': 'd1',
          'deviceName': 'Luminária 101',
          'command': 'off',
        }),
      });
      expect(router.state.uri.path, AppPaths.automation('nova'));
      expect(find.text('Automação criada.'), findsOneWidget);
    });

    testWidgets('o seletor só lista dispositivos com MQTT e filtra por nome', (
      tester,
    ) async {
      await pumpForm(tester);

      await tester.tap(find.byKey(const Key('automation-device')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('pick-d3')), findsNothing);
      expect(find.byKey(const ValueKey('pick-d1')), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('device-picker-search')),
        'ar',
      );
      await tester.pump();
      expect(find.byKey(const ValueKey('pick-d1')), findsNothing);
      expect(find.byKey(const ValueKey('pick-d2')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('device-picker-search')),
        'nada',
      );
      await tester.pump();
      expect(find.text('Nenhum dispositivo encontrado'), findsOneWidget);
    });

    testWidgets('comando "Ligar" publica state ON', (tester) async {
      await pumpForm(tester);
      await tester.enterText(
        find.byKey(const Key('automation-name')),
        'Ligar ar',
      );
      await tester.tap(find.text('Ligar'));
      await pickDevice(tester, 'd2');
      await save(tester);

      expect(sent!.action.payload, {'state': 'ON'});
      expect(sent!.action.command, DeviceAction.on);
      expect(sent!.action.topic, 'bloco-a/102/ac/command');
    });

    testWidgets('manual com MQTT avançado não envia cron', (tester) async {
      await pumpForm(tester);
      await tester.enterText(
        find.byKey(const Key('automation-name')),
        'Cena de aula',
      );
      await tester.tap(find.text('Manual'));
      await tester.pump();
      expect(find.byKey(const ValueKey('day-monday')), findsNothing);

      await tester.tap(find.text('MQTT avançado'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('automation-topic')),
        'bloco-a/101/cena',
      );
      await tester.enterText(
        find.byKey(const Key('automation-payload')),
        '{"scene": "aula"}',
      );
      await save(tester);

      final json = sent!.toJson();
      expect(json['triggerType'], 'MANUAL');
      expect(json.containsKey('cron'), isFalse);
      expect(jsonDecode(json['action'] as String), {
        'type': 'mqtt',
        'topic': 'bloco-a/101/cena',
        'payload': {'scene': 'aula'},
      });
    });

    testWidgets('cron avançado: valida e envia a expressão digitada', (
      tester,
    ) async {
      await pumpForm(tester);
      await tester.enterText(
        find.byKey(const Key('automation-name')),
        'A cada 15 min',
      );
      await tester.tap(find.byKey(const Key('automation-advanced-cron')));
      await tester.pump();
      expect(
        tester
            .widget<TextField>(
              find.descendant(
                of: find.byKey(const Key('automation-cron')),
                matching: find.byType(TextField),
              ),
            )
            .controller!
            .text,
        '0 22 * * 1-5',
      );

      await tester.enterText(
        find.byKey(const Key('automation-cron')),
        '*/15 8-18 * * 99',
      );
      await pickDevice(tester, 'd1');
      await save(tester);
      expect(find.text('Dia da semana inválido (use 0–7).'), findsOneWidget);
      verifyNever(() => repository.create(any()));

      await tester.enterText(
        find.byKey(const Key('automation-cron')),
        '*/15 8-18 * * 1-5',
      );
      await save(tester);

      expect(sent!.cron, '*/15 8-18 * * 1-5');
    });

    testWidgets('voltar do cron avançado reabre a agenda equivalente', (
      tester,
    ) async {
      await pumpForm(tester);
      await tester.tap(find.byKey(const Key('automation-advanced-cron')));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('automation-cron')),
        '30 7 * * 0,6',
      );
      await tester.tap(find.byKey(const Key('automation-advanced-cron')));
      await tester.pump();

      expect(
        find.text('Fins de semana às 07:30 · cron 30 7 * * 0,6'),
        findsOneWidget,
      );
    });

    testWidgets('validações: nome, dias e dispositivo; nada é enviado', (
      tester,
    ) async {
      await pumpForm(tester);
      for (final day in [
        'monday',
        'tuesday',
        'wednesday',
        'thursday',
        'friday',
      ]) {
        await tester.tap(find.byKey(ValueKey('day-$day')));
        await tester.pump();
      }
      await save(tester);

      expect(find.text('Informe um nome.'), findsOneWidget);
      expect(find.text('Escolha pelo menos um dia.'), findsOneWidget);
      expect(find.text('Escolha o dispositivo.'), findsOneWidget);
      verifyNever(() => repository.create(any()));
    });

    testWidgets('validações do MQTT avançado', (tester) async {
      await pumpForm(tester);
      await tester.enterText(find.byKey(const Key('automation-name')), 'Teste');
      await tester.tap(find.text('MQTT avançado'));
      await tester.pump();
      await tester.enterText(
        find.byKey(const Key('automation-payload')),
        '{quebrado',
      );
      await save(tester);

      expect(find.text('Informe o tópico MQTT.'), findsOneWidget);
      expect(find.text('JSON inválido.'), findsOneWidget);
      verifyNever(() => repository.create(any()));
    });

    testWidgets('erro do backend aparece e o formulário continua', (
      tester,
    ) async {
      when(() => repository.create(any())).thenThrow(
        const BadRequestException(message: 'Invalid cron expression'),
      );
      final router = await pumpForm(tester);
      await tester.enterText(find.byKey(const Key('automation-name')), 'Teste');
      await pickDevice(tester, 'd1');
      await save(tester);

      expect(find.text('Invalid cron expression'), findsOneWidget);
      expect(router.state.uri.path, AppPaths.newAutomation);
    });

    testWidgets('horário pelo seletor', (tester) async {
      await pumpForm(tester);
      await tester.tap(find.byKey(const Key('schedule-time')));
      await tester.pumpAndSettle();
      // modo digitação do seletor de horário
      await tester.tap(find.byIcon(Icons.keyboard_outlined));
      await tester.pumpAndSettle();
      final fields = find.descendant(
        of: find.byType(TimePickerDialog),
        matching: find.byType(TextField),
      );
      await tester.enterText(fields.at(0), '07');
      await tester.enterText(fields.at(1), '45');
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Seg a Sex às 07:45 · cron 45 7 * * 1-5'), findsOne);
    });
  });

  group('editar', () {
    testWidgets('abre preenchido e salva com PUT', (tester) async {
      when(() => repository.watchOne('a1')).thenAnswer(
        (_) => Stream.value(
          Cached(
            Automation.fromJson(automationJson(id: 'a1', cron: '30 7 * * 1-5')),
          ),
        ),
      );
      final router = await pumpForm(tester, editId: 'a1');

      expect(find.text('Editar automação'), findsOneWidget);
      expect(find.text('Desligar luzes à noite'), findsOneWidget);
      expect(find.text('Seg a Sex às 07:30 · cron 30 7 * * 1-5'), findsOne);
      expect(find.text('Luminária 1'), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('automation-name')),
        'Desligar cedo',
      );
      await save(tester);

      verify(() => repository.update('a1', any())).called(1);
      expect(sent!.name, 'Desligar cedo');
      expect(sent!.cron, '30 7 * * 1-5');
      expect(sent!.action.deviceId, 'd1');
      expect(sent!.action.command, DeviceAction.off);
      expect(router.state.uri.path, '/automations');
      expect(find.text('Automação salva.'), findsOneWidget);
    });

    testWidgets('cron fora do construtor abre no modo avançado', (
      tester,
    ) async {
      when(() => repository.watchOne('a1')).thenAnswer(
        (_) => Stream.value(
          Cached(
            Automation.fromJson(automationJson(id: 'a1', cron: '*/10 * * * *')),
          ),
        ),
      );
      await pumpForm(tester, editId: 'a1');

      expect(find.byKey(const Key('automation-cron')), findsOneWidget);
      expect(find.text('*/10 * * * *'), findsOneWidget);
    });

    testWidgets('ação avançada abre no modo MQTT com o payload', (
      tester,
    ) async {
      when(() => repository.watchOne('a1')).thenAnswer(
        (_) => Stream.value(
          Cached(
            Automation.fromJson(
              automationJson(
                id: 'a1',
                triggerType: 'MANUAL',
                cron: null,
                action: {
                  'topic': 'x/y',
                  'payload': {'a': 1},
                },
              ),
            ),
          ),
        ),
      );
      await pumpForm(tester, editId: 'a1');

      expect(find.text('x/y'), findsOneWidget);
      expect(find.textContaining('"a": 1'), findsOneWidget);
    });

    testWidgets('gatilho por condição avisa que vai mudar', (tester) async {
      when(() => repository.watchOne('a1')).thenAnswer(
        (_) => Stream.value(
          Cached(
            Automation.fromJson(
              automationJson(id: 'a1', triggerType: 'CONDITION', cron: null),
            ),
          ),
        ),
      );
      await pumpForm(tester, editId: 'a1');

      expect(find.textContaining('gatilho por condição'), findsOneWidget);
    });
  });

  testWidgets('VIEWER não vê o formulário', (tester) async {
    await pumpForm(tester, role: UserRole.viewer);

    expect(find.text('Somente leitura'), findsOneWidget);
    expect(find.byKey(const Key('automation-save')), findsNothing);
  });
}
