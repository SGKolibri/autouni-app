import '../models/user.dart';

/// Contrato de autenticação consumido pela camada de apresentação.
///
/// As falhas chegam como `ApiException` (camada core), nunca como erro cru
/// do cliente HTTP.
abstract interface class AuthRepository {
  /// Autentica com e-mail e senha, guarda os tokens da sessão e devolve o
  /// usuário autenticado.
  Future<User> login({required String email, required String password});
}
