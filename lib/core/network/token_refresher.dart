import 'package:dio/dio.dart';

import 'auth_token_store.dart';

export 'auth_token_store.dart' show TokenPair;

/// Troca um refresh token por um novo [TokenPair]. Abstraído para que o
/// [RefreshInterceptor] não conheça o endpoint nem o `dio` usado na renovação.
abstract interface class TokenRefresher {
  /// Devolve o novo par de tokens, ou `null` se a renovação foi recusada
  /// (refresh token inválido/expirado) — sinal para encerrar a sessão.
  Future<TokenPair?> refresh(String refreshToken);
}

/// Implementação HTTP: `POST /auth/refresh` com um `dio` sem os interceptors
/// da aplicação (senão um 401 aqui dispararia refresh recursivo).
class HttpTokenRefresher implements TokenRefresher {
  HttpTokenRefresher(this._dio, {this.path = '/auth/refresh'});

  final Dio _dio;
  final String path;

  @override
  Future<TokenPair?> refresh(String refreshToken) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        path,
        data: {'refreshToken': refreshToken},
      );
      final data = response.data;
      if (data == null) return null;
      return TokenPair.fromJson(data);
    } on DioException {
      return null;
    } on FormatException {
      return null;
    }
  }
}
