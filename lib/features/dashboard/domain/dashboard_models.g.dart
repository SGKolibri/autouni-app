// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EnergySummary _$EnergySummaryFromJson(Map<String, dynamic> json) =>
    _EnergySummary(
      todayEnergyKwh: (json['todayEnergyKwh'] as num?)?.toDouble() ?? 0,
      hasData: json['hasData'] as bool? ?? false,
      lastReadingAt: json['lastReadingAt'] == null
          ? null
          : DateTime.parse(json['lastReadingAt'] as String),
    );

Map<String, dynamic> _$EnergySummaryToJson(_EnergySummary instance) =>
    <String, dynamic>{
      'todayEnergyKwh': instance.todayEnergyKwh,
      'hasData': instance.hasData,
      'lastReadingAt': instance.lastReadingAt?.toIso8601String(),
    };

_DashboardAlert _$DashboardAlertFromJson(Map<String, dynamic> json) =>
    _DashboardAlert(
      id: json['id'] as String,
      type:
          $enumDecodeNullable(
            _$NotificationTypeEnumMap,
            json['type'],
            unknownValue: NotificationType.info,
          ) ??
          NotificationType.info,
      title: json['title'] as String,
      message: json['message'] as String? ?? '',
      read: json['read'] as bool? ?? false,
      link: json['link'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$DashboardAlertToJson(_DashboardAlert instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$NotificationTypeEnumMap[instance.type]!,
      'title': instance.title,
      'message': instance.message,
      'read': instance.read,
      'link': instance.link,
      'createdAt': instance.createdAt?.toIso8601String(),
    };

const _$NotificationTypeEnumMap = {
  NotificationType.info: 'INFO',
  NotificationType.warning: 'WARNING',
  NotificationType.error: 'ERROR',
  NotificationType.success: 'SUCCESS',
};
