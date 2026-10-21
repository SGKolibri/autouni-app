import 'package:autouni_app/shared/utils/error_messages.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/shared/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formatDecimal usa vírgula decimal e ponto de milhar', () {
    expect(formatDecimal(1234.56), '1.234,6');
    expect(formatDecimal(1234567, 0), '1.234.567');
    expect(formatDecimal(-12.345, 2), '-12,35');
    expect(formatDecimal(0.5), '0,5');
  });

  test('formatKwh ajusta as casas pela grandeza', () {
    expect(formatKwh(3.456), '3,46 kWh');
    expect(formatKwh(1250.04), '1.250,0 kWh');
    expect(formatKwh(0), '0,00 kWh');
  });

  test('formatKw e formatWh', () {
    expect(formatKw(1.234), '1,23 kW');
    expect(formatKw(12.34), '12,3 kW');
    expect(formatWh(250), '250 Wh');
    expect(formatWh(1500.4), '1.500 Wh');
  });

  test('formatDayMonth e formatHour', () {
    final instant = DateTime(2026, 3, 7, 9, 5);
    expect(formatDayMonth(instant), '07/03');
    expect(formatHour(instant), '09h');
  });

  test('formatDateTime mostra data e hora', () {
    expect(formatDateTime(DateTime(2026, 3, 7, 9, 5)), '07/03/2026 09:05');
  });

  test('formatClock mostra só a hora hoje e a data em outro dia', () {
    final now = DateTime(2026, 10, 14, 15);
    expect(formatClock(DateTime(2026, 10, 14, 9, 5), now: now), '09:05');
    expect(
      formatClock(DateTime(2026, 10, 13, 23, 59), now: now),
      '13/10 23:59',
    );
  });

  test('describeError usa a mensagem da ApiException', () {
    expect(
      describeError(const NetworkException()),
      'Sem conexão com a internet.',
    );
    expect(describeError(StateError('x')), 'Algo deu errado. Tente novamente.');
  });
}
