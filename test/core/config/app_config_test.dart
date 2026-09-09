import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppConfig.forFlavor', () {
    test('dev aponta para o backend local e liga o log verboso', () {
      final config = AppConfig.forFlavor(Flavor.dev);

      expect(config.flavor, Flavor.dev);
      expect(config.appName, 'AutoUni Dev');
      expect(config.apiBaseUrl, AppConfig.defaultDevApiBaseUrl);
      expect(config.wsBaseUrl, AppConfig.defaultDevWsBaseUrl);
      expect(config.enableVerboseLogging, isTrue);
      expect(config.showFlavorBanner, isTrue);
    });

    test('prod aponta para o backend remoto e desliga o log verboso', () {
      final config = AppConfig.forFlavor(Flavor.prod);

      expect(config.flavor, Flavor.prod);
      expect(config.appName, 'AutoUni');
      expect(config.apiBaseUrl, AppConfig.defaultProdApiBaseUrl);
      expect(config.wsBaseUrl, AppConfig.defaultProdWsBaseUrl);
      expect(config.enableVerboseLogging, isFalse);
      expect(config.showFlavorBanner, isFalse);
    });

    test('produção usa esquemas seguros (https/wss)', () {
      final config = AppConfig.forFlavor(Flavor.prod);

      expect(Uri.parse(config.apiBaseUrl).scheme, 'https');
      expect(Uri.parse(config.wsBaseUrl).scheme, 'wss');
    });

    test('overrides de --dart-define substituem os defaults do flavor', () {
      final config = AppConfig.forFlavor(
        Flavor.dev,
        apiBaseUrl: 'https://staging.example.com',
        wsBaseUrl: 'wss://staging.example.com',
      );

      expect(config.apiBaseUrl, 'https://staging.example.com');
      expect(config.wsBaseUrl, 'wss://staging.example.com');
      expect(config.flavor, Flavor.dev, reason: 'override não muda o flavor');
    });

    test('override vazio ou só com espaços é ignorado', () {
      // String.fromEnvironment devolve '' quando o define não foi passado.
      final config = AppConfig.forFlavor(
        Flavor.prod,
        apiBaseUrl: '',
        wsBaseUrl: '   ',
      );

      expect(config.apiBaseUrl, AppConfig.defaultProdApiBaseUrl);
      expect(config.wsBaseUrl, AppConfig.defaultProdWsBaseUrl);
    });

    test('remove a barra final das URLs para não gerar caminhos com //', () {
      final config = AppConfig.forFlavor(
        Flavor.dev,
        apiBaseUrl: 'https://api.example.com/',
        wsBaseUrl: 'wss://api.example.com/',
      );

      expect(config.apiBaseUrl, 'https://api.example.com');
      expect(config.wsBaseUrl, 'wss://api.example.com');
    });

    test('rejeita URL sem esquema http/https', () {
      expect(
        () => AppConfig.forFlavor(Flavor.dev, apiBaseUrl: 'api.example.com'),
        throwsArgumentError,
      );
    });

    test('rejeita URL de websocket sem esquema ws/wss', () {
      expect(
        () => AppConfig.forFlavor(Flavor.dev, wsBaseUrl: 'api.example.com'),
        throwsArgumentError,
      );
    });

    test('define timeouts de rede utilizáveis pelo cliente HTTP', () {
      final config = AppConfig.forFlavor(Flavor.dev);

      expect(config.connectTimeout, const Duration(seconds: 15));
      expect(config.receiveTimeout, const Duration(seconds: 20));
    });
  });

  group('AppConfig valor', () {
    test('duas configs do mesmo flavor são iguais', () {
      expect(AppConfig.forFlavor(Flavor.dev), AppConfig.forFlavor(Flavor.dev));
      expect(
        AppConfig.forFlavor(Flavor.dev).hashCode,
        AppConfig.forFlavor(Flavor.dev).hashCode,
      );
    });

    test('configs de flavors diferentes não são iguais', () {
      expect(
        AppConfig.forFlavor(Flavor.dev),
        isNot(AppConfig.forFlavor(Flavor.prod)),
      );
    });

    test('toString descreve flavor e endpoints', () {
      final description = AppConfig.forFlavor(Flavor.dev).toString();

      expect(description, contains('dev'));
      expect(description, contains(AppConfig.defaultDevApiBaseUrl));
    });
  });
}
