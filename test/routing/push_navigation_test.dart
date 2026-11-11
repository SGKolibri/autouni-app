import 'dart:async';

import 'package:autouni_app/app.dart';
import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/app_config_provider.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:autouni_app/core/push/push_messaging.dart';
import 'package:autouni_app/core/push/push_providers.dart';
import 'package:autouni_app/core/realtime/realtime_providers.dart';
import 'package:autouni_app/core/router/app_tab.dart';
import 'package:autouni_app/core/session/session_hooks.dart';
import 'package:autouni_app/features/auth/data/auth_data_providers.dart';
import 'package:autouni_app/features/auth/domain/models/user.dart';
import 'package:autouni_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:autouni_app/features/automations/data/automations_repository.dart';
import 'package:autouni_app/features/dashboard/data/dashboard_repository.dart';
import 'package:autouni_app/features/notifications/data/notification_link_resolver.dart';
import 'package:autouni_app/features/notifications/data/notifications_repository.dart';
import 'package:autouni_app/routing/app_router_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../support/app_fakes.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockMessaging extends Mock implements PushMessaging {}

class _MockResolver extends Mock implements NotificationLinkResolver {}

void main() {
  late _MockMessaging messaging;
  late StreamController<PushMessage> foreground;
  late StreamController<PushMessage> opened;
  late ProviderContainer container;

  const push = PushMessage(
    title: 'Automação executada',
    notificationId: 'n1',
    link: '/automations/a1',
  );

  setUp(() {
    messaging = _MockMessaging();
    foreground = StreamController<PushMessage>.broadcast();
    opened = StreamController<PushMessage>.broadcast();
    when(() => messaging.onForegroundMessage)
        .thenAnswer((_) => foreground.stream);
    when(() => messaging.onMessageOpened).thenAnswer((_) => opened.stream);
    when(() => messaging.initialMessage()).thenAnswer((_) async => null);
    when(() => messaging.permission())
        .thenAnswer((_) async => PushPermission.denied);

    final auth = _MockAuthRepository();
    when(() => auth.restoreSession()).thenAnswer(
      (_) async => const User(id: 'u1', email: 'ana@uni.br', name: 'Ana'),
    );
    final resolver = _MockResolver();
    when(() => resolver.resolve('/automations/a1'))
        .thenAnswer((_) async => '/automations');
    final notifications = EmptyNotificationsRepository();
    when(() => notifications.markRead(any())).thenAnswer((_) async {});

    container = ProviderContainer.test(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.forFlavor(Flavor.prod)),
        authRepositoryProvider.overrideWithValue(auth),
        realtimeClientProvider.overrideWithValue(
          MockRealtimeClient.connected(),
        ),
        dashboardRepositoryProvider.overrideWithValue(
          EmptyDashboardRepository(),
        ),
        automationsRepositoryProvider.overrideWithValue(
          EmptyAutomationsRepository(),
        ),
        notificationsRepositoryProvider.overrideWithValue(notifications),
        notificationLinkResolverProvider.overrideWithValue(resolver),
        pushMessagingProvider.overrideWithValue(messaging),
        sessionUserIdProvider.overrideWithValue('u1'),
      ],
    );
  });

  tearDown(() async {
    await foreground.close();
    await opened.close();
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const AutoUniApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  String location() => container.read(appRouterProvider).state.uri.path;

  testWidgets('push com o app aberto vira aviso; "Ver" abre o destino', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(location(), AppTab.dashboard.path);

    foreground.add(push);
    await tester.pumpAndSettle();

    expect(find.text('Automação executada'), findsOneWidget);
    await tester.tap(find.widgetWithText(SnackBarAction, 'Ver'));
    await tester.pumpAndSettle();

    expect(location(), AppTab.automations.path);
  });

  testWidgets('push tocado na bandeja abre o destino', (tester) async {
    await pumpApp(tester);

    opened.add(push);
    await tester.pumpAndSettle();

    expect(location(), AppTab.automations.path);
  });
}
