import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/network_providers.dart';
import '../domain/repositories/auth_repository.dart';
import 'repositories/http_auth_repository.dart';

/// Repositório de autenticação (`POST /auth/login`).
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => HttpAuthRepository(
    dio: ref.watch(dioProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
  ),
  name: 'authRepositoryProvider',
);
