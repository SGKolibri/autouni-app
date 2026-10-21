/// Validações do formulário de automação (funções puras, usadas como
/// `validator` dos campos).
library;

import 'dart:convert';

String? validateAutomationName(String? value) {
  final name = value?.trim() ?? '';
  if (name.isEmpty) return 'Informe um nome.';
  if (name.length < 3) return 'Use pelo menos 3 caracteres.';
  if (name.length > 80) return 'Use no máximo 80 caracteres.';
  return null;
}

/// Tópico para publicar: sem espaços e sem os curingas de assinatura.
String? validateTopic(String? value) {
  final topic = value?.trim() ?? '';
  if (topic.isEmpty) return 'Informe o tópico MQTT.';
  if (topic.contains(RegExp(r'\s'))) return 'O tópico não pode ter espaços.';
  if (topic.contains('+') || topic.contains('#')) {
    return 'Curingas (+ e #) não valem para publicar.';
  }
  return null;
}

/// Payload do modo avançado: vazio vale `{}`; senão um objeto JSON.
String? validatePayload(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) return null;
  final Object? decoded;
  try {
    decoded = jsonDecode(text);
  } on FormatException {
    return 'JSON inválido.';
  }
  return decoded is Map ? null : 'O payload deve ser um objeto JSON.';
}

/// Lê o payload já validado por [validatePayload].
Map<String, dynamic> parsePayload(String value) {
  final text = value.trim();
  if (text.isEmpty) return <String, dynamic>{};
  return Map<String, dynamic>.from(jsonDecode(text) as Map);
}
