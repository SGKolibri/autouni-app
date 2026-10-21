import 'dart:async';

import 'package:autouni_app/core/cache/cached.dart';
import 'package:autouni_app/core/network/api_exception.dart';
import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/features/energy/data/energy_repository.dart';
import 'package:autouni_app/features/energy/domain/energy_models.dart';
import 'package:autouni_app/features/energy/presentation/energy_routes.dart';
import 'package:autouni_app/features/energy/presentation/pages/energy_page.dart';
import 'package:autouni_app/shared/design_system/design_system.dart';
import 'package:autouni_app/shared/widgets/cached_async_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../support/pump_router_app.dart';

class _MockRepository extends Mock implements EnergyRepository {}

const _building = EnergyScope(
  level: EnergyLevel.building,
  id: 'b1',
  name: 'Bloco A',
);

EnergyOverview _overview(
  EnergyScope scope,
  EnergyPeriod period, {
  EnergyStats stats = const EnergyStats(
    totalKwh: 48.5,
    readingCount: 120,
    totalDevices: 40,
    activeDevices: 12,
  ),
  List<EnergyHistoryPoint>? history,
  List<EnergyRankingItem>? ranking = const [
    EnergyRankingItem(id: 'b1', name: 'Bloco A', totalKwh: 10),
    EnergyRankingItem(id: 'b2', name: 'Bloco B', totalKwh: 30),
  ],
}) => EnergyOverview(
  scope: scope,
  period: period,
  stats: stats,
  history:
      history ??
      [
        EnergyHistoryPoint(bucket: DateTime(2026, 10, 21, 8), totalKwh: 2),
        EnergyHistoryPoint(bucket: DateTime(2026, 10, 21, 9), totalKwh: 4),
        EnergyHistoryPoint(bucket: DateTime(2026, 10, 21, 10), totalKwh: 1.5),
      ],
  ranking: ranking,
);

void main() {
  late _MockRepository repository;

  setUpAll(() {
    registerFallbackValue(const EnergyScope.campus());
    registerFallbackValue(EnergyPeriod.today);
  });

  setUp(() {
    repository = _MockRepository();
    when(() => repository.watchOverview(any(), any())).thenAnswer(
      (invocation) => Stream.value(
        Cached(
          _overview(
            invocation.positionalArguments[0] as EnergyScope,
            invocation.positionalArguments[1] as EnergyPeriod,
          ),
        ),
      ),
    );
  });

  Future<GoRouter> pumpEnergy(
    WidgetTester tester, {
    String location = '/energy',
  }) async {
    tester.view.physicalSize = const Size(800, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final (_, router) = await tester.pumpRouterApp(
      initialLocation: location,
      routes: energyRoutes(),
      overrides: [energyRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pumpAndSettle();
    return router;
  }

  String kpi(WidgetTester tester, String label) =>
      tester.widget<KpiCard>(find.widgetWithText(KpiCard, label)).value;

  testWidgets('campus: KPIs, histórico, gauge e ranking ordenado', (
    tester,
  ) async {
    await pumpEnergy(tester);

    expect(find.text('Campus'), findsWidgets);
    expect(kpi(tester, 'Consumo (hoje)'), '48,5 kWh');
    expect(kpi(tester, 'Potência agora'), '1,50 kW');
    expect(kpi(tester, 'Pico do período'), '4,00 kW');
    expect(kpi(tester, 'Dispositivos ligados'), '12/40');
    expect(find.text('Consumo por hora (kWh)'), findsOneWidget);
    expect(find.text('Prédios que mais consomem'), findsOneWidget);
    expect(find.byKey(const Key('energy-campus')), findsNothing);

    final rankingTop = tester.getTopLeft(
      find.byKey(const ValueKey('ranking-b2')),
    );
    final rankingSecond = tester.getTopLeft(
      find.byKey(const ValueKey('ranking-b1')),
    );
    expect(rankingTop.dy, lessThan(rankingSecond.dy));
    verify(
      () => repository.watchOverview(
        const EnergyScope.campus(),
        EnergyPeriod.today,
      ),
    ).called(1);
  });

  testWidgets('trocar o período recarrega com o novo período', (tester) async {
    await pumpEnergy(tester);

    await tester.tap(find.text('7 dias'));
    await tester.pumpAndSettle();

    verify(
      () => repository.watchOverview(
        const EnergyScope.campus(),
        EnergyPeriod.week,
      ),
    ).called(1);
    expect(kpi(tester, 'Consumo (7 dias)'), '48,5 kWh');
    expect(find.text('Consumo por dia (kWh)'), findsOneWidget);
  });

  testWidgets('tocar no ranking desce um nível e voltar sobe', (tester) async {
    final router = await pumpEnergy(tester);

    await tester.tap(find.byKey(const ValueKey('ranking-b1')));
    await tester.pumpAndSettle();

    expect(router.state.uri.queryParameters, {
      'level': 'building',
      'id': 'b1',
      'name': 'Bloco A',
    });
    expect(find.byKey(const Key('energy-scope-name')), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('energy-scope-name'))).data,
      'Bloco A',
    );
    expect(find.text('Andares que mais consomem'), findsOneWidget);
    verify(() => repository.watchOverview(_building, EnergyPeriod.today))
        .called(1);

    router.pop();
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const Key('energy-scope-name'))).data,
      'Campus',
    );
  });

  testWidgets('o período escolhido vale também no nível de baixo', (
    tester,
  ) async {
    await pumpEnergy(tester);
    await tester.tap(find.text('Mês'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ranking-b1')));
    await tester.pumpAndSettle();

    verify(() => repository.watchOverview(_building, EnergyPeriod.month))
        .called(1);
  });

  testWidgets('escopo por nível mostra média por leitura e atalho ao campus', (
    tester,
  ) async {
    when(() => repository.watchOverview(_building, any())).thenAnswer(
      (_) => Stream.value(
        Cached(
          _overview(
            _building,
            EnergyPeriod.today,
            stats: const EnergyStats(
              totalKwh: 12,
              readingCount: 30,
              avgWh: 400,
            ),
          ),
        ),
      ),
    );
    final router = await pumpEnergy(
      tester,
      location: AppPaths.energy(_building.toQuery()),
    );

    expect(find.text('Prédio'), findsOneWidget);
    expect(kpi(tester, 'Média por leitura'), '400 Wh');
    expect(find.widgetWithText(KpiCard, 'Dispositivos ligados'), findsNothing);

    await tester.tap(find.byKey(const Key('energy-campus')));
    await tester.pumpAndSettle();

    expect(router.state.uri.toString(), '/energy');
  });

  testWidgets('dispositivo (folha) não tem ranking', (tester) async {
    const device = EnergyScope(
      level: EnergyLevel.device,
      id: 'd1',
      name: 'Ar 101',
    );
    when(() => repository.watchOverview(device, any())).thenAnswer(
      (_) => Stream.value(
        Cached(_overview(device, EnergyPeriod.today, ranking: null)),
      ),
    );

    await pumpEnergy(tester, location: AppPaths.energy(device.toQuery()));

    expect(find.textContaining('que mais consomem'), findsNothing);
    expect(find.text('Ar 101'), findsOneWidget);
  });

  testWidgets('ranking indisponível não derruba a tela', (tester) async {
    when(() => repository.watchOverview(const EnergyScope.campus(), any()))
        .thenAnswer(
          (_) => Stream.value(
            Cached(
              _overview(
                const EnergyScope.campus(),
                EnergyPeriod.today,
                ranking: null,
              ),
            ),
          ),
        );

    await pumpEnergy(tester);

    expect(find.text('Ranking indisponível no momento.'), findsOneWidget);
  });

  testWidgets('sem leituras no período: estado vazio', (tester) async {
    when(() => repository.watchOverview(any(), any())).thenAnswer(
      (_) => Stream.value(
        Cached(
          _overview(
            const EnergyScope.campus(),
            EnergyPeriod.today,
            stats: const EnergyStats(),
            history: const [],
          ),
        ),
      ),
    );

    await pumpEnergy(tester);

    expect(find.text('Sem consumo registrado'), findsOneWidget);
  });

  testWidgets('carregando mostra o esqueleto', (tester) async {
    final controller = StreamController<Cached<EnergyOverview>>();
    addTearDown(controller.close);
    when(() => repository.watchOverview(any(), any()))
        .thenAnswer((_) => controller.stream);

    await tester.pumpRouterApp(
      initialLocation: '/energy',
      routes: energyRoutes(),
      overrides: [energyRepositoryProvider.overrideWithValue(repository)],
    );

    expect(find.bySemanticsLabel('Carregando'), findsOneWidget);
  });

  testWidgets('erro sem cache: mensagem e tentar de novo', (tester) async {
    var calls = 0;
    when(() => repository.watchOverview(any(), any())).thenAnswer((_) {
      calls++;
      return calls == 1
          ? Stream.error(const NetworkException())
          : Stream.value(
              Cached(_overview(const EnergyScope.campus(), EnergyPeriod.today)),
            );
    });

    await pumpEnergy(tester);
    expect(find.text('Sem conexão com a internet.'), findsOneWidget);

    await tester.tap(find.text('Tentar de novo'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(KpiCard, 'Potência agora'), findsOneWidget);
  });

  testWidgets('offline com cache: banner de dados salvos', (tester) async {
    when(() => repository.watchOverview(any(), any())).thenAnswer(
      (_) => Stream.value(
        Cached(
          _overview(const EnergyScope.campus(), EnergyPeriod.today),
          savedAt: DateTime(2026, 10, 21, 9, 5),
          offline: true,
        ),
      ),
    );

    await pumpEnergy(tester);

    expect(find.byType(StaleDataBanner), findsOneWidget);
    expect(find.byType(EnergyPage), findsOneWidget);
  });
}
