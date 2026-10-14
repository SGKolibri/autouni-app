import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/realtime/realtime_client.dart';
import '../../core/realtime/realtime_providers.dart';
import '../design_system/design_system.dart';

/// Banner de "tempo real indisponível": aparece enquanto o WebSocket tenta
/// reconectar, ou quando o servidor recusou a conexão (com "Tentar de
/// novo"). Os dados na tela continuam válidos, só deixam de se atualizar
/// sozinhos.
class RealtimeStatusBanner extends ConsumerWidget {
  const RealtimeStatusBanner({
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      0,
    ),
    super.key,
  });

  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(realtimeStatusProvider);
    final banner = switch (status) {
      RealtimeConnectionStatus.reconnecting => AppBanner.wsDisconnected(),
      RealtimeConnectionStatus.unauthorized => AppBanner.wsDisconnected(
        onRetry: () => ref.read(realtimeClientProvider).connect(),
      ),
      _ => null,
    };
    return AnimatedSize(
      duration: AppDuration.medium,
      child: banner == null
          ? const SizedBox(width: double.infinity)
          : Padding(padding: padding, child: banner),
    );
  }
}
