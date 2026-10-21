import 'app_tab.dart';

/// Caminhos das telas internas das abas. Ficam no core para qualquer feature
/// navegar (ex.: dashboard → prédio) sem importar a feature de destino.
///
/// A hierarquia é aninhada na URL — `/environments/buildings/b1/floors/f1/
/// rooms/r1` — para o go_router montar a pilha completa (voltar sobe um
/// nível por vez, inclusive vindo de deep link).
abstract final class AppPaths {
  static String building(String buildingId) =>
      '${AppTab.environments.path}/buildings/$buildingId';

  static String floor(String buildingId, String floorId) =>
      '${building(buildingId)}/floors/$floorId';

  static String room(String buildingId, String floorId, String roomId) =>
      '${floor(buildingId, floorId)}/rooms/$roomId';

  /// Lista global de dispositivos.
  static String get allDevices => '${AppTab.environments.path}/devices';

  /// Raiz da tela de consumo de energia — tela cheia, fora das abas, para
  /// abrir por cima de qualquer aba (dashboard, ambientes, ranking).
  static const String energyRoot = '/energy';

  /// Consumo de um escopo. [query] é o escopo serializado pela feature de
  /// energia (`level`, `id`, `name`); vazio = campus.
  static String energy([Map<String, String> query = const {}]) => Uri(
    path: energyRoot,
    queryParameters: query.isEmpty ? null : query,
  ).toString();

  /// Consumo de uma entidade da hierarquia ([level]: `building`, `floor`,
  /// `room` ou `device`), para telas que não conhecem a feature de energia.
  static String energyOf({
    required String level,
    required String id,
    required String name,
  }) => energy({'level': level, 'id': id, 'name': name});

  /// Nova automação.
  static String get newAutomation => '${AppTab.automations.path}/new';

  /// Detalhe (histórico e ações) de uma automação.
  static String automation(String automationId) =>
      '${AppTab.automations.path}/$automationId';

  /// Edição de uma automação.
  static String editAutomation(String automationId) =>
      '${automation(automationId)}/edit';
}
