import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/biometrics/biometric_authenticator.dart';
import '../../../../core/biometrics/biometric_providers.dart';
import '../../../../shared/design_system/design_system.dart';
import '../controllers/auth_controller.dart';
import '../controllers/biometric_login_controller.dart';

/// Aba "Ajustes" mínima: conta, acesso por biometria e logout. A S6-T5
/// completa com perfil, preferências e aparência.
class AccountSettingsPage extends ConsumerWidget {
  const AccountSettingsPage({super.key});

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você vai precisar entrar com e-mail e senha de novo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  Future<void> _toggleBiometrics(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    final controller = ref.read(biometricLoginEnabledProvider.notifier);
    if (!enable) {
      await controller.disable();
      return;
    }
    final result = await controller.enable();
    if (!context.mounted) return;
    final message = switch (result) {
      BiometricAuthResult.success => 'Acesso por biometria ativado.',
      BiometricAuthResult.failed => 'Biometria não confirmada.',
      BiometricAuthResult.lockedOut =>
        'Biometria bloqueada temporariamente. Tente mais tarde.',
      BiometricAuthResult.unavailable =>
        'Este aparelho não tem biometria disponível.',
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).value;
    final biometricsEnabled =
        ref.watch(biometricLoginEnabledProvider).value ?? false;
    final deviceHasBiometrics = ref.watch(_deviceHasBiometricsProvider);

    return Scaffold(
      appBar: const AppTopBar(title: 'Ajustes'),
      body: ListView(
        children: [
          if (user != null)
            ListTile(
              leading: CircleAvatar(
                child: Text(user.name.isEmpty ? '?' : user.name[0]),
              ),
              title: Text(user.name),
              subtitle: Text(user.email),
              trailing: StatusBadge(user.role.label, tone: AppTone.info),
            ),
          const Divider(),
          if (deviceHasBiometrics.value ?? false)
            SwitchListTile(
              key: const Key('settings-biometrics'),
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Entrar com biometria'),
              subtitle: const Text('Desbloqueie o app sem digitar a senha'),
              value: biometricsEnabled,
              onChanged: (value) => _toggleBiometrics(context, ref, value),
            ),
          ListTile(
            key: const Key('settings-logout'),
            leading: Icon(Icons.logout, color: theme.colorScheme.error),
            title: Text(
              'Sair',
              style: TextStyle(color: theme.colorScheme.error),
            ),
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }
}

final _deviceHasBiometricsProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(biometricAuthenticatorProvider).isAvailable(),
);
