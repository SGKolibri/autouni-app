import 'flavor.dart';

/// Configuração imutável do app, resolvida no bootstrap a partir do [Flavor]
/// e de eventuais overrides vindos de `--dart-define`.
///
/// É injetada no topo da árvore via `appConfigProvider` para que qualquer
/// camada (rede, WebSocket, tema) leia endpoints e flags sem depender de
/// `String.fromEnvironment` espalhado pelo código.
class AppConfig {
  const AppConfig._({
    required this.flavor,
    required this.appName,
    required this.apiBaseUrl,
    required this.wsBaseUrl,
    required this.enableVerboseLogging,
    required this.showFlavorBanner,
    required this.connectTimeout,
    required this.receiveTimeout,
  });

  /// Endpoints padrão do ambiente de desenvolvimento (backend local).
  static const String defaultDevApiBaseUrl = 'http://localhost:3000';
  static const String defaultDevWsBaseUrl = 'ws://localhost:3000';

  /// Endpoints padrão de produção (sempre em canais seguros).
  static const String defaultProdApiBaseUrl = 'https://api.autouni.app';
  static const String defaultProdWsBaseUrl = 'wss://api.autouni.app';

  /// Timeouts de rede reutilizados pelo cliente HTTP (S1-T2).
  static const Duration _connectTimeout = Duration(seconds: 15);
  static const Duration _receiveTimeout = Duration(seconds: 20);

  final Flavor flavor;

  /// Nome exibido do app; varia por ambiente para diferenciar builds no device.
  final String appName;

  /// URL base da API REST, sem barra final.
  final String apiBaseUrl;

  /// URL base do WebSocket, sem barra final.
  final String wsBaseUrl;

  /// Liga logs verbosos (interceptors, eventos de socket) fora de produção.
  final bool enableVerboseLogging;

  /// Mostra a faixa de identificação do ambiente sobre a UI.
  final bool showFlavorBanner;

  final Duration connectTimeout;
  final Duration receiveTimeout;

  /// Monta a config de um [flavor], aplicando overrides opcionais.
  ///
  /// [apiBaseUrl] e [wsBaseUrl] normalmente vêm de `--dart-define`; um valor
  /// vazio ou só com espaços (o que `String.fromEnvironment` devolve quando o
  /// define não foi passado) é ignorado e mantém o default do ambiente.
  factory AppConfig.forFlavor(
    Flavor flavor, {
    String? apiBaseUrl,
    String? wsBaseUrl,
  }) {
    final isDev = flavor.isDev;

    final resolvedApi = _resolveUrl(
      override: apiBaseUrl,
      fallback: isDev ? defaultDevApiBaseUrl : defaultProdApiBaseUrl,
      allowedSchemes: const {'http', 'https'},
      label: 'apiBaseUrl',
    );
    final resolvedWs = _resolveUrl(
      override: wsBaseUrl,
      fallback: isDev ? defaultDevWsBaseUrl : defaultProdWsBaseUrl,
      allowedSchemes: const {'ws', 'wss'},
      label: 'wsBaseUrl',
    );

    return AppConfig._(
      flavor: flavor,
      appName: isDev ? 'AutoUni Dev' : 'AutoUni',
      apiBaseUrl: resolvedApi,
      wsBaseUrl: resolvedWs,
      enableVerboseLogging: isDev,
      showFlavorBanner: isDev,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
    );
  }

  static String _resolveUrl({
    required String? override,
    required String fallback,
    required Set<String> allowedSchemes,
    required String label,
  }) {
    final trimmed = override?.trim() ?? '';
    final raw = trimmed.isEmpty ? fallback : trimmed;
    final withoutTrailingSlash = raw.endsWith('/')
        ? raw.substring(0, raw.length - 1)
        : raw;

    final uri = Uri.tryParse(withoutTrailingSlash);
    if (uri == null || !allowedSchemes.contains(uri.scheme)) {
      throw ArgumentError.value(
        withoutTrailingSlash,
        label,
        'esquema inválido; use um de ${allowedSchemes.join('/')}',
      );
    }
    return withoutTrailingSlash;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppConfig &&
          runtimeType == other.runtimeType &&
          flavor == other.flavor &&
          appName == other.appName &&
          apiBaseUrl == other.apiBaseUrl &&
          wsBaseUrl == other.wsBaseUrl &&
          enableVerboseLogging == other.enableVerboseLogging &&
          showFlavorBanner == other.showFlavorBanner &&
          connectTimeout == other.connectTimeout &&
          receiveTimeout == other.receiveTimeout;

  @override
  int get hashCode => Object.hash(
    flavor,
    appName,
    apiBaseUrl,
    wsBaseUrl,
    enableVerboseLogging,
    showFlavorBanner,
    connectTimeout,
    receiveTimeout,
  );

  @override
  String toString() =>
      'AppConfig(flavor: ${flavor.name}, api: $apiBaseUrl, ws: $wsBaseUrl)';
}
