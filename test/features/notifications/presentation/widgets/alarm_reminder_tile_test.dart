import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/features/notifications/data/alarm_settings_repository.dart';
import 'package:autouni_app/features/notifications/presentation/widgets/alarm_reminder_tile.dart';
import 'package:autouni_app/shared/models/user_role.dart';
import 'package:autouni_app/shared/rbac/rbac_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository implements AlarmSettingsRepository {
  _FakeRepository(this.minutes);

  int minutes;
  final saved = <int>[];
  ApiException? failWith;

  @override
  Future<int> reminderMinutes() async => minutes;

  @override
  Future<int> setReminderMinutes(int value) async {
    if (failWith != null) throw failWith!;
    saved.add(value);
    return minutes = value;
  }
}

void main() {
  Future<void> pump(
    WidgetTester tester,
    _FakeRepository repository,
    UserRole role,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alarmSettingsRepositoryProvider.overrideWithValue(repository),
          currentUserRoleProvider.overrideWithValue(role),
        ],
        child: const MaterialApp(home: Scaffold(body: AlarmReminderTile())),
      ),
    );
    await tester.pumpAndSettle();
  }

  test('descreve o intervalo', () {
    expect(describeAlarmReminder(0), 'Desativado');
    expect(describeAlarmReminder(1), 'A cada 1 minuto');
    expect(describeAlarmReminder(5), 'A cada 5 minutos');
  });

  testWidgets('coordenador escolhe um novo intervalo e ele é salvo', (
    tester,
  ) async {
    final repository = _FakeRepository(5);
    await pump(tester, repository, UserRole.coordinator);
    expect(find.text('A cada 5 minutos'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings-alarm-reminder')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('alarm-reminder-option-15')));
    await tester.pumpAndSettle();

    expect(repository.saved, [15]);
    expect(find.text('A cada 15 minutos'), findsOneWidget);
    expect(find.text('Lembrete: A cada 15 minutos.'), findsOneWidget);
  });

  testWidgets('valor fora da lista do app aparece como opção', (tester) async {
    await pump(tester, _FakeRepository(45), UserRole.admin);

    await tester.tap(find.byKey(const Key('settings-alarm-reminder')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('alarm-reminder-option-45')), findsOneWidget);
  });

  testWidgets('técnico só vê o valor, sem abrir o seletor', (tester) async {
    await pump(tester, _FakeRepository(5), UserRole.technician);

    expect(
      find.text('A cada 5 minutos · definido pela coordenação'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('settings-alarm-reminder')));
    await tester.pumpAndSettle();
    expect(find.byType(SimpleDialog), findsNothing);
  });

  testWidgets('erro ao salvar mantém o valor e avisa', (tester) async {
    final repository = _FakeRepository(5)
      ..failWith = const ForbiddenException(message: 'sem permissão');
    await pump(tester, repository, UserRole.admin);

    await tester.tap(find.byKey(const Key('settings-alarm-reminder')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('alarm-reminder-option-0')));
    await tester.pumpAndSettle();

    expect(find.text('Não foi possível salvar o lembrete.'), findsOneWidget);
    expect(find.text('A cada 5 minutos'), findsOneWidget);
  });
}
