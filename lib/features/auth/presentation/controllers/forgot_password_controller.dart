import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/auth_data_providers.dart';

/// Etapas do pedido de recuperação de senha.
sealed class ForgotPasswordState {
  const ForgotPasswordState();
}

class ForgotPasswordIdle extends ForgotPasswordState {
  const ForgotPasswordIdle();
}

class ForgotPasswordSending extends ForgotPasswordState {
  const ForgotPasswordSending();
}

/// Pedido aceito. A mensagem não confirma se o e-mail existe.
class ForgotPasswordSent extends ForgotPasswordState {
  const ForgotPasswordSent(this.email);

  final String email;
}

class ForgotPasswordFailed extends ForgotPasswordState {
  const ForgotPasswordFailed(this.message);

  final String message;
}

class ForgotPasswordController extends Notifier<ForgotPasswordState> {
  /// Mensagem enquanto o backend não tiver `POST /auth/forgot-password`.
  static const String unavailableMessage =
      'A recuperação de senha ainda não está disponível. '
      'Procure o administrador do sistema.';

  @override
  ForgotPasswordState build() => const ForgotPasswordIdle();

  Future<void> submit(String email) async {
    if (state is ForgotPasswordSending) return;
    state = const ForgotPasswordSending();
    try {
      await ref
          .read(authRepositoryProvider)
          .requestPasswordReset(email: email.trim());
      if (ref.mounted) state = ForgotPasswordSent(email.trim());
    } on NotFoundException {
      if (ref.mounted) state = const ForgotPasswordFailed(unavailableMessage);
    } on ApiException catch (error) {
      if (ref.mounted) state = ForgotPasswordFailed(error.message);
    }
  }

  /// Volta ao formulário (ex.: "usar outro e-mail").
  void reset() => state = const ForgotPasswordIdle();
}

final forgotPasswordControllerProvider =
    NotifierProvider.autoDispose<ForgotPasswordController, ForgotPasswordState>(
      ForgotPasswordController.new,
      name: 'forgotPasswordControllerProvider',
    );
