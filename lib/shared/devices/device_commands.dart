import '../models/campus/campus_models.dart';

/// Comando de `POST /devices/:id/control` e `/devices/bulk-control`.
enum DeviceCommand {
  on('on'),
  off('off'),
  toggle('toggle');

  const DeviceCommand(this.apiValue);

  final String apiValue;
}

/// Resposta de `POST /devices/:id/control`: o dispositivo gravado e se o
/// comando saiu para o broker e aguarda o hardware confirmar ([pending]).
class ControlResult {
  const ControlResult({required this.device, required this.pending});

  final Device device;
  final bool pending;
}

/// Resposta de `POST /devices/bulk-control`. Uma falha individual não
/// aborta o lote.
class BulkControlResult {
  const BulkControlResult({
    required this.successCount,
    required this.failedCount,
    required this.failedDevices,
  });

  factory BulkControlResult.fromJson(Map<String, dynamic> json) =>
      BulkControlResult(
        successCount: (json['successCount'] as num).toInt(),
        failedCount: (json['failedCount'] as num).toInt(),
        failedDevices: [
          for (final id in json['failedDevices'] as List) id as String,
        ],
      );

  final int successCount;
  final int failedCount;
  final List<String> failedDevices;
}
