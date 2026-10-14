import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';
import 'flavor.dart';

/// Config global do app.
///
/// Não tem valor padrão de propósito: o bootstrap (`buildAppRoot`) é obrigado a
/// sobrescrevê-lo com a [AppConfig] do ambiente. Ler sem override é um erro de
/// programação e falha alto em vez de silenciosamente assumir um ambiente.
final appConfigProvider = Provider<AppConfig>(
  (ref) => throw UnimplementedError(
    'appConfigProvider precisa ser sobrescrito no bootstrap com a AppConfig do ambiente',
  ),
  name: 'appConfigProvider',
);

/// Atalho para a URL base da API — evita `ref.watch(appConfigProvider).apiBaseUrl`
/// espalhado pelas camadas de rede.
final apiBaseUrlProvider = Provider<String>(
  (ref) => ref.watch(appConfigProvider).apiBaseUrl,
  name: 'apiBaseUrlProvider',
);

/// Atalho para a URL base do WebSocket.
final wsBaseUrlProvider = Provider<String>(
  (ref) => ref.watch(appConfigProvider).wsBaseUrl,
  name: 'wsBaseUrlProvider',
);

/// Atalho para o [Flavor] atual, útil em gating de UI/diagnóstico.
final flavorProvider = Provider<Flavor>(
  (ref) => ref.watch(appConfigProvider).flavor,
  name: 'flavorProvider',
);
