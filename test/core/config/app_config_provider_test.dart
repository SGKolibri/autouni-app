import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/app_config_provider.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('appConfigProvider', () {
    test('falha alto quando o bootstrap esquece de sobrescrever a config', () {
      final container = ProviderContainer.test();

      // Riverpod 3 embrulha erros de inicialização de provider em ProviderException.
      expect(
        () => container.read(appConfigProvider),
        throwsA(
          isA<ProviderException>().having(
            (e) => e.exception,
            'exception',
            isA<UnimplementedError>(),
          ),
        ),
      );
    });

    test('devolve a config injetada pelo bootstrap', () {
      final config = AppConfig.forFlavor(Flavor.prod);
      final container = ProviderContainer.test(
        overrides: [appConfigProvider.overrideWithValue(config)],
      );

      expect(container.read(appConfigProvider), same(config));
    });

    test('atalhos derivados acompanham a config injetada', () {
      final config = AppConfig.forFlavor(Flavor.dev);
      final container = ProviderContainer.test(
        overrides: [appConfigProvider.overrideWithValue(config)],
      );

      expect(container.read(apiBaseUrlProvider), config.apiBaseUrl);
      expect(container.read(wsBaseUrlProvider), config.wsBaseUrl);
      expect(container.read(flavorProvider), Flavor.dev);
    });
  });
}
