import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';
import 'core/router/router_provider.dart';
import 'shared/design_system/design_system.dart';

/// Raiz visual do app: tema do design system + shell de navegação (go_router).
class AutoUniApp extends ConsumerWidget {
  const AutoUniApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
      builder: (context, child) => _FlavorOverlay(config: config, child: child),
    );
  }
}

/// Faixa de identificação do ambiente, sobreposta à UI apenas quando
/// [AppConfig.showFlavorBanner] está ligado (dev).
class _FlavorOverlay extends StatelessWidget {
  const _FlavorOverlay({required this.config, required this.child});

  final AppConfig config;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final content = child ?? const SizedBox.shrink();
    if (!config.showFlavorBanner) return content;

    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        content,
        Positioned(
          top: 0,
          left: 0,
          child: SafeArea(
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                color: Colors.black.withValues(alpha: 0.6),
                child: Text(
                  config.flavor.label,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
