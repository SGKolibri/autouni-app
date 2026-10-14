import 'package:flutter/material.dart';

import '../../shared/design_system/design_system.dart';

/// Tela de abertura enquanto a sessão guardada é restaurada.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.apartment,
              size: AppSpacing.xxxl,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text('AutoUni', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.xl),
            const SizedBox.square(
              dimension: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ),
      ),
    );
  }
}
