import 'package:json_annotation/json_annotation.dart';

/// Papéis de usuário, espelhando o enum `UserRole` do backend.
@JsonEnum(valueField: 'apiValue')
enum UserRole {
  admin('ADMIN'),
  coordinator('COORDINATOR'),
  technician('TECHNICIAN'),
  viewer('VIEWER');

  const UserRole(this.apiValue);

  /// Valor trafegado na API e no payload do JWT.
  final String apiValue;

  /// Papel desconhecido ou ausente cai em [viewer]: na dúvida, o app libera
  /// o mínimo (somente leitura) em vez de quebrar ou conceder demais.
  static UserRole fromApi(String? value) {
    for (final role in values) {
      if (role.apiValue == value) return role;
    }
    return viewer;
  }
}
