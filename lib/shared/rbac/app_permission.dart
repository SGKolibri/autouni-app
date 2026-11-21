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

  /// Alterar a configuração de alarmes da organização (intervalo do
  /// lembrete). Mesma regra do backend: só ADMIN e COORDINATOR.
  manageAlarmSettings,
}

extension UserRolePermissions on UserRole {
  /// O papel pode executar [permission]? VIEWER é somente leitura; TECHNICIAN
  /// opera tudo menos a configuração de alarmes da organização.
  bool can(AppPermission permission) => switch (this) {
    UserRole.viewer => false,
    UserRole.admin || UserRole.coordinator => true,
    UserRole.technician => permission != AppPermission.manageAlarmSettings,
  };
}
