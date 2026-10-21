import 'package:flutter/foundation.dart';

/// Dia da semana no cron: domingo é 0 (o cron também aceita 7).
enum Weekday {
  sunday(0, 'Dom', 'D'),
  monday(1, 'Seg', 'S'),
  tuesday(2, 'Ter', 'T'),
  wednesday(3, 'Qua', 'Q'),
  thursday(4, 'Qui', 'Q'),
  friday(5, 'Sex', 'S'),
  saturday(6, 'Sáb', 'S');

  const Weekday(this.cronValue, this.shortLabel, this.initial);

  final int cronValue;
  final String shortLabel;

  /// Letra do chip do construtor de agenda.
  final String initial;

  static Weekday fromCron(int value) => values[value % 7];
}

/// Agenda do construtor: em quais dias e a que horas. Vira a expressão cron
/// `m h * * dias` que o backend executa.
@immutable
class WeeklySchedule {
  WeeklySchedule({
    required Set<Weekday> days,
    required this.hour,
    required this.minute,
  }) : assert(hour >= 0 && hour <= 23, 'hora fora de 0–23'),
       assert(minute >= 0 && minute <= 59, 'minuto fora de 0–59'),
       days = Set.unmodifiable(days);

  final Set<Weekday> days;
  final int hour;
  final int minute;

  /// Lê um cron que o construtor sabe representar (um horário fixo, todo
  /// dia do mês e todo mês). Qualquer outro formato devolve `null` — o
  /// formulário cai no modo avançado.
  static WeeklySchedule? fromCron(String cron) {
    final fields = cron.trim().split(RegExp(r'\s+'));
    if (fields.length != 5) return null;
    final minute = _plainInt(fields[0], 0, 59);
    final hour = _plainInt(fields[1], 0, 23);
    if (minute == null || hour == null) return null;
    if (fields[2] != '*' || fields[3] != '*') return null;
    final days = _parseDays(fields[4]);
    if (days == null || days.isEmpty) return null;
    return WeeklySchedule(days: days, hour: hour, minute: minute);
  }

  String? get validationError =>
      days.isEmpty ? 'Escolha pelo menos um dia.' : null;

  bool get isValid => validationError == null;

  /// `30 7 * * 1-5`. Todos os dias viram `*`; 3+ dias seguidos viram faixa.
  String toCron() => '$minute $hour * * ${_daysField()}';

  /// "Seg a Sex às 07:30", "Todos os dias às 22:00"...
  String describe() => '${_describeDays()} às ${formatTime(hour, minute)}';

  List<int> get _sortedValues => days.map((d) => d.cronValue).toList()..sort();

  String _daysField() {
    if (days.length == Weekday.values.length) return '*';
    final parts = <String>[];
    for (final run in _runs(_sortedValues)) {
      if (run.length >= 3) {
        parts.add('${run.first}-${run.last}');
      } else {
        parts.addAll(run.map((v) => '$v'));
      }
    }
    return parts.join(',');
  }

  String _describeDays() {
    final values = _sortedValues;
    if (values.length == 7) return 'Todos os dias';
    if (listEquals(values, const [0, 6])) return 'Fins de semana';
    final runs = _runs(values);
    if (runs.length == 1 && values.length >= 3) {
      return '${Weekday.fromCron(values.first).shortLabel} a '
          '${Weekday.fromCron(values.last).shortLabel}';
    }
    final labels = values.map((v) => Weekday.fromCron(v).shortLabel).toList();
    if (labels.length == 1) return labels.single;
    return '${labels.sublist(0, labels.length - 1).join(', ')} e '
        '${labels.last}';
  }

  /// Agrupa valores ordenados em sequências consecutivas.
  static List<List<int>> _runs(List<int> sorted) {
    final runs = <List<int>>[];
    for (final value in sorted) {
      if (runs.isNotEmpty && runs.last.last == value - 1) {
        runs.last.add(value);
      } else {
        runs.add([value]);
      }
    }
    return runs;
  }

  static int? _plainInt(String text, int min, int max) {
    if (!RegExp(r'^\d+$').hasMatch(text)) return null;
    final value = int.parse(text);
    return value < min || value > max ? null : value;
  }

  static Set<Weekday>? _parseDays(String field) {
    if (field == '*') return Weekday.values.toSet();
    final days = <Weekday>{};
    for (final item in field.split(',')) {
      final bounds = item.split('-');
      if (bounds.length > 2) return null;
      final values = [for (final b in bounds) _cronDayValue(b)];
      if (values.contains(null)) return null;
      final start = values.first!;
      final end = values.last!;
      if (end < start) return null;
      for (var v = start; v <= end; v++) {
        days.add(Weekday.fromCron(v));
      }
    }
    return days;
  }

  @override
  bool operator ==(Object other) =>
      other is WeeklySchedule &&
      other.hour == hour &&
      other.minute == minute &&
      setEquals(other.days, days);

  @override
  int get hashCode => Object.hash(hour, minute, Object.hashAllUnordered(days));

  @override
  String toString() => 'WeeklySchedule(${toCron()})';
}

/// `7, 5` → `"07:05"`.
String formatTime(int hour, int minute) =>
    '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

const _dayNames = ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'];
const _monthNames = [
  'JAN',
  'FEB',
  'MAR',
  'APR',
  'MAY',
  'JUN',
  'JUL',
  'AUG',
  'SEP',
  'OCT',
  'NOV',
  'DEC',
];

/// Dia da semana do cron (0–7 ou SUN–SAT).
int? _cronDayValue(String token) {
  final named = _dayNames.indexOf(token.toUpperCase());
  if (named >= 0) return named;
  if (!RegExp(r'^\d+$').hasMatch(token)) return null;
  final value = int.parse(token);
  return value > 7 ? null : value;
}

class _CronField {
  const _CronField(this.label, this.min, this.max, {this.names = const []});

  final String label;
  final int min;
  final int max;

  /// Nomes aceitos; o índice + [min] é o valor.
  final List<String> names;

  String get error => '$label (use $min–$max).';

  int? valueOf(String token) {
    final named = names.indexOf(token.toUpperCase());
    if (named >= 0) return named + min;
    if (!RegExp(r'^\d+$').hasMatch(token)) return null;
    final value = int.parse(token);
    return value < min || value > max ? null : value;
  }

  bool accepts(String field) => field.split(',').every(_acceptsItem);

  bool _acceptsItem(String item) {
    final parts = item.split('/');
    if (parts.length > 2) return false;
    if (parts.length == 2) {
      final step = int.tryParse(parts[1]);
      if (step == null || step < 1 || !RegExp(r'^\d+$').hasMatch(parts[1])) {
        return false;
      }
    }
    final base = parts[0];
    if (base == '*') return true;
    final bounds = base.split('-');
    if (bounds.length > 2) return false;
    final values = bounds.map(valueOf).toList();
    if (values.contains(null)) return false;
    return values.first! <= values.last!;
  }
}

const _fields = [
  _CronField('Minuto inválido', 0, 59),
  _CronField('Hora inválida', 0, 23),
  _CronField('Dia do mês inválido', 1, 31),
  _CronField('Mês inválido', 1, 12, names: _monthNames),
  _CronField('Dia da semana inválido', 0, 7, names: _dayNames),
];

/// Valida o cron avançado (5 campos, como o backend agenda). Devolve a
/// mensagem do primeiro problema, ou `null` se estiver válido.
String? validateCron(String cron) {
  final trimmed = cron.trim();
  if (trimmed.isEmpty) return 'Informe a expressão cron.';
  final fields = trimmed.split(RegExp(r'\s+'));
  if (fields.length != _fields.length) {
    return 'Use 5 campos: minuto, hora, dia do mês, mês e dia da semana.';
  }
  for (var i = 0; i < fields.length; i++) {
    if (!_fields[i].accepts(fields[i])) return _fields[i].error;
  }
  return null;
}

/// Frase da agenda quando o cron é simples; senão o cron cru.
String describeCron(String cron) =>
    WeeklySchedule.fromCron(cron)?.describe() ?? 'Cron: ${cron.trim()}';
