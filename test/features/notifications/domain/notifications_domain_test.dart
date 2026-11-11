import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/features/notifications/domain/app_notification.dart';
import 'package:autouni_app/features/notifications/domain/notification_filter.dart';
import 'package:autouni_app/features/notifications/domain/notification_link.dart';
import 'package:autouni_app/shared/models/notification_type.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _n(
  String id, {
  NotificationType type = NotificationType.info,
  bool read = false,
  DateTime? createdAt,
}) => AppNotification(
  id: id,
  type: type,
  title: 'T $id',
  read: read,
  createdAt: createdAt ?? DateTime(2026, 10, 21, 9),
);

void main() {
  group('AppNotification.fromJson', () {
    test('lê a notificação do backend', () {
      final notification = AppNotification.fromJson(const {
        'id': 'n1',
        'userId': 'u1',
        'type': 'WARNING',
        'title': 'Ar ligado fora do horário',
        'message': 'Sala 101',
        'read': false,
        'link': '/devices/d1',
        'createdAt': '2026-10-21T08:00:00.000Z',
      });

      expect(notification.type, NotificationType.warning);
      expect(notification.title, 'Ar ligado fora do horário');
      expect(notification.message, 'Sala 101');
      expect(notification.read, isFalse);
      expect(notification.link, '/devices/d1');
      expect(notification.createdAt, DateTime.utc(2026, 10, 21, 8));
      expect(notification.hasLink, isTrue);
    });

    test('mínimo: tipo desconhecido vira INFO, sem link', () {
      final notification = AppNotification.fromJson(const {
        'id': 'n2',
        'type': 'PANIC',
        'title': 'X',
        'link': '  ',
      });

      expect(notification.type, NotificationType.info);
      expect(notification.message, '');
      expect(notification.hasLink, isFalse);
    });
  });

  group('NotificationFilter', () {
    final all = [
      _n('a', type: NotificationType.warning),
      _n('b', type: NotificationType.error, read: true),
      _n('c', type: NotificationType.warning, read: true),
      _n('d', type: NotificationType.success),
    ];

    test('sem filtro, tudo', () {
      expect(const NotificationFilter().apply(all).map((n) => n.id), [
        'a',
        'b',
        'c',
        'd',
      ]);
      expect(const NotificationFilter().isEmpty, isTrue);
    });

    test('só não lidas', () {
      expect(
        const NotificationFilter(unreadOnly: true).apply(all).map((n) => n.id),
        ['a', 'd'],
      );
    });

    test('por tipo, combinável com não lidas', () {
      const warnings = NotificationFilter(type: NotificationType.warning);
      expect(warnings.apply(all).map((n) => n.id), ['a', 'c']);
      expect(warnings.copyWith(unreadOnly: true).apply(all).map((n) => n.id), [
        'a',
      ]);
    });

    test('copyWith limpa o tipo com clearType', () {
      const warnings = NotificationFilter(type: NotificationType.warning);

      expect(warnings.copyWith(clearType: true).type, isNull);
      expect(
        warnings.copyWith(unreadOnly: true).type,
        NotificationType.warning,
      );
    });
  });

  group('groupByDay', () {
    final now = DateTime(2026, 10, 21, 15);

    test('Hoje, Ontem e data, na ordem recebida', () {
      final groups = groupByDay([
        _n('a', createdAt: DateTime(2026, 10, 21, 14)),
        _n('b', createdAt: DateTime(2026, 10, 21, 8)),
        _n('c', createdAt: DateTime(2026, 10, 20, 23)),
        _n('d', createdAt: DateTime(2026, 10, 3, 10)),
      ], now: now);

      expect(groups.map((g) => g.label), ['Hoje', 'Ontem', '03/10']);
      expect(groups.first.items.map((n) => n.id), ['a', 'b']);
    });

    test('sem data vai para "Antes"', () {
      final groups = groupByDay([
        const AppNotification(id: 'x', title: 'x'),
      ], now: now);

      expect(groups.single.label, 'Antes');
    });
  });

  group('classifyLink', () {
    test('rotas da API que precisam de consulta', () {
      expect(
        classifyLink('/devices/d1'),
        const LinkLookup(LinkEntity.device, 'd1'),
      );
      expect(
        classifyLink('/rooms/r1'),
        const LinkLookup(LinkEntity.room, 'r1'),
      );
      expect(
        classifyLink('/floors/f1/'),
        const LinkLookup(LinkEntity.floor, 'f1'),
      );
    });

    test('rotas que viram tela direto', () {
      expect(
        classifyLink('/buildings/b1'),
        LinkLocation(AppPaths.building('b1')),
      );
      expect(
        classifyLink('/automations/a1'),
        LinkLocation(AppPaths.automation('a1')),
      );
    });

    test('caminhos do próprio app passam direto (com query)', () {
      for (final path in [
        '/environments/buildings/b1/floors/f1',
        '/automations',
        '/energy?level=room&id=r1&name=Sala',
        '/dashboard',
        '/notifications',
        '/reports/rep1',
      ]) {
        expect(classifyLink(path), LinkLocation(path), reason: path);
      }
    });

    test('o que ainda não abre no app', () {
      for (final link in [
        '/users/u1',
        'https://evil.example.com/x',
        '//evil.example.com',
        'devices/d1',
        '',
        '/devices',
        '/devices/d1/extra',
      ]) {
        expect(classifyLink(link), isA<LinkUnsupported>(), reason: link);
      }
    });
  });
}
