import 'package:flutter/material.dart';

import '../tokens/app_palette.dart' show SemanticColorsX;
import '../tokens/app_spacing.dart';

/// App bar padrão do AutoUni. Opcionalmente mostra um ponto de status da
/// conexão em tempo real ao lado do título.
class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({
    required this.title,
    this.actions,
    this.leading,
    this.showConnectionDot = false,
    this.connected = true,
    this.bottom,
    super.key,
  });

  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showConnectionDot;
  final bool connected;
  final PreferredSizeWidget? bottom;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final semantic = context.semanticColors;

    return AppBar(
      leading: leading,
      bottom: bottom,
      actions: actions,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: Text(title, overflow: TextOverflow.ellipsis)),
          if (showConnectionDot) ...[
            const SizedBox(width: AppSpacing.sm),
            Tooltip(
              message: connected ? 'Conectado' : 'Reconectando',
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: connected ? semantic.online : semantic.warning,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
