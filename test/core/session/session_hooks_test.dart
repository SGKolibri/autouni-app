import 'dart:async';

import 'package:autouni_app/core/push/push_providers.dart';
import 'package:autouni_app/core/session/session_hooks.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LogoutHooks', () {
    test('roda todos os ganchos, na ordem', () async {
      final hooks = LogoutHooks();
      final calls = <String>[];
      hooks
        ..add(() async => calls.add('a'))
        ..add(() async => calls.add('b'));

      await hooks.run();

      expect(calls, ['a', 'b']);
    });

    test('remover um gancho tira ele da lista', () async {
      final hooks = LogoutHooks();
      var calls = 0;
      final remove = hooks.add(() async => calls++);

      remove();
      await hooks.run();

      expect(calls, 0);
    });

    test('falha de um gancho não impede os outros nem o logout', () async {
      final hooks = LogoutHooks();
      var second = false;
      hooks
        ..add(() async => throw StateError('rede'))
        ..add(() async => second = true);

      await expectLater(hooks.run(), completes);
      expect(second, isTrue);
    });

    test('gancho travado é abandonado depois do limite', () {
      fakeAsync((async) {
        final hooks = LogoutHooks();
        hooks.add(() => Completer<void>().future);
        var done = false;

        hooks.run().then((_) => done = true);
        async.elapse(LogoutHooks.timeout - const Duration(milliseconds: 1));
        expect(done, isFalse);

        async.elapse(const Duration(milliseconds: 1));
        expect(done, isTrue);
      });
    });
  });

  test('defaults: sem sessão e sem push (bootstrap sobrescreve)', () {
    final container = ProviderContainer.test();

    expect(container.read(sessionUserIdProvider), isNull);
    expect(container.read(pushMessagingProvider), isNull);
    expect(container.read(logoutHooksProvider), isA<LogoutHooks>());
  });
}
