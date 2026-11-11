import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';
import 'core/preferences/app_preferences.dart';
import 'core/realtime/realtime_providers.dart';
import 'features/auth/presentation/controllers/session_realtime_binding.dart';
import 'routing/app_router_provider.dart';
import 'routing/push_navigation.dart';
import 'shared/push/push_registration.dart';
import 'shared/design_system/design_system.dart';

/// Raiz visual do app: tema do design system + shell de navegação (go_router).
///
/// Também mantém o WebSocket ligado à sessão e ao ciclo de vida do app
/// (solta em background, retoma em foreground) e o token de push registrado
/// para o usuário logado.
class AutoUniApp extends ConsumerStatefulWidget {
  const AutoUniApp({super.key});

  @override
  ConsumerState<AutoUniApp> createState() => _AutoUniAppState();
}

class _AutoUniAppState extends ConsumerState<AutoUniApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onStateChange: (state) =>
          ref.read(realtimeClientProvider).handleAppLifecycleState(state),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(sessionRealtimeBindingProvider);
    // Mantém o registro do token de push ligado à sessão (S6-T1).
    ref.watch(pushRegistrationProvider);
    // Toque no push abre o destino; push com o app aberto vira aviso (S6-T2).
    ref.watch(pushNavigationProvider);
    final config = ref.watch(appConfigProvider);
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(
      appPreferencesProvider.select((prefs) => prefs.themeMode),
    );

    return MaterialApp.router(
      title: config.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      // Textos do app são pt-BR; os componentes do sistema (seletor de
      // datas, rótulos de acessibilidade) seguem o mesmo idioma.
      locale: appLocale,
      supportedLocales: const [appLocale],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: router,
      scaffoldMessengerKey: ref.watch(rootScaffoldMessengerKeyProvider),
      builder: (context, child) => _FlavorOverlay(config: config, child: child),
    );
  }
}

/// Idioma do app. Só pt-BR por enquanto: os textos não estão em arquivos de
/// tradução (ARB).
const Locale appLocale = Locale('pt', 'BR');

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
