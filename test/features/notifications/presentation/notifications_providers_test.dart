import 'dart:async';

import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/session/session_hooks.dart';
import 'package:autouni_app/features/notifications/data/notifications_repository.dart';
import 'package:autouni_app/features/notifications/domain/app_notification.dart';
import 'package:autouni_app/features/notifications/presentation/providers/notifications_providers.dart';
import 'package:autouni_app/shared/models/notification_type.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepository extends Mock implements NotificationsRepository {}

class _Session extends Notifier<String?> {
  @override
  String? build() => 'u1';

  void set(String? id) => state = id;
}

final _session = NotifierProvider<_Session, String?>(_Session.new);

const _unreadA = AppNotification(id: 'a', title: 'A');
const _unreadB = AppNotification(
  id: 'b',
  title: 'B',
  type: NotificationType.error,
);
const _read = AppNotification(id: 'c', title: 'C', read: true);

void main() {
  late _MockRepository repository;
  late ProviderContainer container;

  ProviderContainer build() {
    final c = ProviderContainer.test(
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repository),
        sessionUserIdProvider.overrideWith((ref) => ref.watch(_session)),
      ],
    );
    c.listen(notificationsProvider, (_, _) {});
    c.listen(unreadNotificationsCountProvider, (_, _) {});
    return c;
  }

  NotificationsController controller() =>
      container.read(notificationsControllerProvider);

  List<AppNotification> visible() =>
      container.read(visibleNotificationsProvider)!;

  bool isRead(String id) => visible().firstWhere((n) => n.id == id).read;

  setUp(() {
    repository = _MockRepository();
    when(() => repository.watchMine()).thenAnswer(
      (_) => Stream.value(const Cached([_unreadA, _unreadB, _read])),
    );
    container = build();
  });

  test('conta as não lidas', () async {
    await container.read(notificationsProvider.future);

    expect(container.read(unreadNotificationsCountProvider), 2);
  });

  test('antes de carregar, contagem desconhecida (null)', () {
    when(() => repository.watchMine()).thenAnswer((_) => const Stream.empty());
    container = build();

    expect(container.read(unreadNotificationsCountProvider), isNull);
    expect(container.read(visibleNotificationsProvider), isNull);
  });

  test('outra conta recarrega a lista', () async {
    await container.read(notificationsProvider.future);

    container.read(_session.notifier).set('u2');
    await container.read(notificationsProvider.future);

    verify(() => repository.watchMine()).called(2);
  });

  group('marcar como lida (otimista)', () {
    test('muda na hora e mantém depois da confirmação', () async {
      await container.read(notificationsProvider.future);
      final response = Completer<void>();
      when(() => repository.markRead('a')).thenAnswer((_) => response.future);

      final pending = controller().markRead(_unreadA);

      expect(isRead('a'), isTrue);
      expect(container.read(unreadNotificationsCountProvider), 1);

      response.complete();
      expect(await pending, isNull);
      expect(isRead('a'), isTrue);
    });

    test('erro desfaz e devolve a mensagem', () async {
      await container.read(notificationsProvider.future);
      when(() => repository.markRead('a')).thenThrow(const NetworkException());

      final error = await controller().markRead(_unreadA);

      expect(error, 'Sem conexão com a internet.');
      expect(isRead('a'), isFalse);
      expect(container.read(unreadNotificationsCountProvider), 2);
    });

    test('já lida não chama o backend', () async {
      await container.read(notificationsProvider.future);

      expect(await controller().markRead(_read), isNull);
      verifyNever(() => repository.markRead(any()));
    });

    test('resposta nova da rede substitui as confirmadas', () async {
      await container.read(notificationsProvider.future);
      when(() => repository.markRead('a')).thenAnswer((_) async {});
      await controller().markRead(_unreadA);
      when(() => repository.watchMine()).thenAnswer(
        (_) => Stream.value(
          Cached([_unreadA.copyWith(read: true), _unreadB, _read]),
        ),
      );

      container.invalidate(notificationsProvider);
      await container.read(notificationsProvider.future);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(notificationReadOverridesProvider).isEmpty, isTrue);
      expect(isRead('a'), isTrue);
    });
  });

  group('marcar todas', () {
    test('todas as não lidas viram lidas (um PATCH por alerta)', () async {
      await container.read(notificationsProvider.future);
      when(() => repository.markAllRead(any())).thenAnswer((_) async => []);

      final error = await controller().markAllRead();

      expect(error, isNull);
      expect(visible().every((n) => n.read), isTrue);
      expect(container.read(unreadNotificationsCountProvider), 0);
      final ids =
          verify(() => repository.markAllRead(captureAny())).captured.single
              as List<String>;
      expect(ids.toSet(), {'a', 'b'});
    });

    test('falha parcial desfaz só as que falharam', () async {
      await container.read(notificationsProvider.future);
      when(() => repository.markAllRead(any())).thenAnswer((_) async => ['b']);

      final error = await controller().markAllRead();

      expect(error, '1 alerta(s) não puderam ser marcados como lidos.');
      expect(isRead('a'), isTrue);
      expect(isRead('b'), isFalse);
      expect(container.read(unreadNotificationsCountProvider), 1);
    });

    test('falha total desfaz todas', () async {
      await container.read(notificationsProvider.future);
      when(() => repository.markAllRead(any()))
          .thenAnswer((_) async => ['a', 'b']);

      final error = await controller().markAllRead();

      expect(error, 'Não foi possível marcar os alertas como lidos.');
      expect(container.read(unreadNotificationsCountProvider), 2);
    });

    test('sem não lidas não chama o backend', () async {
      when(() => repository.watchMine())
          .thenAnswer((_) => Stream.value(const Cached([_read])));
      container = build();
      await container.read(notificationsProvider.future);

      expect(await controller().markAllRead(), isNull);
      verifyNever(() => repository.markAllRead(any()));
    });
  });

  test('filtro guarda tipo e não lidas', () {
    final filter = container.read(notificationFilterProvider.notifier);

    filter.setType(NotificationType.error);
    filter.setUnreadOnly(true);
    expect(
      container.read(notificationFilterProvider).type,
      NotificationType.error,
    );
    expect(container.read(notificationFilterProvider).unreadOnly, isTrue);

    filter.setType(null);
    expect(container.read(notificationFilterProvider).type, isNull);
  });
}
