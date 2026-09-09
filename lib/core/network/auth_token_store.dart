/// Par de tokens JWT devolvido pelo backend em login e refresh.
class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  /// Aceita tanto `accessToken`/`refreshToken` quanto `access_token`/`refresh_token`.
  factory TokenPair.fromJson(Map<String, dynamic> json) {
    final access = json['accessToken'] ?? json['access_token'];
    final refresh = json['refreshToken'] ?? json['refresh_token'];
    if (access is! String || refresh is! String) {
      throw const FormatException(
        'resposta de tokens sem accessToken/refreshToken',
      );
    }
    return TokenPair(accessToken: access, refreshToken: refresh);
  }

  final String accessToken;
  final String refreshToken;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenPair &&
          accessToken == other.accessToken &&
          refreshToken == other.refreshToken;

  @override
  int get hashCode => Object.hash(accessToken, refreshToken);

  @override
  String toString() =>
      'TokenPair(access: ${_mask(accessToken)}, '
      'refresh: ${_mask(refreshToken)})';

  static String _mask(String token) => token.length <= 6
      ? '***'
      : '${token.substring(0, 3)}…${token.substring(token.length - 3)}';
}

/// Guarda os tokens de sessão. A implementação de produção (armazenamento
/// seguro, S2-T3) substitui [InMemoryAuthTokenStore] via override do provider.
abstract interface class AuthTokenStore {
  Future<String?> readAccessToken();
  Future<String?> readRefreshToken();
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });
  Future<void> clear();
}

/// Implementação volátil, usada em testes e como default até a S2-T3.
class InMemoryAuthTokenStore implements AuthTokenStore {
  InMemoryAuthTokenStore({this._accessToken, this._refreshToken});

  String? _accessToken;
  String? _refreshToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
