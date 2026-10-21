import 'package:autouni_app/features/auth/domain/validators/credential_validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('validateEmail', () {
    test('aceita e-mail válido, mesmo com espaços nas pontas', () {
      expect(validateEmail('ana@uni.edu.br'), isNull);
      expect(validateEmail('  ana@uni.edu.br '), isNull);
    });

    for (final value in [null, '', '   ']) {
      test('exige o e-mail ("$value")', () {
        expect(validateEmail(value), 'Informe seu e-mail.');
      });
    }

    for (final value in ['ana', 'ana@', 'ana@uni', '@uni.br', 'a na@uni.br']) {
      test('recusa "$value"', () {
        expect(validateEmail(value), 'E-mail inválido.');
      });
    }
  });

  group('validatePassword', () {
    test('exige a senha', () {
      expect(validatePassword(null), 'Informe sua senha.');
      expect(validatePassword(''), 'Informe sua senha.');
    });

    test('exige o mínimo do backend', () {
      expect(validatePassword('12345'), isNotNull);
      expect(validatePassword('123456'), isNull);
    });
  });
}
