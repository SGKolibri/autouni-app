import 'package:autouni_app/features/auth/domain/validators/profile_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('nome', () {
    expect(validateName('Ana Souza'), isNull);
    expect(validateName('  '), 'Informe seu nome.');
    expect(validateName('Al'), contains('pelo menos 3'));
    expect(validateName('a' * 81), contains('até 80'));
  });

  group('telefone', () {
    for (final ok in [
      null,
      '',
      '(62) 99999-0000',
      '6233334444',
      '+55 62 99999-0000',
    ]) {
      test('aceita "$ok"', () => expect(validatePhone(ok), isNull));
    }
    for (final bad in ['99999-0000', '123', '(62) 9999-00000-1']) {
      test('recusa "$bad"', () => expect(validatePhone(bad), isNotNull));
    }

    test('normaliza para dígitos', () {
      expect(normalizePhone('+55 (62) 99999-0000'), '5562999990000');
      expect(normalizePhone('  '), isNull);
    });
  });

  group('nova senha', () {
    test('aceita letras e números com 8+', () {
      expect(validateNewPassword('novaSenha1'), isNull);
    });

    test('regras', () {
      expect(validateNewPassword(''), 'Informe a nova senha.');
      expect(validateNewPassword('abc12'), contains('pelo menos 8'));
      expect(
        validateNewPassword('somenteletras'),
        contains('letras e números'),
      );
      expect(validateNewPassword('12345678'), contains('letras e números'));
      expect(
        validateNewPassword('igual1234', current: 'igual1234'),
        contains('diferente da atual'),
      );
    });

    test('confirmação', () {
      expect(validatePasswordConfirmation('a1b2c3d4', 'a1b2c3d4'), isNull);
      expect(validatePasswordConfirmation('x', 'a1b2c3d4'), isNotNull);
    });
  });
}
