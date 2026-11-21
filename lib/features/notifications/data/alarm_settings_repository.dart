import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/network_providers.dart';

/// Configuração de alarmes da organização (`/sensors/alarm-settings`).
///
/// [reminderMinutes] é o intervalo entre lembretes de um alarme de sensor
/// aberto e não reconhecido. `0` desativa. Vale para toda a organização.
abstract interface class AlarmSettingsRepository {
  Future<int> reminderMinutes();

  /// Só ADMIN e COORDINATOR; o backend recusa os demais com 403.
  Future<int> setReminderMinutes(int minutes);
}

class HttpAlarmSettingsRepository implements AlarmSettingsRepository {
  HttpAlarmSettingsRepository(this._dio);

  final Dio _dio;

  static int _parse(Object? json) =>
      ((json! as Map<String, dynamic>)['reminderMinutes'] as num).toInt();

  @override
  Future<int> reminderMinutes() async =>
      _parse(await _dio.getJson('/sensors/alarm-settings'));

  @override
  Future<int> setReminderMinutes(int minutes) async => _parse(
    await _dio.putJson(
      '/sensors/alarm-settings',
      data: {'reminderMinutes': minutes},
    ),
  );
}

final alarmSettingsRepositoryProvider = Provider<AlarmSettingsRepository>(
  (ref) => HttpAlarmSettingsRepository(ref.watch(dioProvider)),
  name: 'alarmSettingsRepositoryProvider',
);

/// Intervalo atual do lembrete, em minutos.
final alarmReminderMinutesProvider = FutureProvider.autoDispose<int>(
  (ref) => ref.watch(alarmSettingsRepositoryProvider).reminderMinutes(),
  name: 'alarmReminderMinutesProvider',
);
