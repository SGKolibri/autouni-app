import 'package:autouni_app/core/router/app_paths.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('hierarquia aninhada na URL', () {
    expect(AppPaths.building('b1'), '/environments/buildings/b1');
    expect(AppPaths.floor('b1', 'f1'), '/environments/buildings/b1/floors/f1');
    expect(
      AppPaths.room('b1', 'f1', 'r1'),
      '/environments/buildings/b1/floors/f1/rooms/r1',
    );
    expect(AppPaths.allDevices, '/environments/devices');
  });

  test('energia: campus sem query; escopo vai na query codificada', () {
    expect(AppPaths.energy(), '/energy');
    final uri = Uri.parse(
      AppPaths.energy({'level': 'building', 'id': 'b1', 'name': 'Bloco A & B'}),
    );
    expect(uri.path, '/energy');
    expect(uri.queryParameters, {
      'level': 'building',
      'id': 'b1',
      'name': 'Bloco A & B',
    });
  });

  test('energyOf monta o escopo de uma entidade', () {
    expect(
      Uri.parse(AppPaths.energyOf(level: 'room', id: 'r1', name: 'Sala 101'))
          .queryParameters,
      {'level': 'room', 'id': 'r1', 'name': 'Sala 101'},
    );
  });

  test('automações', () {
    expect(AppPaths.newAutomation, '/automations/new');
    expect(AppPaths.automation('a1'), '/automations/a1');
    expect(AppPaths.editAutomation('a1'), '/automations/a1/edit');
  });
}
