import 'package:dio/dio.dart';

import 'auth_token_store.dart';

export 'auth_token_store.dart' show TokenPair;

/// Troca um refresh token por um novo [TokenPair]. Abstraído para que o
/// [RefreshInterceptor] não conheça o endpoint nem o `dio` usado na renovação.
abstract interface class TokenRefresher {
  /// Devolve o novo par de tokens, ou `null` se a renovação foi **recusada**
  /// (refresh token inválido/expirado) — sinal para encerrar a sessão.
  ///
  /// Falhas que não dizem nada sobre o token (sem rede, timeout, 5xx, 429)
  /// são propagadas como [DioException]: a sessão continua valendo.
  Future<TokenPair?> refresh(String refreshToken);
}

/// Implementação HTTP: `POST /auth/refresh` com um `dio` sem os interceptors
/// da aplicação (senão um 401 aqui dispararia refresh recursivo).
///
/// O backend devolve só `{ accessToken }` e não rotaciona o refresh token;
/// nesse caso o par devolvido mantém o [refresh] token em uso. Se um dia a
/// resposta trouxer `refreshToken`, ele passa a valer.
class HttpTokenRefresher implements TokenRefresher {
  HttpTokenRefresher(this._dio, {this.path = '/auth/refresh'});

  /// Status em que o backend está de fato recusando o refresh token.
  static const Set<int> _rejectedStatuses = {400, 401, 403};

  final Dio _dio;
  final String path;

  @override
  Future<TokenPair?> refresh(String refreshToken) async {
    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        path,
        data: {'refreshToken': refreshToken},
      );
    } on DioException catch (error) {
      if (_rejectedStatuses.contains(error.response?.statusCode)) return null;
      rethrow;
    }

    final data = response.data;
    if (data is! Map) return null;
    final access = data['accessToken'] ?? data['access_token'];
    if (access is! String || access.isEmpty) return null;
    final rotated = data['refreshToken'] ?? data['refresh_token'];
    return TokenPair(
      accessToken: access,
      refreshToken: rotated is String && rotated.isNotEmpty
          ? rotated
          : refreshToken,
    );
  }
}
