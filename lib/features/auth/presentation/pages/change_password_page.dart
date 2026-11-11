import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../domain/validators/credential_validators.dart';
import '../../domain/validators/profile_validators.dart';
import '../controllers/profile_controller.dart';

/// Trocar senha: confirma a atual antes de gravar a nova.
class ChangePasswordPage extends ConsumerStatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  ConsumerState<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends ConsumerState<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await ref
        .read(profileControllerProvider)
        .changePassword(currentPassword: _current.text, newPassword: _new.text);
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = error;
    });
    if (error != null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Senha alterada.')));
    if (router.canPop()) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final visibility = IconButton(
      tooltip: _obscure ? 'Mostrar senhas' : 'Esconder senhas',
      icon: Icon(
        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
      ),
      onPressed: () => setState(() => _obscure = !_obscure),
    );

    return Scaffold(
      appBar: const AppTopBar(title: 'Trocar senha'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (_error != null) ...[
              AppBanner(tone: AppTone.danger, message: _error!),
              const SizedBox(height: AppSpacing.lg),
            ],
            TextFormField(
              key: const Key('password-current'),
              controller: _current,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Senha atual',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: visibility,
              ),
              validator: validatePassword,
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('password-new'),
              controller: _new,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.newPassword],
              decoration: const InputDecoration(
                labelText: 'Nova senha',
                helperText: 'Pelo menos 8 caracteres, com letras e números.',
                prefixIcon: Icon(Icons.lock_reset),
              ),
              validator: (value) =>
                  validateNewPassword(value, current: _current.text),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextFormField(
              key: const Key('password-confirm'),
              controller: _confirm,
              obscureText: _obscure,
              decoration: const InputDecoration(
                labelText: 'Confirmar nova senha',
                prefixIcon: Icon(Icons.lock_reset),
              ),
              validator: (value) =>
                  validatePasswordConfirmation(value, _new.text),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              key: const Key('password-save'),
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Trocar senha'),
            ),
          ],
        ),
      ),
    );
  }
}
