import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/app_config_provider.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:autouni_app/core/realtime/realtime_client.dart';
import 'package:autouni_app/core/realtime/realtime_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProviderContainer containerForDev() => ProviderContainer.test(
    overrides: [
      appConfigProvider.overrideWithValue(AppConfig.forFlavor(Flavor.dev)),
    ],
  );

  test('realtimeClientProvider entrega um RealtimeClient', () {
    final container = containerForDev();

    expect(container.read(realtimeClientProvider), isA<RealtimeClient>());
  });

  test('é um singleton dentro do container', () {
    final container = containerForDev();

    expect(
      container.read(realtimeClientProvider),
      same(container.read(realtimeClientProvider)),
    );
  });

  test('realtimeStatusProvider começa em idle', () {
    final container = containerForDev();

    expect(
      container.read(realtimeStatusProvider),
      RealtimeConnectionStatus.idle,
    );
  });
}
