import 'package:flutter/foundation.dart';

import '../../../shared/models/notification_type.dart';
import '../../../shared/utils/formatters.dart';
import 'app_notification.dart';

/// Filtro da central: por tipo e/ou só não lidas.
@immutable
class NotificationFilter {
  const NotificationFilter({this.type, this.unreadOnly = false});

  final NotificationType? type;
  final bool unreadOnly;

  bool get isEmpty => type == null && !unreadOnly;

  NotificationFilter copyWith({
    NotificationType? type,
    bool clearType = false,
    bool? unreadOnly,
  }) => NotificationFilter(
    type: clearType ? null : type ?? this.type,
    unreadOnly: unreadOnly ?? this.unreadOnly,
  );

  /// Mantém a ordem de [items].
  List<AppNotification> apply(List<AppNotification> items) => [
    for (final item in items)
      if ((type == null || item.type == type) && (!unreadOnly || !item.read))
        item,
  ];

  @override
  bool operator ==(Object other) =>
      other is NotificationFilter &&
      other.type == type &&
      other.unreadOnly == unreadOnly;

  @override
  int get hashCode => Object.hash(type, unreadOnly);
}

/// Um dia da lista ("Hoje", "Ontem", "03/10").
class NotificationDay {
  const NotificationDay(this.label, this.items);

  final String label;
  final List<AppNotification> items;
}

/// Agrupa por dia local, na ordem recebida (mais recentes primeiro).
List<NotificationDay> groupByDay(
  List<AppNotification> items, {
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  String labelOf(DateTime? instant) {
    if (instant == null) return 'Antes';
    final local = instant.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hoje';
    if (diff == 1) return 'Ontem';
    return formatDayMonth(local);
  }

  final groups = <NotificationDay>[];
  for (final item in items) {
    final label = labelOf(item.createdAt);
    if (groups.isNotEmpty && groups.last.label == label) {
      groups.last.items.add(item);
    } else {
      groups.add(NotificationDay(label, [item]));
    }
  }
  return groups;
}
