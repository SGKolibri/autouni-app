import 'package:dio/dio.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/network/auth_token_store.dart';
import '../../../../core/network/interceptors/auth_interceptor.dart';
import '../../domain/models/auth_tokens.dart';
import '../../domain/models/user.dart';
import '../../domain/models/user_role.dart';
import '../../domain/repositories/auth_repository.dart';
import '../session/jwt_payload.dart';

/// Implementação HTTP do [AuthRepository] sobre o `Dio` da aplicação.
///
/// O backend não expõe `GET /auth/me`: o usuário autenticado vem na própria
/// resposta de `POST /auth/login` (`{ user, accessToken, refreshToken }`).
class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository({
    required this._dio,
    required this._tokenStore,
    this.loginPath = '/auth/login',
    this._now = DateTime.now,
  });

  final Dio _dio;
  final AuthTokenStore _tokenStore;
  final String loginPath;
  final DateTime Function() _now;

  @override
  Future<User> login({required String email, required String password}) async {
    final Response<dynamic> response;
    try {
      response = await _dio.post<dynamic>(
        loginPath,
        data: {'email': email.trim(), 'password': password},
        // Rota pública: sem Bearer e sem refresh automático no 401.
        options: Options(extra: AuthInterceptor.skipAuth),
      );
    } on DioException catch (error) {
      final translated = error.error;
      throw translated is ApiException
          ? translated
          : ApiException.fromDioException(error);
    }

    final (user, tokens) = _parse(response);
    await _tokenStore.saveTokens(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
    );
    return user;
  }

  /// Como não existe `GET /auth/me`, o usuário é reconstruído das claims do
  /// JWT guardado (`sub`, `email`, `name`, `role`). A sessão vale enquanto o
  /// refresh token não expirar; um access token vencido é renovado pelo
  /// `RefreshInterceptor` na primeira request.
  @override
  Future<User?> restoreSession() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final refreshClaims = decodeJwtPayload(refreshToken);
    if (refreshClaims != null && !_isExpired(refreshClaims)) {
      final accessToken = await _tokenStore.readAccessToken();
      final accessClaims = accessToken == null
          ? null
          : decodeJwtPayload(accessToken);
      final user =
          _userFromClaims(accessClaims) ?? _userFromClaims(refreshClaims);
      if (user != null) return user;
    }

    await _tokenStore.clear();
    return null;
  }

  bool _isExpired(Map<String, dynamic> claims) {
    final exp = claims['exp'];
    if (exp is! num) return false;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      (exp * 1000).toInt(),
      isUtc: true,
    );
    return !expiresAt.isAfter(_now());
  }

  User? _userFromClaims(Map<String, dynamic>? claims) {
    if (claims == null) return null;
    final id = claims['sub'];
    final email = claims['email'];
    final name = claims['name'];
    final role = claims['role'];
    if (id is! String || email is! String || name is! String) return null;
    return User(
      id: id,
      email: email,
      name: name,
      role: UserRole.fromApi(role is String ? role : null),
    );
  }

  /// Lê `{ user, accessToken, refreshToken }`; qualquer formato diferente
  /// disso vira [UnexpectedResponseException] em vez de erro de cast.
  (User, AuthTokens) _parse(Response<dynamic> response) {
    final body = response.data;
    try {
      if (body is Map<String, dynamic>) {
        final user = body['user'];
        if (user is Map<String, dynamic>) {
          return (User.fromJson(user), AuthTokens.fromJson(body));
        }
      }
    } on TypeError {
      // Campo obrigatório ausente ou com tipo errado: cai no erro abaixo.
    } on FormatException {
      // Data em formato inválido: idem.
    }
    throw UnexpectedResponseException(
      message: 'Resposta de login inválida.',
      statusCode: response.statusCode,
    );
  }
}
