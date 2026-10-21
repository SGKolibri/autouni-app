/// Formatação de números e horários para a UI (pt-BR), sem depender de
/// `intl`.
library;

/// `12.345` → `"12,3 kWh"`; abaixo de 10 kWh mostra duas casas.
String formatKwh(double kwh) {
  final decimals = kwh.abs() < 10 ? 2 : 1;
  return '${formatDecimal(kwh, decimals)} kWh';
}

/// Potência: `1.234` → `"1,23 kW"` (mesmas casas de [formatKwh]).
String formatKw(double kw) {
  final decimals = kw.abs() < 10 ? 2 : 1;
  return '${formatDecimal(kw, decimals)} kW';
}

/// Energia de uma leitura: `1500.4` → `"1.500 Wh"`.
String formatWh(double wh) => '${formatDecimal(wh, 0)} Wh';

/// Número com vírgula decimal e ponto de milhar: `1234.5` → `"1.234,5"`.
String formatDecimal(num value, [int decimals = 1]) {
  final fixed = value.toDouble().toStringAsFixed(decimals);
  final negative = fixed.startsWith('-');
  final unsigned = negative ? fixed.substring(1) : fixed;
  final parts = unsigned.split('.');
  final integer = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  final decimal = parts.length > 1 ? ',${parts[1]}' : '';
  return '${negative ? '-' : ''}$integer$decimal';
}

/// Horário relativo ao dia de [now]: `"09:05"` hoje, `"13/10 09:05"` em
/// outro dia. Sempre no fuso local.
String formatClock(DateTime instant, {DateTime? now}) {
  final local = instant.toLocal();
  final today = (now ?? DateTime.now()).toLocal();
  final time = '${_two(local.hour)}:${_two(local.minute)}';
  final sameDay =
      local.year == today.year &&
      local.month == today.month &&
      local.day == today.day;
  return sameDay ? time : '${_two(local.day)}/${_two(local.month)} $time';
}

/// `"07/03"`, no fuso local.
String formatDayMonth(DateTime instant) {
  final local = instant.toLocal();
  return '${_two(local.day)}/${_two(local.month)}';
}

/// `"09h"`, no fuso local.
String formatHour(DateTime instant) => '${_two(instant.toLocal().hour)}h';

/// `"07/03/2026 09:05"`, no fuso local.
String formatDateTime(DateTime instant) {
  final local = instant.toLocal();
  return '${formatDayMonth(local)}/${local.year} '
      '${_two(local.hour)}:${_two(local.minute)}';
}

String _two(int value) => value.toString().padLeft(2, '0');
