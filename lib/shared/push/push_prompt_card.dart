import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design_system/design_system.dart';
import 'push_registration.dart';

/// Convite para ativar os alertas no celular, mostrado só quando o sistema
/// ainda não perguntou ([PushStatus.promptable]). Explica o porquê antes do
/// prompt do sistema, que só abre em "Ativar alertas".
class PushPromptCard extends ConsumerWidget {
  const PushPromptCard({this.padding = EdgeInsets.zero, super.key});

  /// Espaço em volta do cartão — só existe quando ele aparece.
  final EdgeInsetsGeometry padding;

  Future<void> _accept(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(pushRegistrationProvider.notifier);
    await notifier.accept();
    final message = switch (ref.read(pushRegistrationProvider)) {
      PushStatus.enabled => 'Alertas ativados.',
      PushStatus.denied =>
        'Sem permissão. Você pode ativar nos ajustes do aparelho.',
      PushStatus.failed =>
        'Não foi possível ativar agora. Tentaremos de novo no próximo acesso.',
      _ => null,
    };
    if (message == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(pushRegistrationProvider) != PushStatus.promptable) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);

    return Padding(padding: padding, child: _card(context, ref, theme));
  }

  Widget _card(BuildContext context, WidgetRef ref, ThemeData theme) {
    return Card(
      key: const Key('push-prompt'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Receba alertas no celular',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Avisamos quando um dispositivo falhar, o consumo '
                        'sair do normal ou uma automação rodar — mesmo com o '
                        'app fechado.',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                spacing: AppSpacing.xs,
                children: [
                  TextButton(
                    key: const Key('push-prompt-dismiss'),
                    onPressed: () =>
                        ref.read(pushRegistrationProvider.notifier).dismiss(),
                    child: const Text('Agora não'),
                  ),
                  FilledButton(
                    key: const Key('push-prompt-accept'),
                    onPressed: () => _accept(context, ref),
                    child: const Text('Ativar alertas'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
