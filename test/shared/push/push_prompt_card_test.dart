import 'package:autouni_app/core/push/push_messaging.dart';
import 'package:autouni_app/core/push/push_providers.dart';
import 'package:autouni_app/core/session/session_hooks.dart';
import 'package:autouni_app/shared/push/push_prompt_card.dart';
import 'package:autouni_app/shared/push/push_prompt_store.dart';
import 'package:autouni_app/shared/push/push_registration.dart';
import 'package:autouni_app/shared/push/push_token_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../support/pump_app.dart';

class _MockMessaging extends Mock implements PushMessaging {}

class _MockRepository extends Mock implements PushTokenRepository {}

void main() {
  late _MockMessaging messaging;
  late _MockRepository repository;
  late InMemoryPushPromptStore store;

  setUpAll(() => registerFallbackValue(PushPlatform.android));

  setUp(() {
    messaging = _MockMessaging();
    repository = _MockRepository();
    store = InMemoryPushPromptStore();
    when(() => messaging.permission())
        .thenAnswer((_) async => PushPermission.notDetermined);
    when(() => messaging.getToken()).thenAnswer((_) async => 'fcm-1');
    when(() => messaging.onTokenRefresh)
        .thenAnswer((_) => const Stream.empty());
    when(() => messaging.deleteToken()).thenAnswer((_) async {});
    when(() => repository.register(any(), any())).thenAnswer((_) async {});
  });

  List<Override> overrides({bool withPush = true}) => [
    pushMessagingProvider.overrideWithValue(withPush ? messaging : null),
    pushTokenRepositoryProvider.overrideWithValue(repository),
    pushPromptStoreProvider.overrideWithValue(store),
    pushPlatformProvider.overrideWithValue(PushPlatform.android),
    sessionUserIdProvider.overrideWithValue('u1'),
  ];

  Future<void> pumpCard(WidgetTester tester, {bool withPush = true}) async {
    await tester.pumpApp(
      // no Início o cartão fica numa lista: altura do conteúdo
      const Align(
        alignment: Alignment.topCenter,
        child: PushPromptCard(padding: EdgeInsets.all(16)),
      ),
      overrides: overrides(withPush: withPush),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('aparece quando o sistema ainda não perguntou', (tester) async {
    await pumpCard(tester);

    expect(find.byKey(const Key('push-prompt')), findsOneWidget);
    expect(find.text('Receba alertas no celular'), findsOneWidget);
    // mostrar o convite não abre o prompt do sistema
    verifyNever(() => messaging.requestPermission());
  });

  testWidgets('"Ativar alertas" pede permissão, registra e some', (
    tester,
  ) async {
    when(() => messaging.requestPermission())
        .thenAnswer((_) async => PushPermission.granted);
    await pumpCard(tester);

    await tester.tap(find.byKey(const Key('push-prompt-accept')));
    await tester.pumpAndSettle();

    verify(() => messaging.requestPermission()).called(1);
    verify(() => repository.register('fcm-1', PushPlatform.android)).called(1);
    expect(find.byKey(const Key('push-prompt')), findsNothing);
    expect(find.text('Alertas ativados.'), findsOneWidget);
  });

  testWidgets('recusar no sistema explica onde reativar', (tester) async {
    when(() => messaging.requestPermission())
        .thenAnswer((_) async => PushPermission.denied);
    await pumpCard(tester);

    await tester.tap(find.byKey(const Key('push-prompt-accept')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('push-prompt')), findsNothing);
    expect(find.textContaining('ajustes do aparelho'), findsOneWidget);
    verifyNever(() => repository.register(any(), any()));
  });

  testWidgets('falha ao registrar avisa que tenta de novo', (tester) async {
    when(() => messaging.requestPermission())
        .thenAnswer((_) async => PushPermission.granted);
    when(() => messaging.getToken()).thenAnswer((_) async => null);
    await pumpCard(tester);

    await tester.tap(find.byKey(const Key('push-prompt-accept')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Tentaremos de novo'), findsOneWidget);
  });

  testWidgets('"Agora não" esconde e lembra a escolha', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.byKey(const Key('push-prompt-dismiss')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('push-prompt')), findsNothing);
    expect(await store.dismissedAt(), isNotNull);
    verifyNever(() => messaging.requestPermission());
  });

  testWidgets('permissão já dada: não mostra nada', (tester) async {
    when(() => messaging.permission())
        .thenAnswer((_) async => PushPermission.granted);
    await pumpCard(tester);

    expect(find.byKey(const Key('push-prompt')), findsNothing);
    expect(find.byType(Padding), findsNothing);
  });

  testWidgets('sem push configurado: não mostra nada', (tester) async {
    await pumpCard(tester, withPush: false);

    expect(find.byKey(const Key('push-prompt')), findsNothing);
  });

  testWidgets('golden', (tester) async {
    tester.view.physicalSize = const Size(390, 420);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await pumpCard(tester);

    await expectLater(
      find.byKey(const Key('push-prompt')),
      matchesGoldenFile('goldens/push_prompt_card.png'),
    );
  });
}
