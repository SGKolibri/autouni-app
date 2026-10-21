import 'package:autouni_app/features/automations/domain/automation_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nome: obrigatório, 3 a 80 caracteres', () {
    expect(validateAutomationName(null), 'Informe um nome.');
    expect(validateAutomationName('   '), 'Informe um nome.');
    expect(validateAutomationName('ab'), 'Use pelo menos 3 caracteres.');
    expect(validateAutomationName('a' * 81), 'Use no máximo 80 caracteres.');
    expect(validateAutomationName(' Luzes '), isNull);
  });

  test('tópico MQTT: obrigatório, sem espaços nem curingas', () {
    expect(validateTopic(''), 'Informe o tópico MQTT.');
    expect(validateTopic('a b'), 'O tópico não pode ter espaços.');
    expect(validateTopic('a/+/b'), 'Curingas (+ e #) não valem para publicar.');
    expect(validateTopic('a/#'), 'Curingas (+ e #) não valem para publicar.');
    expect(validateTopic('bloco-a/lum-1/command'), isNull);
  });

  test('payload: vazio vale {}; senão um objeto JSON', () {
    expect(validatePayload(''), isNull);
    expect(validatePayload('{"state":"OFF"}'), isNull);
    expect(validatePayload('{state:OFF}'), 'JSON inválido.');
    expect(validatePayload('[1,2]'), 'O payload deve ser um objeto JSON.');
    expect(parsePayload(''), <String, dynamic>{});
    expect(parsePayload(' {"a": 1} '), {'a': 1});
  });
}
