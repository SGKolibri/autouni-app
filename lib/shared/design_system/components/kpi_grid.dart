import 'package:flutter/material.dart';

import '../tokens/app_spacing.dart';

/// Grade de [KpiCard]s em colunas, com a altura de cada linha medida pelo
/// card mais alto dela.
///
/// Substitui `GridView` com `childAspectRatio`, que fixa a altura pela
/// largura da tela e estoura ("BOTTOM OVERFLOWED") quando o conteúdo cresce:
/// variação no rodapé, telas estreitas ou fonte do sistema maior.
class KpiGrid extends StatelessWidget {
  const KpiGrid({
    required this.children,
    this.columns = 2,
    this.spacing = AppSpacing.md,
    super.key,
  });

  final List<Widget> children;
  final int columns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final cells = <Widget>[];
      for (var column = 0; column < columns; column++) {
        if (column > 0) cells.add(SizedBox(width: spacing));
        final index = start + column;
        cells.add(
          Expanded(
            child: index < children.length
                ? children[index]
                : const SizedBox.shrink(),
          ),
        );
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: spacing));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: cells,
          ),
        ),
      );
    }
    return Column(mainAxisSize: MainAxisSize.min, children: rows);
  }
}
