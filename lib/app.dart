import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';

/// Raiz visual do app.
///
/// Por enquanto entrega apenas um placeholder; o shell de navegação real
/// (go_router + bottom nav) chega na S1-T5 e o tema completo na S1-T4.
class AutoUniApp extends ConsumerWidget {
  const AutoUniApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);

    return MaterialApp(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E5AA8)),
        useMaterial3: true,
      ),
      builder: (context, child) => _FlavorOverlay(config: config, child: child),
      home: const _PlaceholderHome(),
    );
  }
}

/// Placeholder da tela inicial até o shell de navegação da S1-T5.
class _PlaceholderHome extends StatelessWidget {
  const _PlaceholderHome();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'AutoUni',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
        ),
      ),
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
