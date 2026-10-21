import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import 'app.dart';
import 'core/cache/cache_providers.dart';
import 'core/cache/local_cache.dart';
import 'core/config/app_config.dart';
import 'core/config/app_config_provider.dart';
import 'core/config/firebase_config.dart';
import 'core/config/flavor.dart';
import 'core/config/provider_retry.dart';
import 'core/network/network_providers.dart';
import 'core/network/secure_auth_token_store.dart';
import 'core/push/firebase_push_messaging.dart';
import 'core/push/push_messaging.dart';
import 'core/push/push_providers.dart';
import 'core/session/session_hooks.dart';
import 'features/auth/data/biometrics/biometric_login_settings.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'shared/push/push_prompt_store.dart';
import 'shared/rbac/rbac_providers.dart';

/// Monta a árvore raiz do app com as implementações de produção injetadas no
/// `ProviderScope` de topo: [AppConfig] do ambiente, armazenamento seguro,
/// cache local e o papel do usuário logado para o RBAC. Separado de
/// [runAutoUni] para poder ser exercido em testes de widget sem `runApp`.
///
/// Sem [cache], usa um cache só em memória (testes). Sem [push], o push fica
/// desligado.
Widget buildAppRoot(
  AppConfig config, {
  LocalCache? cache,
  PushMessaging? push,
}) {
  return ProviderScope(
    retry: noAutomaticRetry,
    overrides: [
      appConfigProvider.overrideWithValue(config),
      // Sessão persistida no Keychain/Keystore em vez de só em memória.
      authTokenStoreProvider.overrideWith((ref) => SecureAuthTokenStore()),
      biometricLoginSettingsProvider.overrideWith(
        (ref) => SecureBiometricLoginSettings(),
      ),
      if (cache != null) localCacheProvider.overrideWithValue(cache),
      if (push != null) ...[
        pushMessagingProvider.overrideWithValue(push),
        pushPromptStoreProvider.overrideWith((ref) => SecurePushPromptStore()),
      ],
      // `shared/` não conhece a autenticação: o papel vem da sessão daqui.
      currentUserRoleProvider.overrideWith(
        (ref) => ref.watch(authControllerProvider).value?.role,
      ),
      sessionUserIdProvider.overrideWith(
        (ref) => ref.watch(authControllerProvider).value?.id,
      ),
    ],
    child: const AutoUniApp(),
  );
}

/// Ponto de entrada compartilhado pelos entrypoints `main_dev` / `main_prod`.
///
/// Endpoints podem ser sobrescritos em tempo de build via
/// `--dart-define=API_BASE_URL=...` / `--dart-define=WS_BASE_URL=...`.
///
/// O push (FCM) liga com `--dart-define=FIREBASE_API_KEY=... FIREBASE_PROJECT_ID
/// FIREBASE_MESSAGING_SENDER_ID FIREBASE_ANDROID_APP_ID` (e/ou
/// `FIREBASE_IOS_APP_ID` + `FIREBASE_IOS_BUNDLE_ID`); sem eles, fica desligado.
Future<void> runAutoUni(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  const wsBaseUrl = String.fromEnvironment('WS_BASE_URL');

  final config = AppConfig.forFlavor(
    flavor,
    apiBaseUrl: apiBaseUrl,
    wsBaseUrl: wsBaseUrl,
    firebase: FirebaseConfig.fromDefines(
      apiKey: const String.fromEnvironment('FIREBASE_API_KEY'),
      projectId: const String.fromEnvironment('FIREBASE_PROJECT_ID'),
      messagingSenderId: const String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
      ),
      androidAppId: const String.fromEnvironment('FIREBASE_ANDROID_APP_ID'),
      iosAppId: const String.fromEnvironment('FIREBASE_IOS_APP_ID'),
      iosBundleId: const String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
    ),
  );

  await Hive.initFlutter();
  final cache = await HiveLocalCache.open();
  final push = await initFirebasePush(config.firebase);

  runApp(buildAppRoot(config, cache: cache, push: push));
}
