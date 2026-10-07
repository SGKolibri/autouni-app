import 'dart:convert';

/// JWT de teste (sem assinatura válida) com o [payload] dado, no mesmo
/// formato que o backend emite: base64url sem padding.
String fakeJwt(Map<String, dynamic> payload) {
  String segment(Object value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  return '${segment({'alg': 'HS256', 'typ': 'JWT'})}.${segment(payload)}.sig';
}

/// `exp`/`iat` de JWT: segundos desde a época.
int jwtSeconds(DateTime instant) => instant.millisecondsSinceEpoch ~/ 1000;
