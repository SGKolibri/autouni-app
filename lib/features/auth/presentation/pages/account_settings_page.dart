import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/biometrics/biometric_authenticator.dart';
import '../../../../core/biometrics/biometric_providers.dart';
import '../../../../core/preferences/app_preferences.dart';
import '../../../../core/router/app_paths.dart';
import '../../../../shared/design_system/design_system.dart';
import '../../../../shared/push/push_registration.dart';
import '../controllers/auth_controller.dart';
import '../controllers/biometric_login_controller.dart';
import '../controllers/profile_controller.dart';

/// Aba Ajustes: perfil, segurança (senha e biometria), alertas por push,
/// aparência, idioma, relatórios e sair.
class AccountSettingsPage extends ConsumerWidget {
  const AccountSettingsPage({super.key});

  static void _show(BuildContext context, String message) =>
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));

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
    _show(context, switch (result) {
      BiometricAuthResult.success => 'Acesso por biometria ativado.',
      BiometricAuthResult.failed => 'Biometria não confirmada.',
      BiometricAuthResult.lockedOut =>
        'Biometria bloqueada temporariamente. Tente mais tarde.',
      BiometricAuthResult.unavailable =>
        'Este aparelho não tem biometria disponível.',
    });
  }

  Future<void> _togglePush(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    await ref.read(pushRegistrationProvider.notifier).setEnabled(enable);
    if (!context.mounted) return;
    final message = switch (ref.read(pushRegistrationProvider)) {
      PushStatus.enabled => 'Alertas por push ativados.',
      PushStatus.off => 'Alertas por push desligados neste aparelho.',
      PushStatus.denied =>
        'Os alertas estão bloqueados nas configurações do sistema. '
            'Libere lá para receber.',
      PushStatus.failed =>
        'Não foi possível ativar agora. Tentaremos de novo na próxima vez.',
      _ => null,
    };
    if (message != null) _show(context, message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final user =
        ref.watch(profileProvider).value ??
        ref.watch(authControllerProvider).value;
    final preferences = ref.watch(appPreferencesProvider);
    final pushStatus = ref.watch(pushRegistrationProvider);
    final biometricsEnabled =
        ref.watch(biometricLoginEnabledProvider).value ?? false;
    final deviceHasBiometrics = ref.watch(_deviceHasBiometricsProvider);

    Widget header(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );

    final pushAvailable = pushStatus != PushStatus.unavailable;
    final pushOn =
        preferences.pushEnabled &&
        pushStatus != PushStatus.denied &&
        pushStatus != PushStatus.off;

    return Scaffold(
      appBar: const AppTopBar(title: 'Ajustes'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
        children: [
          if (user != null)
            ListTile(
              key: const Key('settings-profile'),
              leading: CircleAvatar(
                child: Text(user.name.isEmpty ? '?' : user.name[0]),
              ),
              title: Text(user.name),
              subtitle: Text([user.email, ?user.phone].join('\n')),
              isThreeLine: user.phone != null,
              trailing: StatusBadge(user.role.label, tone: AppTone.info),
              onTap: () => context.push(AppPaths.profile),
            ),
          header('Segurança'),
          ListTile(
            key: const Key('settings-password'),
            leading: const Icon(Icons.password),
            title: const Text('Trocar senha'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppPaths.changePassword),
          ),
          if (deviceHasBiometrics.value ?? false)
            SwitchListTile(
              key: const Key('settings-biometrics'),
              secondary: const Icon(Icons.fingerprint),
              title: const Text('Entrar com biometria'),
              subtitle: const Text('Desbloqueie o app sem digitar a senha'),
              value: biometricsEnabled,
              onChanged: (value) => _toggleBiometrics(context, ref, value),
            ),
          header('Notificações'),
          SwitchListTile(
            key: const Key('settings-push'),
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Alertas por push'),
            subtitle: Text(switch (pushStatus) {
              PushStatus.unavailable => 'Indisponível neste aparelho',
              PushStatus.denied => 'Bloqueados nas configurações do sistema',
              PushStatus.off => 'Desligados neste aparelho',
              PushStatus.enabled => 'Ativos neste aparelho',
              PushStatus.failed => 'Não registrados; tentaremos de novo',
              PushStatus.checking => 'Verificando…',
              PushStatus.promptable ||
              PushStatus.dismissed => 'Ainda não autorizados',
            }),
            value: pushAvailable && pushOn,
            onChanged: !pushAvailable || pushStatus == PushStatus.checking
                ? null
                : (value) => _togglePush(context, ref, value),
          ),
          header('Aparência'),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: SegmentedButton<ThemeMode>(
              key: const Key('settings-theme'),
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: Icon(Icons.brightness_auto),
                  label: Text('Sistema'),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode_outlined),
                  label: Text('Claro'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode_outlined),
                  label: Text('Escuro'),
                ),
              ],
              selected: {preferences.themeMode},
              onSelectionChanged: (selection) => ref
                  .read(appPreferencesProvider.notifier)
                  .setThemeMode(selection.single),
            ),
          ),
          const ListTile(
            key: Key('settings-language'),
            leading: Icon(Icons.language),
            title: Text('Idioma'),
            subtitle: Text('Português (Brasil)'),
          ),
          header('Dados'),
          ListTile(
            key: const Key('settings-reports'),
            leading: const Icon(Icons.description_outlined),
            title: const Text('Relatórios'),
            subtitle: const Text('Gerar e baixar em PDF, CSV ou XLSX'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push(AppPaths.reportsRoot),
          ),
          const Divider(),
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
