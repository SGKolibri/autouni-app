import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/realtime/realtime_client.dart';
import 'package:autouni_app/features/automations/data/automations_repository.dart';
import 'package:autouni_app/features/automations/domain/automation_models.dart';
import 'package:autouni_app/features/dashboard/data/dashboard_repository.dart';
import 'package:autouni_app/features/dashboard/domain/dashboard_models.dart';
import 'package:autouni_app/features/energy/data/energy_repository.dart';
import 'package:autouni_app/features/energy/domain/energy_models.dart';
import 'package:mocktail/mocktail.dart';

/// Dashboard vazio, para testes do app inteiro que não tratam do dashboard.
class EmptyDashboardRepository implements DashboardRepository {
  @override
  Stream<Cached<DashboardOverview>> watchOverview() => Stream.value(
    const Cached(DashboardOverview(buildings: [], energy: null, alerts: [])),
  );
}

class MockRealtimeClient extends Mock implements RealtimeClient {
  /// Mock já conectado, sem eventos.
  static MockRealtimeClient connected() {
    final client = MockRealtimeClient();
    when(client.connect).thenAnswer((_) async {});
    when(client.disconnect).thenAnswer((_) async {});
    when(() => client.status).thenReturn(RealtimeConnectionStatus.connected);
    when(() => client.statusStream).thenAnswer((_) => const Stream.empty());
    return client;
  }
}

/// Nenhuma automação; escritas não são esperadas nos testes do app inteiro.
class EmptyAutomationsRepository extends Mock implements AutomationsRepository {
  @override
  Stream<Cached<List<Automation>>> watchAll() =>
      Stream.value(const Cached(<Automation>[]));
}

/// Consumo zerado para qualquer escopo.
class EmptyEnergyRepository implements EnergyRepository {
  @override
  Stream<Cached<EnergyOverview>> watchOverview(
    EnergyScope scope,
    EnergyPeriod period,
  ) => Stream.value(
    Cached(
      EnergyOverview(
        scope: scope,
        period: period,
        stats: const EnergyStats(totalKwh: 1, readingCount: 1),
        history: const [],
        ranking: const [],
      ),
    ),
  );
}
