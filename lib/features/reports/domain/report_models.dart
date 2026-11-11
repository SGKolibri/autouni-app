import 'package:freezed_annotation/freezed_annotation.dart';

part 'report_models.freezed.dart';
part 'report_models.g.dart';

/// Tipo de relatório (`ReportType` do backend).
@JsonEnum(valueField: 'apiValue')
enum ReportType {
  energyConsumption(
    'ENERGY_CONSUMPTION',
    'Consumo de energia',
    'Leituras de energia por dispositivo no período.',
    usesPeriod: true,
  ),
  deviceStatus(
    'DEVICE_STATUS',
    'Status dos dispositivos',
    'Retrato atual: status e última conexão de cada dispositivo.',
  ),
  roomUsage(
    'ROOM_USAGE',
    'Uso das salas',
    'Retrato atual: dispositivos ativos, inativos e com erro por sala.',
  ),
  incidents(
    'INCIDENTS',
    'Incidentes',
    'Alertas de erro/atenção e dispositivos com falha no período.',
    usesPeriod: true,
  );

  const ReportType(
    this.apiValue,
    this.label,
    this.description, {
    this.usesPeriod = false,
  });

  final String apiValue;
  final String label;
  final String description;

  /// O backend filtra por `startDate`/`endDate` só nestes tipos; os outros
  /// são um retrato do momento da geração.
  final bool usesPeriod;
}

/// Formato do arquivo (`ReportFormat` do backend).
@JsonEnum(valueField: 'apiValue')
enum ReportFormat {
  pdf('PDF', 'pdf', 'application/pdf'),
  csv('CSV', 'csv', 'text/csv'),
  xlsx(
    'XLSX',
    'xlsx',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );

  const ReportFormat(this.apiValue, this.extension, this.mimeType);

  final String apiValue;
  final String extension;
  final String mimeType;

  String get label => apiValue;
}

/// Andamento da geração (`ReportStatus` do backend).
@JsonEnum(valueField: 'apiValue')
enum ReportStatus {
  pending('PENDING', 'Na fila'),
  processing('PROCESSING', 'Gerando'),
  completed('COMPLETED', 'Pronto'),
  failed('FAILED', 'Falhou');

  const ReportStatus(this.apiValue, this.label);

  final String apiValue;
  final String label;

  /// A geração ainda não terminou: vale acompanhar.
  bool get inProgress => this == pending || this == processing;
}

/// Relatório (`GET /reports/...`).
@freezed
abstract class Report with _$Report {
  const Report._();

  const factory Report({
    required String id,
    @JsonKey(unknownEnumValue: ReportType.deviceStatus)
    required ReportType type,
    required String title,
    @JsonKey(unknownEnumValue: ReportFormat.pdf) required ReportFormat format,
    @JsonKey(unknownEnumValue: ReportStatus.pending)
    @Default(ReportStatus.pending)
    ReportStatus status,
    @Default(<String, dynamic>{}) Map<String, dynamic> filters,

    /// Caminho no servidor; só serve para saber que o arquivo existe — o
    /// download é sempre por `GET /reports/:id/download`.
    String? fileUrl,
    String? createdById,
    DateTime? createdAt,
  }) = _Report;

  factory Report.fromJson(Map<String, dynamic> json) => _$ReportFromJson(json);

  bool get canDownload => status == ReportStatus.completed;

  /// Nome do arquivo baixado: título sem caracteres problemáticos + extensão.
  String get fileName {
    final safe = title
        .replaceAll(RegExp(r'[^\w\s\-À-ÿ]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    return '${safe.isEmpty ? 'relatorio_$id' : safe}.${format.extension}';
  }
}
