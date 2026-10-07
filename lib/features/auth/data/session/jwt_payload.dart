import 'dart:convert';

/// Lê as claims (payload) de um JWT **sem validar a assinatura** — quem
/// valida é o backend a cada request. Serve só para o app saber de quem é a
/// sessão guardada e quando ela expira.
///
/// Devolve `null` se [token] não for um JWT legível.
Map<String, dynamic>? decodeJwtPayload(String token) {
  final parts = token.split('.');
  if (parts.length != 3) return null;
  try {
    final json = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final payload = jsonDecode(json);
    return payload is Map<String, dynamic> ? payload : null;
  } on FormatException {
    return null;
  }
}
