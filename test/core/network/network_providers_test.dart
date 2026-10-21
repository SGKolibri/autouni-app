import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/app_config_provider.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:autouni_app/core/network/auth_token_store.dart';
import 'package:autouni_app/core/network/network_providers.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer containerForDev() => ProviderContainer.test(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.forFlavor(Flavor.dev)),
    ],
  );

  test('dioProvider entrega um Dio configurado pela AppConfig', () {
    final container = containerForDev();

    final dio = container.read(dioProvider);

    expect(dio, isA<Dio>());
    expect(dio.options.baseUrl, container.read(appConfigProvider).apiBaseUrl);
  });

  test('authTokenStoreProvider é um singleton dentro do container', () {
    final container = containerForDev();

    expect(
      container.read(authTokenStoreProvider),
      same(container.read(authTokenStoreProvider)),
    );
    expect(container.read(authTokenStoreProvider), isA<AuthTokenStore>());
  });

  test('fecha o Dio quando o provider é descartado', () async {
    final container = containerForDev();
    final dio = container.read(dioProvider);

    container.dispose();

    await expectLater(dio.get<void>('/x'), throwsA(isA<DioException>()));
  });
}
