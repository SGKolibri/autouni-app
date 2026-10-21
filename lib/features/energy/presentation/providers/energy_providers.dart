import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/cache/cached.dart';
import '../../data/energy_repository.dart';
import '../../domain/energy_models.dart';

/// Período escolhido na tela de energia. Compartilhado entre os níveis:
/// descer no ranking mantém o período.
class EnergyPeriodNotifier extends Notifier<EnergyPeriod> {
  @override
  EnergyPeriod build() => EnergyPeriod.today;

  void select(EnergyPeriod period) => state = period;
}

final energyPeriodProvider =
    NotifierProvider<EnergyPeriodNotifier, EnergyPeriod>(
      EnergyPeriodNotifier.new,
      name: 'energyPeriodProvider',
    );

/// Consumo de um escopo em um período.
final energyOverviewProvider = StreamProvider.autoDispose
    .family<Cached<EnergyOverview>, (EnergyScope, EnergyPeriod)>(
      (ref, key) =>
          ref.watch(energyRepositoryProvider).watchOverview(key.$1, key.$2),
      name: 'energyOverviewProvider',
    );
