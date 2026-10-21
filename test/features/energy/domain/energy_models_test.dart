import 'package:autouni_app/core/router/app_paths.dart';
import 'package:autouni_app/features/energy/domain/energy_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EnergyPeriod', () {
    final now = DateTime(2026, 10, 21, 14, 30);

    test('início local de cada período (mesma regra do backend)', () {
      expect(EnergyPeriod.today.startOf(now), DateTime(2026, 10, 21));
      expect(EnergyPeriod.week.startOf(now), DateTime(2026, 10, 15));
      expect(EnergyPeriod.month.startOf(now), DateTime(2026, 10));
    });

    test('semana atravessando a virada do mês', () {
      expect(
        EnergyPeriod.week.startOf(DateTime(2026, 11, 2, 8)),
        DateTime(2026, 10, 27),
      );
    });

    test('hoje usa buckets de 1 h; semana e mês, de 24 h', () {
      expect(EnergyPeriod.today.bucketHours, 1);
      expect(EnergyPeriod.week.bucketHours, 24);
      expect(EnergyPeriod.month.bucketHours, 24);
    });

    test('valores da API e rótulos', () {
      expect(EnergyPeriod.values.map((p) => p.apiValue), [
        'today',
        'week',
        'month',
      ]);
      expect(EnergyPeriod.fromApi('week'), EnergyPeriod.week);
      expect(EnergyPeriod.fromApi('???'), EnergyPeriod.today);
      expect(EnergyPeriod.fromApi(null), EnergyPeriod.today);
    });
  });

  group('EnergyLevel', () {
    test('cada nível compara o nível de baixo; dispositivo é a folha', () {
      expect(EnergyLevel.general.child, EnergyLevel.building);
      expect(EnergyLevel.building.child, EnergyLevel.floor);
      expect(EnergyLevel.floor.child, EnergyLevel.room);
      expect(EnergyLevel.room.child, EnergyLevel.device);
      expect(EnergyLevel.device.child, isNull);
    });

    test('rótulo do ranking', () {
      expect(EnergyLevel.general.rankingTitle, 'Prédios que mais consomem');
      expect(EnergyLevel.building.rankingTitle, 'Andares que mais consomem');
      expect(EnergyLevel.floor.rankingTitle, 'Salas que mais consomem');
      expect(EnergyLevel.room.rankingTitle, 'Dispositivos que mais consomem');
      expect(EnergyLevel.device.rankingTitle, isNull);
    });
  });

  group('EnergyScope', () {
    test('campus é o escopo padrão', () {
      const scope = EnergyScope.campus();

      expect(scope.level, EnergyLevel.general);
      expect(scope.id, isNull);
      expect(scope.name, 'Campus');
    });

    test('ida e volta pela query da URL', () {
      const scope = EnergyScope(
        level: EnergyLevel.building,
        id: 'b1',
        name: 'Bloco A',
      );

      expect(scope.toQuery(), {
        'level': 'building',
        'id': 'b1',
        'name': 'Bloco A',
      });
      expect(EnergyScope.fromQuery(scope.toQuery()), scope);
    });

    test('lê o link montado pelas outras telas (AppPaths.energyOf)', () {
      final uri = Uri.parse(
        AppPaths.energyOf(level: 'floor', id: 'f1', name: '2º andar'),
      );

      expect(
        EnergyScope.fromQuery(uri.queryParameters),
        const EnergyScope(level: EnergyLevel.floor, id: 'f1', name: '2º andar'),
      );
    });

    test('query sem nível, sem id ou com nível desconhecido cai no campus', () {
      expect(EnergyScope.fromQuery(const {}), const EnergyScope.campus());
      expect(
        EnergyScope.fromQuery(const {'level': 'room'}),
        const EnergyScope.campus(),
      );
      expect(
        EnergyScope.fromQuery(const {'level': 'x', 'id': 'a'}),
        const EnergyScope.campus(),
      );
    });

    test('sem nome na query usa o nome do nível', () {
      expect(
        EnergyScope.fromQuery(const {'level': 'room', 'id': 'r1'}).name,
        'Sala',
      );
    });

    test('igualdade por valor (chave de provider family)', () {
      const a = EnergyScope(level: EnergyLevel.room, id: 'r1', name: 'A');
      const b = EnergyScope(level: EnergyLevel.room, id: 'r1', name: 'A');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a == const EnergyScope.campus(), isFalse);
    });

    test('escopo filho a partir de um item do ranking', () {
      const campus = EnergyScope.campus();
      const item = EnergyRankingItem(id: 'b1', name: 'Bloco A', totalKwh: 3);

      expect(
        campus.childFor(item),
        const EnergyScope(
          level: EnergyLevel.building,
          id: 'b1',
          name: 'Bloco A',
        ),
      );
      expect(
        const EnergyScope(
          level: EnergyLevel.device,
          id: 'd1',
          name: 'x',
        ).childFor(item),
        isNull,
      );
    });
  });

  group('EnergyStats.fromJson', () {
    test('geral: total do snapshot, leituras e dispositivos ativos', () {
      final stats = EnergyStats.fromJson(const {
        'totalKwh': 48.5,
        'count': 120,
        'readingCount': 120,
        'avgWh': 250.0,
        'maxWh': 1500,
        'minWh': 1,
        'totalDevices': 40,
        'activeDevices': 12,
        'hasData': true,
      });

      expect(stats.totalKwh, 48.5);
      expect(stats.readingCount, 120);
      expect(stats.avgWh, 250);
      expect(stats.maxWh, 1500);
      expect(stats.totalDevices, 40);
      expect(stats.activeDevices, 12);
      expect(stats.hasData, isTrue);
    });

    test('por nível: só agregação, sem contagem de dispositivos', () {
      final stats = EnergyStats.fromJson(const {'totalKwh': 0, 'count': 0});

      expect(stats.totalKwh, 0);
      expect(stats.readingCount, 0);
      expect(stats.avgWh, isNull);
      expect(stats.totalDevices, isNull);
      expect(stats.hasData, isFalse);
    });

    test('hasData ausente: deduz das leituras', () {
      expect(
        EnergyStats.fromJson(const {'totalKwh': 1.2, 'count': 3}).hasData,
        isTrue,
      );
    });
  });

  group('EnergyHistoryPoint', () {
    test('lê o bucket e calcula a potência média em kW', () {
      final point = EnergyHistoryPoint.fromJson(const {
        'bucket': '2026-10-21T13:00:00.000Z',
        'totalKwh': 3.0,
        'count': 12,
      });

      expect(point.bucket, DateTime.utc(2026, 10, 21, 13));
      expect(point.totalKwh, 3);
      expect(point.averageKw(bucketHours: 1), 3);
      expect(point.averageKw(bucketHours: 24), closeTo(0.125, 1e-9));
    });
  });

  group('EnergyRankingItem', () {
    test('traduz o nome padrão de andar sem nome do backend', () {
      expect(
        EnergyRankingItem.fromJson(const {
          'id': 'f1',
          'name': 'Floor 2',
          'totalKwh': 1,
        }).name,
        '2º andar',
      );
      expect(
        EnergyRankingItem.fromJson(const {
          'id': 'f0',
          'name': 'Floor 0',
          'totalKwh': 1,
        }).name,
        'Térreo',
      );
      expect(
        EnergyRankingItem.fromJson(const {
          'id': 'r1',
          'name': 'Lab Floor 3',
          'totalKwh': 1,
        }).name,
        'Lab Floor 3',
      );
    });
  });

  group('EnergyOverview', () {
    EnergyOverview overview({
      List<EnergyHistoryPoint> history = const [],
      List<EnergyRankingItem>? ranking,
      EnergyPeriod period = EnergyPeriod.today,
    }) => EnergyOverview(
      scope: const EnergyScope.campus(),
      period: period,
      stats: const EnergyStats(totalKwh: 10, readingCount: 5),
      history: history,
      ranking: ranking,
    );

    EnergyHistoryPoint point(int hour, double kwh) => EnergyHistoryPoint(
      bucket: DateTime.utc(2026, 10, 21, hour),
      totalKwh: kwh,
    );

    test('potência atual = último bucket; pico = maior bucket', () {
      final data = overview(
        history: [point(10, 2), point(11, 5), point(12, 3)],
      );

      expect(data.currentKw, 3);
      expect(data.peakKw, 5);
    });

    test('semana: potência média do dia (kWh / 24 h)', () {
      final data = overview(
        period: EnergyPeriod.week,
        history: [point(0, 48), point(1, 24)],
      );

      expect(data.currentKw, 1);
      expect(data.peakKw, 2);
    });

    test('sem histórico, sem potência', () {
      final data = overview();

      expect(data.currentKw, isNull);
      expect(data.peakKw, isNull);
    });

    test('ranking ordenado do maior para o menor consumo', () {
      final data = overview(
        ranking: const [
          EnergyRankingItem(id: 'a', name: 'A', totalKwh: 1),
          EnergyRankingItem(id: 'b', name: 'B', totalKwh: 9),
          EnergyRankingItem(id: 'c', name: 'C', totalKwh: 4),
        ],
      );

      expect(data.sortedRanking.map((i) => i.id), ['b', 'c', 'a']);
    });
  });
}
