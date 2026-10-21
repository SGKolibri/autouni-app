// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'energy_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_EnergyStats _$EnergyStatsFromJson(Map<String, dynamic> json) => _EnergyStats(
  totalKwh: (json['totalKwh'] as num?)?.toDouble() ?? 0,
  readingCount: (json['count'] as num?)?.toInt() ?? 0,
  avgWh: (json['avgWh'] as num?)?.toDouble(),
  maxWh: (json['maxWh'] as num?)?.toDouble(),
  minWh: (json['minWh'] as num?)?.toDouble(),
  totalDevices: (json['totalDevices'] as num?)?.toInt(),
  activeDevices: (json['activeDevices'] as num?)?.toInt(),
  reportedHasData: json['hasData'] as bool?,
);

Map<String, dynamic> _$EnergyStatsToJson(_EnergyStats instance) =>
    <String, dynamic>{
      'totalKwh': instance.totalKwh,
      'count': instance.readingCount,
      'avgWh': instance.avgWh,
      'maxWh': instance.maxWh,
      'minWh': instance.minWh,
      'totalDevices': instance.totalDevices,
      'activeDevices': instance.activeDevices,
      'hasData': instance.reportedHasData,
    };

_EnergyHistoryPoint _$EnergyHistoryPointFromJson(Map<String, dynamic> json) =>
    _EnergyHistoryPoint(
      bucket: DateTime.parse(json['bucket'] as String),
      totalKwh: (json['totalKwh'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$EnergyHistoryPointToJson(_EnergyHistoryPoint instance) =>
    <String, dynamic>{
      'bucket': instance.bucket.toIso8601String(),
      'totalKwh': instance.totalKwh,
      'count': instance.count,
    };

_EnergyRankingItem _$EnergyRankingItemFromJson(Map<String, dynamic> json) =>
    _EnergyRankingItem(
      id: json['id'] as String,
      name: _displayName(json['name']),
      totalKwh: (json['totalKwh'] as num?)?.toDouble() ?? 0,
    );

Map<String, dynamic> _$EnergyRankingItemToJson(_EnergyRankingItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'totalKwh': instance.totalKwh,
    };
