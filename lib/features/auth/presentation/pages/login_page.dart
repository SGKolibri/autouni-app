import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/biometrics/biometric_authenticator.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/router/session_guard.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../domain/validators/credential_validators.dart';
import '../controllers/auth_controller.dart';
import '../controllers/biometric_login_controller.dart';

/// Login por e-mail e senha, com atalho de biometria quando disponível.
///
/// Não navega sozinha: quando a sessão abre, o guard de rotas leva ao
/// destino (ou à home).
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await ref
        .read(authControllerProvider.notifier)
        .login(email: _email.text, password: _password.text);
  }

  Future<void> _loginWithBiometrics() async {
    final result = await ref
        .read(authControllerProvider.notifier)
        .loginWithBiometrics();
    if (!mounted) return;
    final message = switch (result) {
      BiometricAuthResult.success => null,
      BiometricAuthResult.failed => 'Biometria não confirmada.',
      BiometricAuthResult.lockedOut =>
        'Biometria bloqueada temporariamente. Entre com sua senha.',
      BiometricAuthResult.unavailable =>
        'Biometria indisponível. Entre com sua senha.',
    };
    if (message != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = ref.watch(authControllerProvider);
    final loading = auth.isLoading;
    final sessionExpired = ref.watch(sessionExpiredNoticeProvider);
    final biometricAvailable =
        ref.watch(biometricLoginAvailableProvider).value ?? false;
    final error = auth.hasError ? _messageFor(auth.error) : null;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: AutofillGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.apartment,
                        size: AppSpacing.xxxl,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'AutoUni',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Entre com sua conta institucional',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      if (sessionExpired && error == null) ...[
                        const AppBanner(
                          tone: AppTone.warning,
                          message: 'Sua sessão expirou. Entre novamente.',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      if (error != null) ...[
                        AppBanner(tone: AppTone.danger, message: error),
                        const SizedBox(height: AppSpacing.lg),
                      ],
                      TextFormField(
                        key: const Key('login-email'),
                        controller: _email,
                        enabled: !loading,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'E-mail',
                          prefixIcon: Icon(Icons.mail_outline),
                        ),
                        validator: validateEmail,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        key: const Key('login-password'),
                        controller: _password,
                        enabled: !loading,
                        obscureText: _obscure,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _submit(),
                        decoration: InputDecoration(
                          labelText: 'Senha',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            tooltip: _obscure
                                ? 'Mostrar senha'
                                : 'Esconder senha',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                        validator: validatePassword,
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: loading
                              ? null
                              : () =>
                                    context.push(SessionRoutes.forgotPassword),
                          child: const Text('Esqueci minha senha'),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FilledButton(
                        key: const Key('login-submit'),
                        onPressed: loading ? null : _submit,
                        child: loading
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Entrar'),
                      ),
                      if (biometricAvailable) ...[
                        const SizedBox(height: AppSpacing.md),
                        OutlinedButton.icon(
                          onPressed: loading ? null : _loginWithBiometrics,
                          icon: const Icon(Icons.fingerprint),
                          label: const Text('Entrar com biometria'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _messageFor(Object? error) => switch (error) {
    UnauthorizedException() => 'E-mail ou senha incorretos.',
    ApiException(:final message) => message,
    _ => 'Não foi possível entrar. Tente novamente.',
  };
}
