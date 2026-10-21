import 'package:dio/dio.dart';

import '../auth_token_store.dart';

/// Injeta `Authorization: Bearer <access token>` nas requests autenticadas.
///
/// Pule a injeção em rotas públicas (login, refresh, forgot-password) passando
/// [AuthInterceptor.skipAuth] em `Options.extra`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStore);

  final AuthTokenStore _tokenStore;

  static const String _skipAuthKey = 'autouni.network.skipAuth';

  /// Marcador para `Options(extra: AuthInterceptor.skipAuth)`.
  static const Map<String, dynamic> skipAuth = {_skipAuthKey: true};

  /// Uma request está marcada como pública?
  static bool isSkipAuth(RequestOptions options) =>
      options.extra[_skipAuthKey] == true;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final alreadySet = options.headers.containsKey('Authorization');
    if (isSkipAuth(options) || alreadySet) {
      handler.next(options);
      return;
    }

    final token = await _tokenStore.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
