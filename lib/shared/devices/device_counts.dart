import '../models/campus/campus_models.dart';
import 'device_live_state.dart';

/// Contagem de dispositivos de um prédio/andar/sala já com o estado ao vivo,
/// para os cards se atualizarem pelo WebSocket sem recarregar.
class DeviceCounts {
  const DeviceCounts({this.total = 0, this.on = 0, this.online = 0});

  factory DeviceCounts.of(Iterable<Device> devices, LiveDevices live) {
    var total = 0;
    var on = 0;
    var online = 0;
    for (final device in live.applyAll(devices)) {
      total++;
      if (device.isOn) on++;
      if (device.online) online++;
    }
    return DeviceCounts(total: total, on: on, online: online);
  }

  final int total;
  final int on;
  final int online;

  int get offline => total - online;
}

extension CampusDevices on Building {
  Iterable<Device> get allDevices => floors.expand((floor) => floor.allDevices);
}

extension FloorDevices on Floor {
  Iterable<Device> get allDevices => rooms.expand((room) => room.devices);
}
