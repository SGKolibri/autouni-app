import 'package:flutter/foundation.dart';

import '../../../shared/utils/formatters.dart';
import 'report_models.dart';

/// Atalhos de período do formulário.
enum ReportPeriodPreset {
  last7Days('Últimos 7 dias'),
  last30Days('Últimos 30 dias'),
  thisMonth('Este mês'),
  lastMonth('Mês passado'),
  custom('Personalizado');

  const ReportPeriodPreset(this.label);

  final String label;
}

/// Intervalo de datas, dias inteiros (sem hora).
@immutable
class ReportPeriod {
  ReportPeriod(DateTime start, DateTime end)
    : start = DateTime(start.year, start.month, start.day),
      end = DateTime(end.year, end.month, end.day);

  /// Resolve [preset] em relação a [today]. `custom` não tem datas próprias.
  static ReportPeriod? of(ReportPeriodPreset preset, DateTime today) {
    final day = DateTime(today.year, today.month, today.day);
    return switch (preset) {
      ReportPeriodPreset.last7Days => ReportPeriod(
        day.subtract(const Duration(days: 6)),
        day,
      ),
      ReportPeriodPreset.last30Days => ReportPeriod(
        day.subtract(const Duration(days: 29)),
        day,
      ),
      ReportPeriodPreset.thisMonth => ReportPeriod(
        DateTime(day.year, day.month),
        day,
      ),
      ReportPeriodPreset.lastMonth => ReportPeriod(
        DateTime(day.year, day.month - 1),
        DateTime(day.year, day.month, 0),
      ),
      ReportPeriodPreset.custom => null,
    };
  }

  final DateTime start;
  final DateTime end;

  int get days => end.difference(start).inDays + 1;

  /// "01/10 a 31/10/2026".
  String get label =>
      '${formatDayMonth(start)} a '
      '${formatDayMonth(end)}/${end.year}';

  static String apiDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is ReportPeriod && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// O que o formulário de "Gerar relatório" envia.
@immutable
class ReportRequest {
  const ReportRequest({
    required this.type,
    required this.format,
    required this.title,
    this.period,
    this.buildingId,
  });

  static const int minTitleLength = 5;

  /// Período máximo aceito pelo app (um ano), para não pedir ao backend um
  /// arquivo gigante por engano.
  static const int maxPeriodDays = 366;

  final ReportType type;
  final ReportFormat format;
  final String title;

  /// Obrigatório nos tipos com período ([ReportType.usesPeriod]).
  final ReportPeriod? period;

  /// `null` = todos os prédios.
  final String? buildingId;

  /// Título sugerido: "Consumo de energia · 01/10 a 31/10/2026 · Bloco A".
  static String suggestTitle({
    required ReportType type,
    ReportPeriod? period,
    String? buildingName,
  }) => [
    type.label,
    if (type.usesPeriod && period != null) period.label,
    buildingName ?? 'Campus',
  ].join(' · ');

  /// Erros por campo (`title`, `period`); vazio = válido.
  Map<String, String> validate({required DateTime today}) {
    final errors = <String, String>{};
    if (title.trim().length < minTitleLength) {
      errors['title'] =
          'O título precisa ter pelo menos $minTitleLength letras.';
    }
    if (type.usesPeriod) {
      final period = this.period;
      final day = DateTime(today.year, today.month, today.day);
      if (period == null) {
        errors['period'] = 'Escolha o período.';
      } else if (period.end.isBefore(period.start)) {
        errors['period'] = 'A data final é anterior à inicial.';
      } else if (period.start.isAfter(day)) {
        errors['period'] = 'O período não pode começar no futuro.';
      } else if (period.days > maxPeriodDays) {
        errors['period'] = 'O período vai até $maxPeriodDays dias.';
      }
    }
    return errors;
  }

  /// Corpo de `POST /reports`.
  Map<String, dynamic> toJson({required String createdById}) => {
    'type': type.apiValue,
    'format': format.apiValue,
    'title': title.trim(),
    'createdById': createdById,
    'filters': {
      if (type.usesPeriod && period != null) ...{
        'startDate': ReportPeriod.apiDate(period!.start),
        'endDate': ReportPeriod.apiDate(period!.end),
      },
      'buildingId': ?buildingId,
    },
  };

  /// Mesmo pedido de um relatório existente (para "Gerar de novo").
  static ReportRequest fromReport(Report report) {
    final filters = report.filters;
    final start = DateTime.tryParse('${filters['startDate']}');
    final end = DateTime.tryParse('${filters['endDate']}');
    final building = filters['buildingId'];
    return ReportRequest(
      type: report.type,
      format: report.format,
      title: report.title,
      period: start != null && end != null ? ReportPeriod(start, end) : null,
      buildingId: building is String && building.isNotEmpty ? building : null,
    );
  }
}
