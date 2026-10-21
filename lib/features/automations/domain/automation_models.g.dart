// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'automation_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Automation _$AutomationFromJson(Map<String, dynamic> json) => _Automation(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  triggerType:
      $enumDecodeNullable(
        _$TriggerTypeEnumMap,
        json['triggerType'],
        unknownValue: TriggerType.manual,
      ) ??
      TriggerType.manual,
  cron: json['cron'] as String?,
  condition: json['condition'] as String?,
  action: json['action'] == null
      ? const AutomationAction()
      : AutomationAction.parse(json['action']),
  enabled: json['enabled'] as bool? ?? true,
  lastRunAt: json['lastRunAt'] == null
      ? null
      : DateTime.parse(json['lastRunAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  creatorName: _readCreatorName(json, 'creatorName') as String?,
);

Map<String, dynamic> _$AutomationToJson(_Automation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'triggerType': _$TriggerTypeEnumMap[instance.triggerType]!,
      'cron': instance.cron,
      'condition': instance.condition,
      'action': _actionToJson(instance.action),
      'enabled': instance.enabled,
      'lastRunAt': instance.lastRunAt?.toIso8601String(),
      'createdAt': instance.createdAt?.toIso8601String(),
      'creatorName': instance.creatorName,
    };

const _$TriggerTypeEnumMap = {
  TriggerType.schedule: 'SCHEDULE',
  TriggerType.condition: 'CONDITION',
  TriggerType.manual: 'MANUAL',
};

_AutomationRun _$AutomationRunFromJson(Map<String, dynamic> json) =>
    _AutomationRun(
      id: json['id'] as String,
      runAt: DateTime.parse(json['runAt'] as String),
      success: json['success'] as bool? ?? false,
      logs: json['logs'] as String?,
    );

Map<String, dynamic> _$AutomationRunToJson(_AutomationRun instance) =>
    <String, dynamic>{
      'id': instance.id,
      'runAt': instance.runAt.toIso8601String(),
      'success': instance.success,
      'logs': instance.logs,
    };
