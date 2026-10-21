import 'package:autouni_app/features/auth/data/session/jwt_payload.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/fake_jwt.dart';

void main() {
  group('decodeJwtPayload', () {
    test('lê as claims de um JWT (base64url sem padding, com acentos)', () {
      final token = fakeJwt({
        'sub': 'uuid-user-123',
        'email': 'joao@example.com',
        'name': 'João Silva',
        'role': 'ADMIN',
        'exp': 1767225600,
      });

      expect(decodeJwtPayload(token), {
        'sub': 'uuid-user-123',
        'email': 'joao@example.com',
        'name': 'João Silva',
        'role': 'ADMIN',
        'exp': 1767225600,
      });
    });

    for (final (description, token) in [
      ('vazio', ''),
      ('sem três partes', 'abc.def'),
      ('com payload que não é base64', 'abc.***.sig'),
      ('com payload que não é JSON', 'abc.bm90LWpzb24.sig'),
      ('com payload que não é objeto', 'abc.WzFd.sig'),
    ]) {
      test('devolve null para token $description', () {
        expect(decodeJwtPayload(token), isNull);
      });
    }
  });
}
