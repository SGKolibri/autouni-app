import 'package:json_annotation/json_annotation.dart';

/// Papéis de usuário, espelhando o enum `UserRole` do backend.
@JsonEnum(valueField: 'apiValue')
enum UserRole {
  admin('ADMIN', 'Administrador'),
  coordinator('COORDINATOR', 'Coordenador'),
  technician('TECHNICIAN', 'Técnico'),
  viewer('VIEWER', 'Visualizador');

  const UserRole(this.apiValue, this.label);

  /// Valor trafegado na API e no payload do JWT.
  final String apiValue;

  /// Nome do papel exibido ao usuário.
  final String label;

  /// Papel desconhecido ou ausente cai em [viewer]: na dúvida, o app libera
  /// o mínimo (somente leitura) em vez de quebrar ou conceder demais.
  static UserRole fromApi(String? value) {
    for (final role in values) {
      if (role.apiValue == value) return role;
    }
    return viewer;
  }
}
