import 'package:autouni_app/core/config/app_config.dart';
import 'package:autouni_app/core/config/app_config_provider.dart';
import 'package:autouni_app/core/config/flavor.dart';
import 'package:autouni_app/features/auth/data/auth_data_providers.dart';
import 'package:autouni_app/features/auth/data/repositories/http_auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('authRepositoryProvider entrega o repositório HTTP', () {
    final container = ProviderContainer.test(
      overrides: [
        appConfigProvider.overrideWithValue(AppConfig.forFlavor(Flavor.prod)),
      ],
    );

    final repository = container.read(authRepositoryProvider);

    expect(repository, isA<HttpAuthRepository>());
    expect(container.read(authRepositoryProvider), same(repository));
  });
}
