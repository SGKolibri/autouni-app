/// Validações de perfil e troca de senha. Devolvem a mensagem de erro, ou
/// `null` quando o valor é válido.
library;

const int minNameLength = 3;
const int maxNameLength = 80;

/// Senha nova: mais forte que o mínimo do login (6), já que é o app que
/// escolhe agora.
const int minNewPasswordLength = 8;

String? validateName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Informe seu nome.';
  if (name.length < minNameLength) {
    return 'O nome precisa ter pelo menos $minNameLength letras.';
  }
  if (name.length > maxNameLength) {
    return 'O nome vai até $maxNameLength caracteres.';
  }
  return null;
}

/// Telefone opcional; com DDD (10 ou 11 dígitos, aceita "+55" e máscara).
String? validatePhone(String? value) {
  final digits = normalizePhone(value);
  if (digits == null) return null;
  final local = digits.startsWith('55') && digits.length > 11
      ? digits.substring(2)
      : digits;
  if (local.length < 10 || local.length > 11) {
    return 'Telefone com DDD: 10 ou 11 dígitos.';
  }
  return null;
}

/// Só os dígitos do telefone, ou `null` se vazio.
String? normalizePhone(String? value) {
  final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
  return digits.isEmpty ? null : digits;
}

String? validateNewPassword(String? value, {String? current}) {
  final password = value ?? '';
  if (password.isEmpty) return 'Informe a nova senha.';
  if (password.length < minNewPasswordLength) {
    return 'A nova senha precisa ter pelo menos $minNewPasswordLength '
        'caracteres.';
  }
  if (!RegExp('[A-Za-z]').hasMatch(password) ||
      !RegExp(r'\d').hasMatch(password)) {
    return 'Use letras e números na nova senha.';
  }
  if (current != null && password == current) {
    return 'A nova senha precisa ser diferente da atual.';
  }
  return null;
}

String? validatePasswordConfirmation(String? value, String password) =>
    value == password ? null : 'As senhas não conferem.';
