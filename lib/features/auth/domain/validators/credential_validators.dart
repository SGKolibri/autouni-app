/// Validações dos formulários de autenticação, alinhadas ao `LoginDto` do
/// backend (e-mail válido, senha com pelo menos [minPasswordLength]).
/// Devolvem a mensagem de erro, ou `null` quando o valor é válido.
library;

const int minPasswordLength = 6;

final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Informe seu e-mail.';
  if (!_emailPattern.hasMatch(email)) return 'E-mail inválido.';
  return null;
}

String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Informe sua senha.';
  if (password.length < minPasswordLength) {
    return 'A senha tem pelo menos $minPasswordLength caracteres.';
  }
  return null;
}
