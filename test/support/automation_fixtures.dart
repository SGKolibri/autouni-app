import 'dart:convert';

/// JSON de automação no formato do backend (ação serializada em string).
Map<String, dynamic> automationJson({
  String id = 'a1',
  String triggerType = 'SCHEDULE',
  String? cron = '0 22 * * *',
  Object? action,
  bool enabled = true,
  String? lastRunAt,
}) => {
  'id': id,
  'name': 'Desligar luzes à noite',
  'description': 'Bloco A',
  'triggerType': triggerType,
  'cron': cron,
  'condition': null,
  'action':
      action ??
      jsonEncode({
        'type': 'mqtt',
        'topic': 'bloco-a/lum-1/command',
        'payload': {'state': 'OFF'},
        'deviceId': 'd1',
        'deviceName': 'Luminária 1',
        'command': 'off',
      }),
  'enabled': enabled,
  'lastRunAt': lastRunAt,
  'createdAt': '2026-10-01T10:00:00.000Z',
  'creator': {'id': 'u1', 'name': 'Ana', 'email': 'ana@uni.br'},
};
