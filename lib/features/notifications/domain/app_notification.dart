import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../shared/models/notification_type.dart';

part 'app_notification.freezed.dart';
part 'app_notification.g.dart';

/// Notificação do usuário (`GET /notifications/user/:userId`).
@freezed
abstract class AppNotification with _$AppNotification {
  const AppNotification._();

  const factory AppNotification({
    required String id,
    @JsonKey(unknownEnumValue: NotificationType.info)
    @Default(NotificationType.info)
    NotificationType type,
    required String title,
    @Default('') String message,
    @Default(false) bool read,

    /// Caminho de destino no formato da API (ex.: `/devices/<id>`).
    String? link,
    DateTime? createdAt,
  }) = _AppNotification;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      _$AppNotificationFromJson(json);

  bool get hasLink => link?.trim().isNotEmpty ?? false;
}
