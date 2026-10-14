import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/realtime/realtime_client.dart';
import '../../core/realtime/realtime_providers.dart';
import '../design_system/design_system.dart';

/// [AppTopBar] com o ponto de status do tempo real ligado ao WebSocket.
class LiveTopBar extends ConsumerWidget implements PreferredSizeWidget {
  const LiveTopBar({required this.title, this.actions, super.key});

  final String title;
  final List<Widget>? actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(realtimeStatusProvider);
    return AppTopBar(
      title: title,
      actions: actions,
      showConnectionDot: true,
      connected: status == RealtimeConnectionStatus.connected,
    );
  }
}
