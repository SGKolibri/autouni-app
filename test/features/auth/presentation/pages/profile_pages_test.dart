import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/core/router/app_tab.dart';
import 'package:autouni_app/features/auth/data/auth_data_providers.dart';
import 'package:autouni_app/features/auth/data/repositories/profile_repository.dart';
import 'package:autouni_app/features/auth/domain/models/user.dart';
import 'package:autouni_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:autouni_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autouni_app/features/auth/presentation/pages/change_password_page.dart';
import 'package:autouni_app/features/auth/presentation/pages/profile_page.dart';
import 'package:autouni_app/shared/models/user_role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/pump_router_app.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockProfile extends Mock implements ProfileRepository {}

const _user = User(
  id: 'u1',
  email: 'ana@uni.br',
  name: 'Ana',
  phone: '62999990000',
  role: UserRole.coordinator,
);

void main() {
  late _MockAuth auth;
  late _MockProfile profile;

  setUp(() {
    auth = _MockAuth();
    profile = _MockProfile();
    when(() => auth.restoreSession()).thenAnswer((_) async => _user);
    when(() => profile.fetch('u1')).thenAnswer((_) async => _user);
  });

  /// Abre [path] a partir de Ajustes, para o "voltar" ter para onde ir.
  Future<(ProviderContainer, GoRouter)> pump(
    WidgetTester tester,
    String path,
  ) async {
    final result = await tester.pumpRouterApp(
      initialLocation: AppTab.settings.path,
      routes: [
        GoRoute(
          path: AppTab.settings.path,
          builder: (_, _) => const Scaffold(body: Text('ajustes')),
          routes: [
            GoRoute(path: 'profile', builder: (_, _) => const ProfilePage()),
            GoRoute(
              path: 'password',
              builder: (_, _) => const ChangePasswordPage(),
            ),
          ],
        ),
      ],
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(profile),
      ],
    );
    await result.$1.read(authControllerProvider.future);
    result.$2.push(path);
    await tester.pumpAndSettle();
    return result;
  }

  group('perfil', () {
    testWidgets('mostra os dados; e-mail e papel só leitura', (tester) async {
      await pump(tester, AppPaths.profile);

      expect(find.text('Ana'), findsOneWidget);
      expect(find.text('62999990000'), findsOneWidget);
      expect(find.text('Coordenador'), findsOneWidget);
      final email = tester.widget<TextField>(
        find.widgetWithText(TextField, 'ana@uni.br'),
      );
      expect(email.enabled, isFalse);
    });

    testWidgets('salva, atualiza a sessão e volta', (tester) async {
      when(
        () => profile.update(
          'u1',
          name: any(named: 'name'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer((_) async => _user.copyWith(name: 'Ana Souza'));
      final (container, router) = await pump(tester, AppPaths.profile);

      await tester.enterText(
        find.byKey(const Key('profile-name')),
        'Ana Souza',
      );
      await tester.tap(find.byKey(const Key('profile-save')));
      await tester.pumpAndSettle();

      expect(container.read(authControllerProvider).value?.name, 'Ana Souza');
      expect(router.state.uri.path, AppTab.settings.path);
      expect(find.text('Perfil atualizado.'), findsOneWidget);
    });

    testWidgets('nome curto e telefone inválido aparecem no formulário', (
      tester,
    ) async {
      await pump(tester, AppPaths.profile);

      await tester.enterText(find.byKey(const Key('profile-name')), 'A');
      await tester.enterText(find.byKey(const Key('profile-phone')), '123');
      await tester.tap(find.byKey(const Key('profile-save')));
      await tester.pumpAndSettle();

      expect(find.textContaining('pelo menos 3'), findsOneWidget);
      expect(find.textContaining('DDD'), findsOneWidget);
      verifyNever(
        () => profile.update(
          any(),
          name: any(named: 'name'),
          phone: any(named: 'phone'),
        ),
      );
    });
  });

  group('trocar senha', () {
    When<Future<void>> whenChange() => when(
      () => profile.changePassword(
        userId: any(named: 'userId'),
        email: any(named: 'email'),
        currentPassword: any(named: 'currentPassword'),
        newPassword: any(named: 'newPassword'),
      ),
    );

    Future<void> fill(
      WidgetTester tester, {
      String current = 'antiga123',
      String fresh = 'novaSenha1',
      String? confirm,
    }) async {
      await tester.enterText(
        find.byKey(const Key('password-current')),
        current,
      );
      await tester.enterText(find.byKey(const Key('password-new')), fresh);
      await tester.enterText(
        find.byKey(const Key('password-confirm')),
        confirm ?? fresh,
      );
      await tester.tap(find.byKey(const Key('password-save')));
      await tester.pumpAndSettle();
    }

    testWidgets('troca e volta para Ajustes', (tester) async {
      whenChange().thenAnswer((_) async {});
      final (_, router) = await pump(tester, AppPaths.changePassword);

      await fill(tester);

      verify(
        () => profile.changePassword(
          userId: 'u1',
          email: 'ana@uni.br',
          currentPassword: 'antiga123',
          newPassword: 'novaSenha1',
        ),
      ).called(1);
      expect(router.state.uri.path, AppTab.settings.path);
      expect(find.text('Senha alterada.'), findsOneWidget);
    });

    testWidgets('senha atual errada aparece em destaque', (tester) async {
      whenChange().thenThrow(const WrongCurrentPasswordException());
      await pump(tester, AppPaths.changePassword);

      await fill(tester, current: 'errada1');

      expect(find.text('Senha atual incorreta.'), findsOneWidget);
    });

    testWidgets('confirmação diferente e senha fraca não enviam', (
      tester,
    ) async {
      await pump(tester, AppPaths.changePassword);

      await fill(tester, fresh: 'curta', confirm: 'outra');

      expect(find.textContaining('pelo menos 8'), findsOneWidget);
      expect(find.text('As senhas não conferem.'), findsOneWidget);
      verifyNever(
        () => profile.changePassword(
          userId: any(named: 'userId'),
          email: any(named: 'email'),
          currentPassword: any(named: 'currentPassword'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });
  });
}
