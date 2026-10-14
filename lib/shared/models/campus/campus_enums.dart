import 'package:json_annotation/json_annotation.dart';

/// Tipo de dispositivo (`DeviceType` do backend).
@JsonEnum(valueField: 'apiValue')
enum DeviceType {
  light('LIGHT', 'Iluminação'),
  ac('AC', 'Ar-condicionado'),
  projector('PROJECTOR', 'Projetor'),
  speaker('SPEAKER', 'Som'),
  lock('LOCK', 'Fechadura'),
  sensor('SENSOR', 'Sensor'),
  other('OTHER', 'Outro');

  const DeviceType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// Valor desconhecido cai em [other].
  static DeviceType fromApi(Object? value) =>
      values.firstWhere((type) => type.apiValue == value, orElse: () => other);
}

/// Estado lógico do aparelho (`DeviceStatus` do backend). Independente de
/// estar online: um dispositivo pode estar ligado e inalcançável.
@JsonEnum(valueField: 'apiValue')
enum DeviceStatus {
  on('ON', 'Ligado'),
  off('OFF', 'Desligado'),
  standby('STANDBY', 'Em espera'),
  error('ERROR', 'Erro');

  const DeviceStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// Valor desconhecido cai em [off]: na dúvida, não mostra como ligado.
  static DeviceStatus fromApi(Object? value) => values.firstWhere(
    (status) => status.apiValue == value,
    orElse: () => off,
  );
}

/// Tipo de sala (`RoomType` do backend).
@JsonEnum(valueField: 'apiValue')
enum RoomType {
  classroom('CLASSROOM', 'Sala de aula'),
  lab('LAB', 'Laboratório'),
  office('OFFICE', 'Escritório'),
  auditorium('AUDITORIUM', 'Auditório'),
  library('LIBRARY', 'Biblioteca'),
  other('OTHER', 'Outro');

  const RoomType(this.apiValue, this.label);

  final String apiValue;
  final String label;
}
