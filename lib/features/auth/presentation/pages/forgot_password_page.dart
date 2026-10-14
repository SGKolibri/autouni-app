import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/session_guard.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../domain/validators/credential_validators.dart';
import '../controllers/forgot_password_controller.dart';

/// Pedido de e-mail de recuperação de senha.
class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(forgotPasswordControllerProvider.notifier)
        .submit(_email.text);
  }

  void _backToLogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(SessionRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(forgotPasswordControllerProvider);
    final sending = state is ForgotPasswordSending;

    return Scaffold(
      appBar: AppTopBar(
        title: 'Recuperar senha',
        leading: BackButton(onPressed: _backToLogin),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: switch (state) {
            ForgotPasswordSent(:final email) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppBanner(
                  tone: AppTone.success,
                  title: 'Pedido enviado',
                  message:
                      'Se $email estiver cadastrado, você vai receber as '
                      'instruções para criar uma nova senha.',
                ),
                const SizedBox(height: AppSpacing.xl),
                FilledButton(
                  onPressed: _backToLogin,
                  child: const Text('Voltar ao login'),
                ),
              ],
            ),
            _ => Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Informe o e-mail da sua conta. Enviaremos as instruções '
                    'para criar uma nova senha.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (state case ForgotPasswordFailed(:final message)) ...[
                    AppBanner(tone: AppTone.danger, message: message),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  TextFormField(
                    key: const Key('forgot-email'),
                    controller: _email,
                    enabled: !sending,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    onFieldSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'E-mail',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton(
                    key: const Key('forgot-submit'),
                    onPressed: sending ? null : _submit,
                    child: sending
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar instruções'),
                  ),
                ],
              ),
            ),
          },
        ),
      ),
    );
  }
}
