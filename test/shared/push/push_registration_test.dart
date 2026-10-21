import 'dart:async';

import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/push/push_messaging.dart';
import 'package:autouni_app/core/push/push_providers.dart';
import 'package:autouni_app/core/session/session_hooks.dart';
import 'package:autouni_app/shared/push/push_prompt_store.dart';
import 'package:autouni_app/shared/push/push_registration.dart';
import 'package:autouni_app/shared/push/push_token_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMessaging extends Mock implements PushMessaging {}

class _MockRepository extends Mock implements PushTokenRepository {}

/// Usuário logado controlável pelo teste.
class _Session extends Notifier<String?> {
  @override
  String? build() => 'u1';

  void set(String? id) => state = id;
}

final _session = NotifierProvider<_Session, String?>(_Session.new);

void main() {
  late _MockMessaging messaging;
  late _MockRepository repository;
  late InMemoryPushPromptStore store;
  late StreamController<String> refresh;
  late ProviderContainer container;
  final now = DateTime.utc(2026, 10, 21, 12);

  setUpAll(() => registerFallbackValue(PushPlatform.android));

  ProviderContainer build({bool withPush = true}) {
    final c = ProviderContainer.test(
      overrides: [
        pushMessagingProvider.overrideWithValue(withPush ? messaging : null),
        pushTokenRepositoryProvider.overrideWithValue(repository),
        pushPromptStoreProvider.overrideWithValue(store),
        pushPlatformProvider.overrideWithValue(PushPlatform.android),
        pushClockProvider.overrideWithValue(() => now),
        sessionUserIdProvider.overrideWith((ref) => ref.watch(_session)),
      ],
    );
    c.listen(pushRegistrationProvider, (_, _) {});
    return c;
  }

  PushStatus status() => container.read(pushRegistrationProvider);
  PushRegistration controller() =>
      container.read(pushRegistrationProvider.notifier);

  void permissionIs(PushPermission permission) =>
      when(() => messaging.permission()).thenAnswer((_) async => permission);

  setUp(() {
    messaging = _MockMessaging();
    repository = _MockRepository();
    store = InMemoryPushPromptStore();
    refresh = StreamController<String>.broadcast();
    when(() => messaging.getToken()).thenAnswer((_) async => 'fcm-1');
    when(() => messaging.onTokenRefresh).thenAnswer((_) => refresh.stream);
    when(() => messaging.deleteToken()).thenAnswer((_) async {});
    when(() => repository.register(any(), any())).thenAnswer((_) async {});
    when(() => repository.unregister(any())).thenAnswer((_) async {});
  });

  tearDown(() => refresh.close());

  group('sem push ou sem sessão', () {
    test('sem Firebase configurado: indisponível, nada é chamado', () async {
      container = build(withPush: false);
      await pumpEventQueue();

      expect(status(), PushStatus.unavailable);
      verifyZeroInteractions(messaging);
    });

    test('deslogado: indisponível, sem pedir permissão', () async {
      permissionIs(PushPermission.notDetermined);
      container = build();
      container.read(_session.notifier).set(null);
      await pumpEventQueue();

      expect(status(), PushStatus.unavailable);
      verifyNever(() => messaging.requestPermission());
    });
  });

  group('ao entrar', () {
    test(
      'permissão já concedida: registra o token sem perguntar nada',
      () async {
        permissionIs(PushPermission.granted);
        container = build();
        await pumpEventQueue();

        expect(status(), PushStatus.enabled);
        verify(() => repository.register('fcm-1', PushPlatform.android))
            .called(1);
        verifyNever(() => messaging.requestPermission());
      },
    );

    test(
      'sistema ainda não perguntou: mostra o convite, não o prompt',
      () async {
        permissionIs(PushPermission.notDetermined);
        container = build();
        await pumpEventQueue();

        expect(status(), PushStatus.promptable);
        verifyNever(() => messaging.requestPermission());
        verifyNever(() => repository.register(any(), any()));
      },
    );

    test('convite dispensado há menos de 7 dias não volta', () async {
      permissionIs(PushPermission.notDetermined);
      await store.setDismissedAt(now.subtract(const Duration(days: 6)));
      container = build();
      await pumpEventQueue();

      expect(status(), PushStatus.dismissed);
    });

    test('depois de 7 dias o convite volta', () async {
      permissionIs(PushPermission.notDetermined);
      await store.setDismissedAt(now.subtract(const Duration(days: 7)));
      container = build();
      await pumpEventQueue();

      expect(status(), PushStatus.promptable);
    });

    test('recusado no sistema: não insiste', () async {
      permissionIs(PushPermission.denied);
      container = build();
      await pumpEventQueue();

      expect(status(), PushStatus.denied);
      verifyNever(() => messaging.requestPermission());
      verifyNever(() => repository.register(any(), any()));
    });

    test('FCM sem token: falha silenciosa, tenta na próxima sessão', () async {
      permissionIs(PushPermission.granted);
      when(() => messaging.getToken()).thenAnswer((_) async => null);
      container = build();
      await pumpEventQueue();

      expect(status(), PushStatus.failed);
      verifyNever(() => repository.register(any(), any()));
    });

    test('backend fora: falha silenciosa', () async {
      permissionIs(PushPermission.granted);
      when(() => repository.register(any(), any()))
          .thenThrow(const NetworkException());
      container = build();
      await pumpEventQueue();

      expect(status(), PushStatus.failed);
    });
  });

  group('convite', () {
    setUp(() => permissionIs(PushPermission.notDetermined));

    test('"Ativar" abre o prompt do sistema e registra se aceito', () async {
      when(() => messaging.requestPermission())
          .thenAnswer((_) async => PushPermission.granted);
      container = build();
      await pumpEventQueue();

      await controller().accept();

      expect(status(), PushStatus.enabled);
      verify(() => messaging.requestPermission()).called(1);
      verify(() => repository.register('fcm-1', PushPlatform.android))
          .called(1);
    });

    test('recusar no prompt do sistema fica recusado', () async {
      when(() => messaging.requestPermission())
          .thenAnswer((_) async => PushPermission.denied);
      container = build();
      await pumpEventQueue();

      await controller().accept();

      expect(status(), PushStatus.denied);
      verifyNever(() => repository.register(any(), any()));
    });

    test('"Agora não" guarda a data e esconde o convite', () async {
      container = build();
      await pumpEventQueue();

      await controller().dismiss();

      expect(status(), PushStatus.dismissed);
      expect(await store.dismissedAt(), now);
      verifyNever(() => messaging.requestPermission());
    });

    test(
      'fora do estado de convite, ativar e dispensar não fazem nada',
      () async {
        permissionIs(PushPermission.denied);
        container = build();
        await pumpEventQueue();

        await controller().accept();
        await controller().dismiss();

        expect(status(), PushStatus.denied);
        verifyNever(() => messaging.requestPermission());
        expect(await store.dismissedAt(), isNull);
      },
    );
  });

  group('token e logout', () {
    setUp(() => permissionIs(PushPermission.granted));

    test('token renovado pelo FCM é registrado de novo', () async {
      container = build();
      await pumpEventQueue();

      refresh.add('fcm-2');
      await pumpEventQueue();

      verify(() => repository.register('fcm-2', PushPlatform.android))
          .called(1);
    });

    test('logout remove o token no backend (com a sessão ainda válida) '
        'e invalida o token local', () async {
      container = build();
      await pumpEventQueue();

      await container.read(logoutHooksProvider).run();

      verify(() => repository.unregister('fcm-1')).called(1);
      verify(() => messaging.deleteToken()).called(1);

      // a sessão acaba depois do gancho: nada é apagado duas vezes
      container.read(_session.notifier).set(null);
      await pumpEventQueue();
      expect(status(), PushStatus.unavailable);
      verifyNever(() => messaging.deleteToken());
    });

    test(
      'depois do logout, renovação de token não é mais registrada',
      () async {
        container = build();
        await pumpEventQueue();
        await container.read(logoutHooksProvider).run();
        container.read(_session.notifier).set(null);
        await pumpEventQueue();
        clearInteractions(repository);

        refresh.add('fcm-3');
        await pumpEventQueue();

        verifyNever(() => repository.register(any(), any()));
      },
    );

    test('sessão expirada (sem logout): invalida o token local', () async {
      container = build();
      await pumpEventQueue();

      container.read(_session.notifier).set(null);
      await pumpEventQueue();

      verify(() => messaging.deleteToken()).called(1);
      verifyNever(() => repository.unregister(any()));
    });

    test('entrar com outra conta registra o token para ela', () async {
      container = build();
      await pumpEventQueue();
      await container.read(logoutHooksProvider).run();
      container.read(_session.notifier).set(null);
      await pumpEventQueue();
      when(() => messaging.getToken()).thenAnswer((_) async => 'fcm-novo');

      container.read(_session.notifier).set('u2');
      await pumpEventQueue();

      expect(status(), PushStatus.enabled);
      verify(() => repository.register('fcm-novo', PushPlatform.android))
          .called(1);
    });

    test('logout sem token registrado não chama o backend', () async {
      permissionIs(PushPermission.notDetermined);
      container = build();
      await pumpEventQueue();

      await container.read(logoutHooksProvider).run();

      verifyNever(() => repository.unregister(any()));
      verifyNever(() => messaging.deleteToken());
    });
  });
}
