import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/realtime/realtime_client.dart';
import 'package:autouni_app/features/dashboard/data/dashboard_repository.dart';
import 'package:autouni_app/features/dashboard/domain/dashboard_models.dart';
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
