import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_tokens.freezed.dart';
part 'auth_tokens.g.dart';

/// Par de tokens JWT da sessão. Pode ser lido direto da resposta de
/// `POST /auth/login` (`{ accessToken, refreshToken, user }`).
@freezed
abstract class AuthTokens with _$AuthTokens {
  const AuthTokens._();

  const factory AuthTokens({
    required String accessToken,
    required String refreshToken,
  }) = _AuthTokens;

  factory AuthTokens.fromJson(Map<String, dynamic> json) =>
      _$AuthTokensFromJson(json);

  /// Aplica a resposta de `POST /auth/refresh`: sempre traz um novo
  /// `accessToken`; o `refreshToken` só é trocado se o backend o rotacionar.
  AuthTokens refreshedWith(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String? ?? refreshToken,
    );
  }

  /// Nunca expõe os tokens em logs ou relatórios de erro.
  @override
  String toString() => 'AuthTokens(accessToken: ***, refreshToken: ***)';
}
