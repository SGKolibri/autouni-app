import 'package:freezed_annotation/freezed_annotation.dart';

part 'energy_models.freezed.dart';
part 'energy_models.g.dart';

/// Período das consultas de energia (`period` do backend).
enum EnergyPeriod {
  today('today', 'Hoje', 1),
  week('week', '7 dias', 24),
  month('month', 'Mês', 24);

  const EnergyPeriod(this.apiValue, this.label, this.bucketHours);

  final String apiValue;
  final String label;

  /// Largura de cada ponto do histórico: o backend agrupa por hora em
  /// "hoje" e por dia em semana/mês.
  final int bucketHours;

  /// Valor desconhecido cai em [today].
  static EnergyPeriod fromApi(Object? value) =>
      values.firstWhere((p) => p.apiValue == value, orElse: () => today);

  /// Início do período no fuso local, com a mesma regra do backend: hoje à
  /// meia-noite, os últimos 7 dias (hoje incluso) ou o dia 1 do mês.
  DateTime startOf(DateTime now) => switch (this) {
    today => DateTime(now.year, now.month, now.day),
    week => DateTime(now.year, now.month, now.day - 6),
    month => DateTime(now.year, now.month),
  };
}

/// Nível da hierarquia em que o consumo é olhado.
enum EnergyLevel {
  general('general', 'Campus', 'Prédios'),
  building('building', 'Prédio', 'Andares'),
  floor('floor', 'Andar', 'Salas'),
  room('room', 'Sala', 'Dispositivos'),
  device('device', 'Dispositivo', null);

  const EnergyLevel(this.apiValue, this.label, this._childrenLabel);

  final String apiValue;
  final String label;
  final String? _childrenLabel;

  static EnergyLevel? fromApi(Object? value) {
    for (final level in values) {
      if (level.apiValue == value) return level;
    }
    return null;
  }

  /// O nível que o ranking deste compara (`GET /energy/comparison`).
  EnergyLevel? get child => switch (this) {
    general => building,
    building => floor,
    floor => room,
    room => device,
    device => null,
  };

  /// Título da seção de ranking; `null` na folha (dispositivo).
  String? get rankingTitle =>
      _childrenLabel == null ? null : '$_childrenLabel que mais consomem';
}

/// Onde o consumo está sendo olhado: o campus inteiro ou uma entidade.
@immutable
class EnergyScope {
  const EnergyScope({required this.level, required this.id, required this.name})
    : assert(level == EnergyLevel.general || id != null);

  const EnergyScope.campus()
    : level = EnergyLevel.general,
      id = null,
      name = 'Campus';

  /// Lê da query da URL (`?level=building&id=..&name=..`). Qualquer coisa
  /// incompleta vira o campus.
  factory EnergyScope.fromQuery(Map<String, String> query) {
    final level = EnergyLevel.fromApi(query['level']);
    final id = query['id'];
    if (level == null || level == EnergyLevel.general || id == null) {
      return const EnergyScope.campus();
    }
    final name = query['name']?.trim();
    return EnergyScope(
      level: level,
      id: id,
      name: (name == null || name.isEmpty) ? level.label : name,
    );
  }

  final EnergyLevel level;
  final String? id;
  final String name;

  Map<String, String> toQuery() => {
    'level': level.apiValue,
    'id': ?id,
    'name': name,
  };

  /// O escopo de um item do ranking deste escopo; `null` na folha.
  EnergyScope? childFor(EnergyRankingItem item) {
    final child = level.child;
    if (child == null) return null;
    return EnergyScope(level: child, id: item.id, name: item.name);
  }

  @override
  bool operator ==(Object other) =>
      other is EnergyScope &&
      other.level == level &&
      other.id == id &&
      other.name == name;

  @override
  int get hashCode => Object.hash(level, id, name);

  @override
  String toString() => 'EnergyScope(${level.apiValue}, $id, $name)';
}

/// KPIs do período. `GET /energy/stats` (campus) traz também a contagem de
/// dispositivos; as rotas por nível trazem só a agregação das leituras.
@freezed
abstract class EnergyStats with _$EnergyStats {
  const EnergyStats._();

  const factory EnergyStats({
    @Default(0) double totalKwh,
    @JsonKey(name: 'count') @Default(0) int readingCount,
    double? avgWh,
    double? maxWh,
    double? minWh,
    int? totalDevices,
    int? activeDevices,
    @JsonKey(name: 'hasData') bool? reportedHasData,
  }) = _EnergyStats;

  factory EnergyStats.fromJson(Map<String, dynamic> json) =>
      _$EnergyStatsFromJson(json);

  /// Há consumo para mostrar (telemetria ou estimativa).
  bool get hasData => reportedHasData ?? (readingCount > 0 || totalKwh > 0);
}

/// Um ponto do histórico (`GET /energy/history`).
@freezed
abstract class EnergyHistoryPoint with _$EnergyHistoryPoint {
  const EnergyHistoryPoint._();

  const factory EnergyHistoryPoint({
    required DateTime bucket,
    @Default(0) double totalKwh,
    @Default(0) int count,
  }) = _EnergyHistoryPoint;

  factory EnergyHistoryPoint.fromJson(Map<String, dynamic> json) =>
      _$EnergyHistoryPointFromJson(json);

  /// Potência média no intervalo do ponto, em kW.
  double averageKw({required int bucketHours}) => totalKwh / bucketHours;
}

/// Uma entidade no ranking de consumo (`GET /energy/comparison`).
@freezed
abstract class EnergyRankingItem with _$EnergyRankingItem {
  const factory EnergyRankingItem({
    required String id,
    @JsonKey(fromJson: _displayName) required String name,
    @Default(0) double totalKwh,
  }) = _EnergyRankingItem;

  factory EnergyRankingItem.fromJson(Map<String, dynamic> json) =>
      _$EnergyRankingItemFromJson(json);
}

/// O backend nomeia andares sem nome como "Floor N".
String _displayName(Object? raw) {
  final name = '$raw';
  final match = RegExp(r'^Floor (\d+)$').firstMatch(name);
  if (match == null) return name;
  final number = int.parse(match.group(1)!);
  return number == 0 ? 'Térreo' : '$numberº andar';
}

/// Tudo o que a tela de energia mostra para um escopo e período.
class EnergyOverview {
  const EnergyOverview({
    required this.scope,
    required this.period,
    required this.stats,
    required this.history,
    required this.ranking,
  });

  final EnergyScope scope;
  final EnergyPeriod period;
  final EnergyStats stats;
  final List<EnergyHistoryPoint> history;

  /// `null` na folha (dispositivo) ou se o ranking não pôde ser carregado.
  final List<EnergyRankingItem>? ranking;

  /// Potência média do ponto mais recente, em kW.
  double? get currentKw => history.isEmpty
      ? null
      : history.last.averageKw(bucketHours: period.bucketHours);

  /// Maior potência média entre os pontos do período, em kW.
  double? get peakKw => history.isEmpty
      ? null
      : history
            .map((p) => p.averageKw(bucketHours: period.bucketHours))
            .reduce((a, b) => a > b ? a : b);

  List<EnergyRankingItem> get sortedRanking =>
      [...?ranking]..sort((a, b) => b.totalKwh.compareTo(a.totalKwh));
}
