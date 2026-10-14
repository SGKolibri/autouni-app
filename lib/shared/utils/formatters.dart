/// Formatação de números e horários para a UI (pt-BR), sem depender de
/// `intl`.
library;

/// `12.345` → `"12,3 kWh"`; abaixo de 10 kWh mostra duas casas.
String formatKwh(double kwh) {
  final decimals = kwh.abs() < 10 ? 2 : 1;
  return '${formatDecimal(kwh, decimals)} kWh';
}

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

String _two(int value) => value.toString().padLeft(2, '0');
