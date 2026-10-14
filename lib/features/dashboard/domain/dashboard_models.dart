import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/models/campus/campus_models.dart';
import '../../../shared/models/notification_type.dart';

part 'dashboard_models.freezed.dart';
part 'dashboard_models.g.dart';

/// Consumo do período (`GET /energy/stats?period=today`).
@freezed
abstract class EnergySummary with _$EnergySummary {
  const factory EnergySummary({
    @Default(0) double todayEnergyKwh,
    @Default(false) bool hasData,
    DateTime? lastReadingAt,
  }) = _EnergySummary;

  factory EnergySummary.fromJson(Map<String, dynamic> json) =>
      _$EnergySummaryFromJson(json);
}

/// Notificação do usuário (`GET /notifications/me`), usada nos alertas
/// recentes.
@freezed
abstract class DashboardAlert with _$DashboardAlert {
  const factory DashboardAlert({
    required String id,
    @JsonKey(unknownEnumValue: NotificationType.info)
    @Default(NotificationType.info)
    NotificationType type,
    required String title,
    @Default('') String message,
    @Default(false) bool read,
    String? link,
    DateTime? createdAt,
  }) = _DashboardAlert;

  factory DashboardAlert.fromJson(Map<String, dynamic> json) =>
      _$DashboardAlertFromJson(json);
}

/// Tudo o que o dashboard mostra.
class DashboardOverview {
  const DashboardOverview({
    required this.buildings,
    required this.energy,
    required this.alerts,
  });

  /// Prédios com a árvore completa — fonte das contagens de dispositivos.
  final List<Building> buildings;

  /// `null` se o consumo não pôde ser carregado.
  final EnergySummary? energy;

  /// Mais recentes primeiro. Vazio se os alertas não puderam ser carregados.
  final List<DashboardAlert> alerts;

  int get unreadAlerts => alerts.where((alert) => !alert.read).length;

  Iterable<Device> get allDevices => buildings.expand(
    (b) => b.floors.expand((f) => f.rooms.expand((r) => r.devices)),
  );
}
