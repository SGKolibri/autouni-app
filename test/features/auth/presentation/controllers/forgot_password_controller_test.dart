import 'dart:async';

import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/features/auth/data/auth_data_providers.dart';
import 'package:autouni_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:autouni_app/features/auth/presentation/controllers/forgot_password_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late ProviderContainer container;

  When<Future<void>> whenReset() =>
      when(() => repository.requestPasswordReset(email: any(named: 'email')));

  ForgotPasswordState state() =>
      container.read(forgotPasswordControllerProvider);
  ForgotPasswordController controller() =>
      container.read(forgotPasswordControllerProvider.notifier);

  setUp(() {
    repository = _MockAuthRepository();
    container = ProviderContainer.test(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    container.listen(forgotPasswordControllerProvider, (_, _) {});
  });

  test('começa no formulário', () {
    expect(state(), isA<ForgotPasswordIdle>());
  });

  test('envia o e-mail aparado e confirma o envio', () async {
    whenReset().thenAnswer((_) async {});

    await controller().submit(' ana@uni.br ');

    verify(() => repository.requestPasswordReset(email: 'ana@uni.br'));
    expect(state(), isA<ForgotPasswordSent>());
    expect((state() as ForgotPasswordSent).email, 'ana@uni.br');
  });

  test('fica em envio enquanto a request não volta', () async {
    final pending = Completer<void>();
    whenReset().thenAnswer((_) => pending.future);

    final call = controller().submit('ana@uni.br');
    expect(state(), isA<ForgotPasswordSending>());

    pending.complete();
    await call;
    expect(state(), isA<ForgotPasswordSent>());
  });

  test(
    'endpoint ausente no backend (404) avisa que está indisponível',
    () async {
      whenReset().thenThrow(const NotFoundException(message: 'Cannot POST'));

      await controller().submit('ana@uni.br');

      expect(
        (state() as ForgotPasswordFailed).message,
        ForgotPasswordController.unavailableMessage,
      );
    },
  );

  test('outras falhas mostram a mensagem da ApiException', () async {
    whenReset().thenThrow(const NetworkException());

    await controller().submit('ana@uni.br');

    expect(
      (state() as ForgotPasswordFailed).message,
      'Sem conexão com a internet.',
    );
  });

  test('reset volta ao formulário', () async {
    whenReset().thenAnswer((_) async {});
    await controller().submit('ana@uni.br');

    controller().reset();

    expect(state(), isA<ForgotPasswordIdle>());
  });
}
