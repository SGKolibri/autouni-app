import 'package:freezed_annotation/freezed_annotation.dart';

import 'user_role.dart';

part 'user.freezed.dart';
part 'user.g.dart';

/// Usuário autenticado, como devolvido em `POST /auth/login` (o `User` do
/// backend sem `password`).
@freezed
abstract class User with _$User {
  const factory User({
    required String id,
    required String email,
    required String name,
    @JsonKey(unknownEnumValue: UserRole.viewer)
    @Default(UserRole.viewer)
    UserRole role,
    String? phone,
    String? cpf,
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
