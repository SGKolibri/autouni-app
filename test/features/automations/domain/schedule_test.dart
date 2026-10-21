import 'package:autouni_app/features/automations/domain/schedule.dart';
import 'package:flutter_test/flutter_test.dart';

WeeklySchedule _at(Set<Weekday> days, int hour, int minute) =>
    WeeklySchedule(days: days, hour: hour, minute: minute);

const _weekdays = {
  Weekday.monday,
  Weekday.tuesday,
  Weekday.wednesday,
  Weekday.thursday,
  Weekday.friday,
};

void main() {
  group('WeeklySchedule.toCron (agenda → cron)', () {
    test('todos os dias vira *', () {
      expect(_at(Weekday.values.toSet(), 22, 0).toCron(), '0 22 * * *');
    });

    test('dias úteis viram faixa 1-5', () {
      expect(_at(_weekdays, 7, 30).toCron(), '30 7 * * 1-5');
    });

    test('dias soltos viram lista em ordem', () {
      expect(
        _at(
          {Weekday.friday, Weekday.monday, Weekday.wednesday},
          18,
          5,
        ).toCron(),
        '5 18 * * 1,3,5',
      );
    });

    test('mistura de faixa (3+ dias seguidos) e dias soltos', () {
      expect(
        _at(
          {Weekday.monday, Weekday.tuesday, Weekday.wednesday, Weekday.friday},
          8,
          0,
        ).toCron(),
        '0 8 * * 1-3,5',
      );
    });

    test('dois dias seguidos ficam como lista, não faixa', () {
      expect(
        _at({Weekday.saturday, Weekday.sunday}, 10, 0).toCron(),
        '0 10 * * 0,6',
      );
    });

    test('domingo é 0 (convenção do cron)', () {
      expect(_at({Weekday.sunday}, 0, 0).toCron(), '0 0 * * 0');
    });

    test('limites do horário', () {
      expect(_at({Weekday.monday}, 23, 59).toCron(), '59 23 * * 1');
      expect(
        () => WeeklySchedule(days: {Weekday.monday}, hour: 24, minute: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => WeeklySchedule(days: {Weekday.monday}, hour: 1, minute: 60),
        throwsA(isA<AssertionError>()),
      );
    });

    test('sem dias não gera cron (validação do formulário)', () {
      final empty = _at({}, 8, 0);

      expect(empty.isValid, isFalse);
      expect(empty.validationError, 'Escolha pelo menos um dia.');
      expect(_at({Weekday.monday}, 8, 0).validationError, isNull);
    });
  });

  group('WeeklySchedule.fromCron (cron → agenda)', () {
    test('ida e volta para cada combinação de dias', () {
      for (var mask = 1; mask < 128; mask++) {
        final days = {
          for (final day in Weekday.values)
            if (mask & (1 << day.cronValue) != 0) day,
        };
        final schedule = _at(days, mask % 24, mask % 60);

        expect(
          WeeklySchedule.fromCron(schedule.toCron()),
          schedule,
          reason: schedule.toCron(),
        );
      }
    });

    test('aceita 7 como domingo, nomes em inglês e faixas', () {
      expect(WeeklySchedule.fromCron('0 9 * * 7'), _at({Weekday.sunday}, 9, 0));
      expect(
        WeeklySchedule.fromCron('15 6 * * MON-FRI'),
        _at(_weekdays, 6, 15),
      );
      expect(
        WeeklySchedule.fromCron('0 12 * * sat,sun'),
        _at({Weekday.saturday, Weekday.sunday}, 12, 0),
      );
    });

    test('espaços extras não atrapalham', () {
      expect(
        WeeklySchedule.fromCron('  0   22 * *   *  '),
        _at(Weekday.values.toSet(), 22, 0),
      );
    });

    test('cron que o construtor não representa devolve null', () {
      for (final cron in [
        '*/5 * * * *', // a cada 5 minutos
        '0 */2 * * *', // a cada 2 horas
        '0 8 1 * *', // dia do mês
        '0 8 * 12 *', // mês
        '0 8,18 * * *', // dois horários
        '0 8 * * 1/2', // passo nos dias
        '0 0 8 * * *', // 6 campos (segundos)
        'lixo',
        '',
      ]) {
        expect(WeeklySchedule.fromCron(cron), isNull, reason: cron);
      }
    });
  });

  group('WeeklySchedule.describe', () {
    test('frases em português', () {
      expect(
        _at(Weekday.values.toSet(), 22, 0).describe(),
        'Todos os dias às 22:00',
      );
      expect(_at(_weekdays, 7, 30).describe(), 'Seg a Sex às 07:30');
      expect(
        _at({Weekday.saturday, Weekday.sunday}, 9, 5).describe(),
        'Fins de semana às 09:05',
      );
      expect(_at({Weekday.monday}, 8, 0).describe(), 'Seg às 08:00');
      expect(
        _at(
          {Weekday.monday, Weekday.wednesday, Weekday.friday},
          8,
          0,
        ).describe(),
        'Seg, Qua e Sex às 08:00',
      );
      expect(
        _at({Weekday.sunday, Weekday.monday}, 8, 0).describe(),
        'Dom e Seg às 08:00',
      );
    });
  });

  group('validateCron (cron avançado)', () {
    test('expressões válidas', () {
      for (final cron in [
        '0 22 * * *',
        '*/15 8-18 * * 1-5',
        '0 0 1 1 *',
        '30 6 1,15 * MON',
        '0 12 * JAN-MAR 0',
        '5-10/2 * * * 7',
        '0 0 L * *'.replaceAll('L', '31'),
      ]) {
        expect(validateCron(cron), isNull, reason: cron);
      }
    });

    test('vazio', () {
      expect(validateCron('   '), 'Informe a expressão cron.');
    });

    test('quantidade de campos', () {
      const message =
          'Use 5 campos: minuto, hora, dia do mês, mês e dia da semana.';
      expect(validateCron('0 22 * *'), message);
      expect(validateCron('0 0 22 * * *'), message);
    });

    test('valor fora da faixa diz qual campo e a faixa aceita', () {
      expect(validateCron('60 * * * *'), 'Minuto inválido (use 0–59).');
      expect(validateCron('0 24 * * *'), 'Hora inválida (use 0–23).');
      expect(validateCron('0 0 0 * *'), 'Dia do mês inválido (use 1–31).');
      expect(validateCron('0 0 * 13 *'), 'Mês inválido (use 1–12).');
      expect(validateCron('0 0 * * 8'), 'Dia da semana inválido (use 0–7).');
    });

    test('sintaxe inválida', () {
      for (final cron in [
        'a * * * *',
        '1-- * * * *',
        '*/0 * * * *',
        '10-5 * * * *',
        '1,,2 * * * *',
        '0 0 * * FUN',
      ]) {
        expect(validateCron(cron), isNotNull, reason: cron);
      }
    });
  });

  group('describeCron', () {
    test('usa a frase da agenda quando possível', () {
      expect(describeCron('30 7 * * 1-5'), 'Seg a Sex às 07:30');
    });

    test('senão mostra o cron cru', () {
      expect(describeCron('*/15 * * * *'), 'Cron: */15 * * * *');
    });
  });
}
