import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/models/campus/campus_models.dart';
import 'schedule.dart';

part 'automation_models.freezed.dart';
part 'automation_models.g.dart';

/// Gatilho de uma automação (`TriggerType` do backend).
@JsonEnum(valueField: 'apiValue')
enum TriggerType {
  schedule('SCHEDULE', 'Agenda'),
  condition('CONDITION', 'Condição'),
  manual('MANUAL', 'Manual');

  const TriggerType(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

/// Comando de uma ação sobre dispositivo.
enum DeviceAction {
  on('on', 'ON', 'Ligar'),
  off('off', 'OFF', 'Desligar');

  const DeviceAction(this.apiValue, this.state, this.label);

  final String apiValue;

  /// Valor de `state` no payload MQTT (o mesmo do controle manual).
  final String state;
  final String label;

  static DeviceAction? fromApi(Object? value) {
    for (final action in values) {
      if (action.apiValue == value) return action;
    }
    return null;
  }
}

/// O que a automação faz: publicar [payload] em [topic] no MQTT. Quando
/// criada pelo app sobre um dispositivo, guarda também qual e o comando,
/// para a tela descrever e o formulário reabrir no mesmo modo.
@freezed
abstract class AutomationAction with _$AutomationAction {
  const AutomationAction._();

  const factory AutomationAction({
    String? topic,
    Map<String, dynamic>? payload,
    String? deviceId,
    String? deviceName,
    DeviceAction? command,
  }) = _AutomationAction;

  /// Ligar/desligar [device]: `{state}` em `{mqttTopic}/command`, igual ao
  /// controle manual do backend.
  factory AutomationAction.forDevice(Device device, DeviceAction command) =>
      AutomationAction(
        topic: '${device.mqttTopic!.trim()}/command',
        payload: {'state': command.state},
        deviceId: device.id,
        deviceName: device.name,
        command: command,
      );

  /// Lê o campo `action` do backend (string JSON ou objeto). Formato
  /// ilegível vira uma ação vazia em vez de derrubar a lista.
  static AutomationAction parse(Object? raw) {
    Object? decoded = raw;
    if (raw is String) {
      try {
        decoded = jsonDecode(raw);
      } on FormatException {
        return const AutomationAction();
      }
    }
    if (decoded is! Map) return const AutomationAction();
    final payload = decoded['payload'];
    return AutomationAction(
      topic: decoded['topic'] as String?,
      payload: payload is Map ? Map<String, dynamic>.from(payload) : null,
      deviceId: decoded['deviceId'] as String?,
      deviceName: decoded['deviceName'] as String?,
      command: DeviceAction.fromApi(decoded['command']),
    );
  }

  /// Só dispositivos com tópico MQTT recebem comandos.
  static bool canTarget(Device device) =>
      (device.mqttTopic?.trim().isNotEmpty) ?? false;

  bool get isDeviceCommand => deviceId != null && command != null;

  /// JSON enviado ao backend (como string, que o DTO aceita sem validar
  /// campos aninhados).
  String encode() => jsonEncode({
    'type': 'mqtt',
    'topic': ?topic,
    'payload': payload ?? const <String, dynamic>{},
    'deviceId': ?deviceId,
    'deviceName': ?deviceName,
    'command': ?command?.apiValue,
  });

  String describe() {
    if (isDeviceCommand) {
      return '${command!.label} ${deviceName ?? 'dispositivo'}';
    }
    if (topic != null) return 'Publicar em $topic';
    return 'Ação personalizada';
  }
}

/// Automação (`GET /automations`, `GET /automations/:id`).
@freezed
abstract class Automation with _$Automation {
  const Automation._();

  const factory Automation({
    required String id,
    required String name,
    String? description,
    @JsonKey(unknownEnumValue: TriggerType.manual)
    @Default(TriggerType.manual)
    TriggerType triggerType,
    String? cron,
    String? condition,
    @JsonKey(fromJson: AutomationAction.parse, toJson: _actionToJson)
    @Default(AutomationAction())
    AutomationAction action,
    @Default(true) bool enabled,
    DateTime? lastRunAt,
    DateTime? createdAt,
    @JsonKey(readValue: _readCreatorName) String? creatorName,
  }) = _Automation;

  factory Automation.fromJson(Map<String, dynamic> json) =>
      _$AutomationFromJson(json);

  /// "Seg a Sex às 07:30", "Execução manual"...
  String get triggerSummary => switch (triggerType) {
    TriggerType.schedule =>
      cron == null ? 'Agenda sem horário' : describeCron(cron!),
    TriggerType.manual => 'Execução manual',
    TriggerType.condition => 'Condição: ${condition ?? '—'}',
  };
}

String _actionToJson(AutomationAction action) => action.encode();

Object? _readCreatorName(Map<dynamic, dynamic> json, String key) {
  final creator = json['creator'];
  return creator is Map ? creator['name'] : null;
}

/// Uma execução (`GET /automations/:id/history`).
@freezed
abstract class AutomationRun with _$AutomationRun {
  const factory AutomationRun({
    required String id,
    required DateTime runAt,
    @Default(false) bool success,
    String? logs,
  }) = _AutomationRun;

  factory AutomationRun.fromJson(Map<String, dynamic> json) =>
      _$AutomationRunFromJson(json);
}

/// O que o formulário envia em `POST /automations` e `PUT /automations/:id`.
@immutable
class AutomationDraft {
  const AutomationDraft({
    required this.name,
    required this.description,
    required this.triggerType,
    required this.cron,
    required this.action,
  });

  factory AutomationDraft.fromAutomation(Automation automation) =>
      AutomationDraft(
        name: automation.name,
        description: automation.description ?? '',
        triggerType: automation.triggerType,
        cron: automation.cron,
        action: automation.action,
      );

  final String name;
  final String description;
  final TriggerType triggerType;

  /// Só vale para [TriggerType.schedule].
  final String? cron;
  final AutomationAction action;

  Map<String, dynamic> toJson() => {
    'name': name.trim(),
    'description': description.trim(),
    'triggerType': triggerType.apiValue,
    if (triggerType == TriggerType.schedule) 'cron': cron?.trim(),
    'action': action.encode(),
  };
}
