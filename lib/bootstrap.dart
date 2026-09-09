import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';
import 'core/config/flavor.dart';

/// Monta a árvore raiz do app já com a [AppConfig] do ambiente injetada no
/// `ProviderScope` de topo. Separado de [runAutoUni] para poder ser exercido
/// em testes de widget sem `runApp`.
Widget buildAppRoot(AppConfig config) {
  return ProviderScope(
    overrides: [appConfigProvider.overrideWithValue(config)],
    child: const AutoUniApp(),
  );
}

/// Ponto de entrada compartilhado pelos entrypoints `main_dev` / `main_prod`.
///
/// Endpoints podem ser sobrescritos em tempo de build via
/// `--dart-define=API_BASE_URL=...` / `--dart-define=WS_BASE_URL=...`.
void runAutoUni(Flavor flavor) {
  WidgetsFlutterBinding.ensureInitialized();

  const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  const wsBaseUrl = String.fromEnvironment('WS_BASE_URL');

  final config = AppConfig.forFlavor(
    flavor,
    apiBaseUrl: apiBaseUrl,
    wsBaseUrl: wsBaseUrl,
  );

  runApp(buildAppRoot(config));
}
