import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/design_system/design_system.dart';
import '../../domain/models/user.dart';
import '../../domain/validators/profile_validators.dart';
import '../controllers/profile_controller.dart';

/// Editar nome e telefone. E-mail e papel são só leitura (mudam pelo
/// administrador no painel web).
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    return Scaffold(
      appBar: const AppTopBar(title: 'Perfil'),
      body: switch (profile) {
        AsyncValue(:final User value) => _ProfileForm(user: value),
        AsyncValue(isLoading: true) => const Center(
          child: CircularProgressIndicator(),
        ),
        _ => const AppEmptyState(
          icon: Icons.person_off_outlined,
          title: 'Sem sessão',
        ),
      },
    );
  }
}

class _ProfileForm extends ConsumerStatefulWidget {
  const _ProfileForm({required this.user});

  final User user;

  @override
  ConsumerState<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<_ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.user.name);
    _phone = TextEditingController(text: widget.user.phone ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    setState(() => _saving = true);
    final error = await ref
        .read(profileControllerProvider)
        .save(name: _name.text, phone: _phone.text);
    if (!mounted) return;
    setState(() => _saving = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(error ?? 'Perfil atualizado.')));
    if (error == null && router.canPop()) router.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          TextFormField(
            key: const Key('profile-name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            decoration: const InputDecoration(
              labelText: 'Nome',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: validateName,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            key: const Key('profile-phone'),
            controller: _phone,
            keyboardType: TextInputType.phone,
            autofillHints: const [AutofillHints.telephoneNumber],
            decoration: const InputDecoration(
              labelText: 'Telefone (opcional)',
              hintText: '(62) 99999-0000',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
            validator: validatePhone,
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            initialValue: user.email,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'E-mail',
              prefixIcon: Icon(Icons.mail_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextFormField(
            initialValue: user.role.label,
            enabled: false,
            decoration: const InputDecoration(
              labelText: 'Papel',
              helperText: 'E-mail e papel são alterados pelo administrador.',
              prefixIcon: Icon(Icons.badge_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            key: const Key('profile-save'),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
