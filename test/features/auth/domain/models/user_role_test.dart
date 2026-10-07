import 'package:autouni_app/features/auth/domain/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole', () {
    test('espelha os 4 papéis do backend (enum UserRole do Prisma)', () {
      expect(UserRole.values.map((r) => r.apiValue), [
        'ADMIN',
        'COORDINATOR',
        'TECHNICIAN',
        'VIEWER',
      ]);
    });

    test('fromApi resolve cada valor do backend', () {
      expect(UserRole.fromApi('ADMIN'), UserRole.admin);
      expect(UserRole.fromApi('COORDINATOR'), UserRole.coordinator);
      expect(UserRole.fromApi('TECHNICIAN'), UserRole.technician);
      expect(UserRole.fromApi('VIEWER'), UserRole.viewer);
    });

    test('papel desconhecido ou ausente cai no de menor privilégio', () {
      expect(UserRole.fromApi('SUPERUSER'), UserRole.viewer);
      expect(UserRole.fromApi(''), UserRole.viewer);
      expect(UserRole.fromApi(null), UserRole.viewer);
    });

    test('fromApi é sensível a maiúsculas, como o backend', () {
      expect(UserRole.fromApi('admin'), UserRole.viewer);
    });
  });
}
