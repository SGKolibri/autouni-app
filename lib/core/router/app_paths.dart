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
}
