import '../models/user_role.dart';

/// Ações sensíveis do app, controladas por papel (RBAC).
///
/// O backend ainda não aplica papéis nas rotas: este é o único ponto que
/// decide o que cada papel pode fazer na UI.
enum AppPermission {
  /// Ligar/desligar e ajustar (dimmer, termostato) um dispositivo.
  controlDevices,

  /// "Desligar todos" de uma sala.
  bulkControlDevices,

  /// Criar, editar, excluir e executar automações.
  manageAutomations,

  /// Gerar relatórios.
  generateReports,
}

extension UserRolePermissions on UserRole {
  /// O papel pode executar [permission]? VIEWER é somente leitura; os demais
  /// papéis têm, por enquanto, as mesmas permissões no app.
  bool can(AppPermission permission) => switch (this) {
    UserRole.viewer => false,
    UserRole.admin ||
    UserRole.coordinator ||
    UserRole.technician => _granted.contains(permission),
  };

  static const Set<AppPermission> _granted = {...AppPermission.values};
}
