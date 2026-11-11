import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/features/auth/data/auth_data_providers.dart';
import 'package:autouni_app/features/auth/data/repositories/profile_repository.dart';
import 'package:autouni_app/features/auth/domain/models/user.dart';
import 'package:autouni_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:autouni_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:autouni_app/features/auth/presentation/controllers/profile_controller.dart';
import 'package:autouni_app/shared/models/user_role.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockProfile extends Mock implements ProfileRepository {}

const _user = User(
  id: 'u1',
  email: 'ana@uni.br',
  name: 'Ana',
  role: UserRole.technician,
);

void main() {
  late _MockAuth auth;
  late _MockProfile profile;
  late ProviderContainer container;

  setUp(() async {
    auth = _MockAuth();
    profile = _MockProfile();
    when(() => auth.restoreSession()).thenAnswer((_) async => _user);
    container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        profileRepositoryProvider.overrideWithValue(profile),
      ],
    );
    await container.read(authControllerProvider.future);
  });

  ProfileController controller() => container.read(profileControllerProvider);

  group('perfil', () {
    test('carrega o perfil completo; sem rede usa o da sessão', () async {
      when(() => profile.fetch('u1'))
          .thenAnswer((_) async => _user.copyWith(phone: '62999990000'));
      expect(
        (await container.read(profileProvider.future))?.phone,
        '62999990000',
      );

      when(() => profile.fetch('u1')).thenThrow(const NetworkException());
      container.invalidate(profileProvider);
      expect(await container.read(profileProvider.future), _user);
    });

    test('salvar atualiza a sessão (mantendo o papel)', () async {
      when(
        () => profile.update(
          'u1',
          name: any(named: 'name'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer(
        (_) async => _user.copyWith(name: 'Ana Souza', role: UserRole.viewer),
      );

      final error = await controller().save(
        name: 'Ana Souza',
        phone: '(62) 99999-0000',
      );

      expect(error, isNull);
      verify(
        () => profile.update('u1', name: 'Ana Souza', phone: '62999990000'),
      ).called(1);
      final session = container.read(authControllerProvider).value!;
      expect(session.name, 'Ana Souza');
      expect(session.role, UserRole.technician);
    });

    test('dados inválidos não vão ao backend', () async {
      expect(await controller().save(name: 'A'), contains('pelo menos 3'));
      expect(
        await controller().save(name: 'Ana', phone: '123'),
        contains('DDD'),
      );
      verifyNever(
        () => profile.update(
          any(),
          name: any(named: 'name'),
          phone: any(named: 'phone'),
        ),
      );
    });

    test('erro do backend volta como mensagem', () async {
      when(
        () => profile.update(
          any(),
          name: any(named: 'name'),
          phone: any(named: 'phone'),
        ),
      ).thenThrow(const ServerException(message: 'Erro no servidor.'));

      expect(await controller().save(name: 'Ana'), 'Erro no servidor.');
      expect(container.read(authControllerProvider).value, _user);
    });
  });

  group('trocar senha', () {
    When<Future<void>> whenChange() => when(
      () => profile.changePassword(
        userId: any(named: 'userId'),
        email: any(named: 'email'),
        currentPassword: any(named: 'currentPassword'),
        newPassword: any(named: 'newPassword'),
      ),
    );

    test('usa o e-mail da sessão', () async {
      whenChange().thenAnswer((_) async {});

      final error = await controller().changePassword(
        currentPassword: 'antiga123',
        newPassword: 'novaSenha1',
      );

      expect(error, isNull);
      verify(
        () => profile.changePassword(
          userId: 'u1',
          email: 'ana@uni.br',
          currentPassword: 'antiga123',
          newPassword: 'novaSenha1',
        ),
      ).called(1);
    });

    test('senha atual errada', () async {
      whenChange().thenThrow(const WrongCurrentPasswordException());

      expect(
        await controller().changePassword(
          currentPassword: 'errada',
          newPassword: 'novaSenha1',
        ),
        'Senha atual incorreta.',
      );
    });

    test('senha nova fraca não vai ao backend', () async {
      expect(
        await controller().changePassword(
          currentPassword: 'antiga123',
          newPassword: 'curta',
        ),
        contains('pelo menos 8'),
      );
    });
  });
}
