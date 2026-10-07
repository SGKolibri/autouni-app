import 'package:autouni_app/features/auth/domain/models/user.dart';
import 'package:autouni_app/features/auth/domain/models/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usuário completo, como o backend devolve em POST /auth/login
/// (`Omit<User, 'password'>` do Prisma).
const _fullJson = <String, dynamic>{
  'id': 'uuid-user-123',
  'email': 'joao@example.com',
  'name': 'João Silva',
  'phone': '62999990000',
  'cpf': '12345678900',
  'role': 'COORDINATOR',
  'avatar': 'https://cdn.example.com/joao.png',
  'createdAt': '2025-01-01T00:00:00.000Z',
  'updatedAt': '2025-02-03T04:05:06.000Z',
};

void main() {
  group('User.fromJson', () {
    test('lê todos os campos do usuário completo', () {
      final user = User.fromJson(_fullJson);

      expect(user.id, 'uuid-user-123');
      expect(user.email, 'joao@example.com');
      expect(user.name, 'João Silva');
      expect(user.phone, '62999990000');
      expect(user.cpf, '12345678900');
      expect(user.role, UserRole.coordinator);
      expect(user.avatar, 'https://cdn.example.com/joao.png');
      expect(user.createdAt, DateTime.utc(2025));
      expect(user.updatedAt, DateTime.utc(2025, 2, 3, 4, 5, 6));
    });

    test('aceita o usuário mínimo: opcionais ausentes ou nulos', () {
      final user = User.fromJson(const {
        'id': 'u1',
        'email': 'a@b.com',
        'name': 'Ana',
        'role': 'ADMIN',
        'phone': null,
        'cpf': null,
        'avatar': null,
      });

      expect(user.role, UserRole.admin);
      expect(user.phone, isNull);
      expect(user.cpf, isNull);
      expect(user.avatar, isNull);
      expect(user.createdAt, isNull);
      expect(user.updatedAt, isNull);
    });

    test('papel desconhecido vira VIEWER em vez de quebrar o login', () {
      final user = User.fromJson({..._fullJson, 'role': 'SUPERUSER'});

      expect(user.role, UserRole.viewer);
    });

    test('papel ausente vira VIEWER', () {
      final user = User.fromJson({..._fullJson}..remove('role'));

      expect(user.role, UserRole.viewer);
    });

    test(
      'ignora campos extras do backend (ex.: password vazado, relações)',
      () {
        final user = User.fromJson({
          ..._fullJson,
          'password': 'hash',
          'notifications': <dynamic>[],
        });

        expect(user.id, 'uuid-user-123');
        expect(user.toJson().containsKey('password'), isFalse);
      },
    );

    test('falha quando falta um campo obrigatório', () {
      expect(
        () => User.fromJson({..._fullJson}..remove('email')),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('User.toJson', () {
    test('faz o round-trip sem perder nada', () {
      final user = User.fromJson(_fullJson);

      expect(user.toJson(), _fullJson);
      expect(User.fromJson(user.toJson()), user);
    });

    test('serializa o papel no formato do backend', () {
      expect(User.fromJson(_fullJson).toJson()['role'], 'COORDINATOR');
    });
  });

  group('User valor', () {
    test('igualdade por valor', () {
      expect(User.fromJson(_fullJson), User.fromJson(_fullJson));
      expect(
        User.fromJson(_fullJson).hashCode,
        User.fromJson(_fullJson).hashCode,
      );
    });

    test('copyWith troca só o campo pedido', () {
      final user = User.fromJson(_fullJson);
      final renamed = user.copyWith(name: 'João S.');

      expect(renamed.name, 'João S.');
      expect(renamed.email, user.email);
      expect(renamed, isNot(user));
    });
  });
}
