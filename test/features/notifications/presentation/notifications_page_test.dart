import 'dart:async';

import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/features/notifications/data/notification_link_resolver.dart';
import 'package:autouni_app/features/notifications/data/notifications_repository.dart';
import 'package:autouni_app/features/notifications/domain/app_notification.dart';
import 'package:autouni_app/features/notifications/presentation/notification_opener.dart';
import 'package:autouni_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:autouni_app/shared/models/notification_type.dart';
import 'package:autouni_app/shared/widgets/cached_async_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/pump_router_app.dart';

class _MockRepository extends Mock implements NotificationsRepository {}

class _MockResolver extends Mock implements NotificationLinkResolver {}

final _now = DateTime(2026, 10, 21, 15);

final _device = AppNotification(
  id: 'n1',
  type: NotificationType.warning,
  title: 'Ar ligado fora do horário',
  message: 'Sala 101 — Bloco A',
  link: '/devices/d1',
  createdAt: DateTime(2026, 10, 21, 14),
);
final _room = AppNotification(
  id: 'n2',
  type: NotificationType.error,
  title: 'Sala sem resposta',
  link: '/rooms/r1',
  createdAt: DateTime(2026, 10, 21, 9),
);
final _info = AppNotification(
  id: 'n3',
  title: 'Manutenção programada',
  message: 'Sábado, das 8h às 12h, o Bloco B fica sem energia.',
  read: true,
  createdAt: DateTime(2026, 10, 20, 18),
);
final _report = AppNotification(
  id: 'n4',
  type: NotificationType.success,
  title: 'Relatório gerado',
  link: '/reports/rep1',
  read: true,
  createdAt: DateTime(2026, 10, 3, 10),
);

void main() {
  late _MockRepository repository;
  late _MockResolver resolver;
  final deviceRoom = AppPaths.room('b1', 'f1', 'r1', deviceId: 'd1');

  setUp(() {
    repository = _MockRepository();
    resolver = _MockResolver();
    when(
      () => repository.watchMine(),
    ).thenAnswer((_) => Stream.value(Cached([_device, _room, _info, _report])));
    when(() => repository.markRead(any())).thenAnswer((_) async {});
    when(() => repository.markAllRead(any())).thenAnswer((_) async => []);
    when(() => resolver.resolve('/devices/d1'))
        .thenAnswer((_) async => deviceRoom);
    when(() => resolver.resolve('/rooms/r1'))
        .thenAnswer((_) async => AppPaths.room('b1', 'f1', 'r1'));
    when(() => resolver.resolve('/reports/rep1')).thenAnswer((_) async => null);
  });

  Future<GoRouter> pumpPage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (_, router) = await tester.pumpRouterApp(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (_, _) => NotificationsPage(now: () => _now),
        ),
        GoRoute(
          path: '/environments/buildings/:b/floors/:f/rooms/:r',
          builder: (_, state) => Scaffold(body: Text('sala ${state.uri}')),
        ),
      ],
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repository),
        notificationLinkResolverProvider.overrideWithValue(resolver),
      ],
    );
    await tester.pumpAndSettle();
    return router;
  }

  Finder tile(String id) => find.byKey(ValueKey('notification-$id'));
  Finder unreadDot(String id) => find.byKey(ValueKey('unread-dot-$id'));

  testWidgets('lista por dia, com não lidas destacadas', (tester) async {
    await pumpPage(tester);

    expect(find.text('Hoje'), findsOneWidget);
    expect(find.text('Ontem'), findsOneWidget);
    expect(find.text('03/10'), findsOneWidget);
    expect(unreadDot('n1'), findsOneWidget);
    expect(unreadDot('n2'), findsOneWidget);
    expect(unreadDot('n3'), findsNothing);
    expect(find.text('Não lidas (2)'), findsOneWidget);
    expect(
      tester.getTopLeft(tile('n1')).dy,
      lessThan(tester.getTopLeft(tile('n3')).dy),
    );
  });

  group('filtros', () {
    testWidgets('por tipo', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byKey(const ValueKey('filter-error')));
      await tester.pumpAndSettle();

      expect(tile('n2'), findsOneWidget);
      expect(tile('n1'), findsNothing);
      expect(tile('n3'), findsNothing);
    });

    testWidgets('só não lidas', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byKey(const Key('filter-unread')));
      await tester.pumpAndSettle();

      expect(tile('n1'), findsOneWidget);
      expect(tile('n2'), findsOneWidget);
      expect(tile('n3'), findsNothing);
      expect(tile('n4'), findsNothing);
    });

    testWidgets('sem resultado oferece limpar os filtros', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byKey(const Key('filter-unread')));
      await tester.pump();
      await tester.ensureVisible(find.byKey(const ValueKey('filter-success')));
      await tester.tap(find.byKey(const ValueKey('filter-success')));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum alerta com esse filtro'), findsOneWidget);

      await tester.tap(find.text('Limpar filtros'));
      await tester.pumpAndSettle();

      expect(tile('n4'), findsOneWidget);
    });
  });

  group('deep link (S6-T2)', () {
    testWidgets('alerta de dispositivo abre a sala com a ficha dele', (
      tester,
    ) async {
      final router = await pumpPage(tester);

      await tester.tap(tile('n1'));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), deviceRoom);
      verify(() => repository.markRead('n1')).called(1);
    });

    testWidgets('alerta de sala abre a sala', (tester) async {
      final router = await pumpPage(tester);

      await tester.tap(tile('n2'));
      await tester.pumpAndSettle();

      expect(router.state.uri.toString(), AppPaths.room('b1', 'f1', 'r1'));
    });

    testWidgets('destino que não abre no app avisa e fica na central', (
      tester,
    ) async {
      final router = await pumpPage(tester);

      await tester.tap(tile('n4'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/notifications');
      expect(find.text(unsupportedLinkMessage), findsOneWidget);
    });

    testWidgets('destino apagado avisa com o erro', (tester) async {
      when(() => resolver.resolve('/devices/d1'))
          .thenThrow(const NotFoundException(message: 'Device not found'));
      final router = await pumpPage(tester);

      await tester.tap(tile('n1'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/notifications');
      expect(find.textContaining('Device not found'), findsOneWidget);
    });

    testWidgets('alerta sem link mostra o texto completo', (tester) async {
      await pumpPage(tester);

      await tester.tap(tile('n3'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.textContaining('o Bloco B fica sem energia'),
        ),
        findsOneWidget,
      );
      verifyNever(() => repository.markRead('n3'));
    });
  });

  group('lido / não lido', () {
    testWidgets('tocar marca como lida na hora', (tester) async {
      // o link fica resolvendo: a central continua na tela
      final pending = Completer<String?>();
      when(() => resolver.resolve('/rooms/r1'))
          .thenAnswer((_) => pending.future);
      await pumpPage(tester);

      await tester.tap(tile('n2'));
      await tester.pump();

      expect(unreadDot('n2'), findsNothing);
      expect(find.text('Não lidas (1)'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      pending.complete(null);
      await tester.pumpAndSettle();
    });

    testWidgets('marcar todas', (tester) async {
      await pumpPage(tester);

      await tester.tap(find.byKey(const Key('notifications-read-all')));
      await tester.pumpAndSettle();

      verify(() => repository.markAllRead(any())).called(1);
      expect(unreadDot('n1'), findsNothing);
      expect(unreadDot('n2'), findsNothing);
      expect(
        find.text('Todos os alertas marcados como lidos.'),
        findsOneWidget,
      );
      final button = tester.widget<IconButton>(
        find.byKey(const Key('notifications-read-all')),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('erro ao marcar todas desfaz e avisa', (tester) async {
      when(() => repository.markAllRead(any())).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments.first as List<String>,
      );
      await pumpPage(tester);

      await tester.tap(find.byKey(const Key('notifications-read-all')));
      await tester.pumpAndSettle();

      expect(unreadDot('n1'), findsOneWidget);
      expect(
        find.text('Não foi possível marcar os alertas como lidos.'),
        findsOneWidget,
      );
    });
  });

  group('estados', () {
    testWidgets('vazio', (tester) async {
      when(() => repository.watchMine())
          .thenAnswer((_) => Stream.value(const Cached(<AppNotification>[])));
      await pumpPage(tester);

      expect(find.text('Nenhum alerta'), findsOneWidget);
    });

    testWidgets('erro sem cache: tentar de novo', (tester) async {
      var calls = 0;
      when(() => repository.watchMine()).thenAnswer((_) {
        calls++;
        return calls == 1
            ? Stream.error(const ServerException(message: 'Fora do ar'))
            : Stream.value(Cached([_device]));
      });
      await pumpPage(tester);

      expect(find.text('Fora do ar'), findsOneWidget);
      await tester.tap(find.text('Tentar de novo'));
      await tester.pumpAndSettle();

      expect(tile('n1'), findsOneWidget);
    });

    testWidgets('offline com cache: banner de dados salvos', (tester) async {
      when(() => repository.watchMine()).thenAnswer(
        (_) => Stream.value(
          Cached([_device], savedAt: DateTime(2026, 10, 21, 9), offline: true),
        ),
      );
      await pumpPage(tester);

      expect(find.byType(StaleDataBanner), findsOneWidget);
      expect(tile('n1'), findsOneWidget);
    });
  });
}
