import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/features/auth/data/auth_data_providers.dart';
import 'package:autouni_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:autouni_app/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:autouni_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/pump_router_app.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  When<Future<void>> whenReset() =>
      when(() => repository.requestPasswordReset(email: any(named: 'email')));

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpRouterApp(
      initialLocation: '/forgot-password',
      routes: [
        stubRoute('/login'),
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordPage(),
        ),
      ],
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
  }

  Future<void> submit(WidgetTester tester, String email) async {
    await tester.enterText(find.byKey(const Key('forgot-email')), email);
    await tester.tap(find.byKey(const Key('forgot-submit')));
    await tester.pumpAndSettle();
  }

  setUp(() => repository = _MockAuthRepository());

  testWidgets('valida o e-mail antes de enviar', (tester) async {
    await pumpPage(tester);

    await submit(tester, 'ana');

    expect(find.text('E-mail inválido.'), findsOneWidget);
    verifyNever(
      () => repository.requestPasswordReset(email: any(named: 'email')),
    );
  });

  testWidgets('confirma o envio sem revelar se a conta existe', (tester) async {
    whenReset().thenAnswer((_) async {});
    await pumpPage(tester);

    await submit(tester, 'ana@uni.br');

    expect(find.text('Pedido enviado'), findsOneWidget);
    expect(find.textContaining('Se ana@uni.br estiver cadastrado'), findsOne);

    await tester.tap(find.text('Voltar ao login'));
    await tester.pumpAndSettle();
    expect(find.text('stub /login'), findsOneWidget);
  });

  testWidgets('backend sem o endpoint mostra que está indisponível', (
    tester,
  ) async {
    whenReset().thenThrow(const NotFoundException(message: 'Cannot POST'));
    await pumpPage(tester);

    await submit(tester, 'ana@uni.br');

    expect(
      find.text(ForgotPasswordController.unavailableMessage),
      findsOneWidget,
    );
  });
}
