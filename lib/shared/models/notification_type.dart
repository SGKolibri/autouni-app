import 'package:json_annotation/json_annotation.dart';

/// Tipo de notificação (`NotificationType` do backend).
@JsonEnum(valueField: 'apiValue')
enum NotificationType {
  info('INFO', 'Informação'),
  warning('WARNING', 'Atenção'),
  error('ERROR', 'Erro'),
  success('SUCCESS', 'Sucesso');

  const NotificationType(this.apiValue, this.label);

  final String apiValue;
  final String label;
}
