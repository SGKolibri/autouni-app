import 'dart:convert';

import 'package:autouni_app/features/automations/domain/automation_models.dart';
import 'package:autouni_app/shared/models/campus/campus_models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/automation_fixtures.dart';

void main() {
  group('Automation.fromJson', () {
    test('lê a automação com a ação serializada em string', () {
      final automation = Automation.fromJson(
        automationJson(lastRunAt: '2026-10-20T22:00:00.000Z'),
      );

      expect(automation.id, 'a1');
      expect(automation.triggerType, TriggerType.schedule);
      expect(automation.cron, '0 22 * * *');
      expect(automation.enabled, isTrue);
      expect(automation.lastRunAt, DateTime.utc(2026, 10, 20, 22));
      expect(automation.creatorName, 'Ana');
      expect(automation.action.topic, 'bloco-a/lum-1/command');
      expect(automation.action.payload, {'state': 'OFF'});
      expect(automation.action.deviceId, 'd1');
      expect(automation.action.command, DeviceAction.off);
    });

    test('aceita a ação como objeto', () {
      final automation = Automation.fromJson(
        automationJson(
          action: {
            'topic': 't',
            'payload': {'x': 1},
          },
        ),
      );

      expect(automation.action.topic, 't');
      expect(automation.action.payload, {'x': 1});
      expect(automation.action.deviceId, isNull);
    });

    test('ação ilegível não derruba a lista', () {
      final automation = Automation.fromJson(
        automationJson(action: 'nao-json'),
      );

      expect(automation.action.topic, isNull);
      expect(automation.action.describe(), 'Ação personalizada');
    });

    test('gatilho desconhecido vira manual; mínimo de campos', () {
      final automation = Automation.fromJson({
        'id': 'a2',
        'name': 'X',
        'triggerType': 'WEBHOOK',
        'action': '{}',
      });

      expect(automation.triggerType, TriggerType.manual);
      expect(automation.enabled, isTrue);
      expect(automation.creatorName, isNull);
    });
  });

  group('Automation.triggerSummary', () {
    test('agenda, manual e condição', () {
      expect(
        Automation.fromJson(automationJson(cron: '30 7 * * 1-5'))
            .triggerSummary,
        'Seg a Sex às 07:30',
      );
      expect(
        Automation.fromJson(automationJson(triggerType: 'MANUAL', cron: null))
            .triggerSummary,
        'Execução manual',
      );
      expect(
        Automation.fromJson({
          ...automationJson(triggerType: 'CONDITION', cron: null),
          'condition': 'temperature > 25',
        }).triggerSummary,
        'Condição: temperature > 25',
      );
      expect(
        Automation.fromJson(automationJson(cron: null)).triggerSummary,
        'Agenda sem horário',
      );
    });
  });

  group('AutomationAction', () {
    const lamp = Device(
      id: 'd1',
      name: 'Luminária 1',
      roomId: 'r1',
      mqttTopic: 'bloco-a/lum-1',
    );

    test('comando de dispositivo publica {state} no tópico de comando', () {
      final action = AutomationAction.forDevice(lamp, DeviceAction.on);

      expect(action.topic, 'bloco-a/lum-1/command');
      expect(action.payload, {'state': 'ON'});
      expect(action.deviceId, 'd1');
      expect(action.deviceName, 'Luminária 1');
      expect(action.command, DeviceAction.on);
    });

    test('encode gera o JSON do backend (type mqtt)', () {
      final encoded = jsonDecode(
        AutomationAction.forDevice(lamp, DeviceAction.off).encode(),
      );

      expect(encoded, {
        'type': 'mqtt',
        'topic': 'bloco-a/lum-1/command',
        'payload': {'state': 'OFF'},
        'deviceId': 'd1',
        'deviceName': 'Luminária 1',
        'command': 'off',
      });
    });

    test('ação avançada: só tópico e payload', () {
      const action = AutomationAction(topic: 'x/y', payload: {'a': 1});

      expect(jsonDecode(action.encode()), {
        'type': 'mqtt',
        'topic': 'x/y',
        'payload': {'a': 1},
      });
      expect(action.describe(), 'Publicar em x/y');
    });

    test('descrição', () {
      expect(
        AutomationAction.forDevice(lamp, DeviceAction.on).describe(),
        'Ligar Luminária 1',
      );
      expect(
        AutomationAction.forDevice(lamp, DeviceAction.off).describe(),
        'Desligar Luminária 1',
      );
    });

    test('dispositivo sem tópico MQTT não pode ser alvo', () {
      expect(AutomationAction.canTarget(lamp), isTrue);
      expect(
        AutomationAction.canTarget(lamp.copyWith(mqttTopic: null)),
        isFalse,
      );
      expect(
        AutomationAction.canTarget(lamp.copyWith(mqttTopic: '  ')),
        isFalse,
      );
    });
  });

  group('AutomationRun', () {
    test('lê o histórico', () {
      final run = AutomationRun.fromJson(const {
        'id': 'h1',
        'automationId': 'a1',
        'runAt': '2026-10-20T22:00:00.000Z',
        'success': false,
        'logs': 'Error: MQTT connection failed',
      });

      expect(run.runAt, DateTime.utc(2026, 10, 20, 22));
      expect(run.success, isFalse);
      expect(run.logs, 'Error: MQTT connection failed');
    });
  });

  group('AutomationDraft.toJson', () {
    final action = AutomationAction.forDevice(
      const Device(id: 'd1', name: 'Ar', roomId: 'r1', mqttTopic: 'ac'),
      DeviceAction.off,
    );

    test('agenda: nome aparado, cron e ação em string', () {
      final json = AutomationDraft(
        name: '  Desligar ar  ',
        description: '',
        triggerType: TriggerType.schedule,
        cron: '0 22 * * 1-5',
        action: action,
      ).toJson();

      expect(json, {
        'name': 'Desligar ar',
        'description': '',
        'triggerType': 'SCHEDULE',
        'cron': '0 22 * * 1-5',
        'action': action.encode(),
      });
    });

    test('manual não envia cron', () {
      final json = AutomationDraft(
        name: 'Ligar',
        description: 'agora',
        triggerType: TriggerType.manual,
        cron: '0 22 * * *',
        action: action,
      ).toJson();

      expect(json.containsKey('cron'), isFalse);
      expect(json['triggerType'], 'MANUAL');
      expect(json['description'], 'agora');
    });

    test('rascunho a partir de uma automação existente', () {
      final draft = AutomationDraft.fromAutomation(
        Automation.fromJson(automationJson()),
      );

      expect(draft.name, 'Desligar luzes à noite');
      expect(draft.description, 'Bloco A');
      expect(draft.triggerType, TriggerType.schedule);
      expect(draft.cron, '0 22 * * *');
      expect(draft.action.deviceId, 'd1');
    });
  });
}
