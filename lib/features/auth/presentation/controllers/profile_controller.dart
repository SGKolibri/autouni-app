import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/repositories/profile_repository.dart';
import '../../domain/models/user.dart';
import '../../domain/validators/profile_validators.dart';
import 'auth_controller.dart';

/// Perfil completo do usuário logado. Sem rede, cai no usuário da sessão.
final profileProvider = FutureProvider.autoDispose<User?>((ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return null;
  try {
    return await ref.watch(profileRepositoryProvider).fetch(user.id);
  } on ApiException {
    return user;
  }
}, name: 'profileProvider');

/// Editar perfil e trocar senha. Devolvem a mensagem de erro, ou `null` em
/// sucesso.
class ProfileController {
  ProfileController(this._ref);

  final Ref _ref;

  ProfileRepository get _repository => _ref.read(profileRepositoryProvider);
  User? get _user => _ref.read(authControllerProvider).value;

  Future<String?> save({required String name, String? phone}) async {
    final user = _user;
    if (user == null) return 'Sessão expirada. Entre novamente.';
    final invalid = validateName(name) ?? validatePhone(phone);
    if (invalid != null) return invalid;
    try {
      final saved = await _repository.update(
        user.id,
        name: name,
        phone: normalizePhone(phone),
      );
      // O PUT devolve o usuário inteiro; mantém o papel da sessão se não vier.
      _ref
          .read(authControllerProvider.notifier)
          .updateUser(saved.copyWith(role: user.role));
      _ref.invalidate(profileProvider);
      return null;
    } on ApiException catch (error) {
      return error.message;
    }
  }

  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _user;
    if (user == null) return 'Sessão expirada. Entre novamente.';
    final invalid = validateNewPassword(newPassword, current: currentPassword);
    if (invalid != null) return invalid;
    try {
      await _repository.changePassword(
        userId: user.id,
        email: user.email,
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return null;
    } on WrongCurrentPasswordException {
      return 'Senha atual incorreta.';
    } on ApiException catch (error) {
      return error.message;
    }
  }
}

final profileControllerProvider = Provider<ProfileController>(
  ProfileController.new,
  name: 'profileControllerProvider',
);
