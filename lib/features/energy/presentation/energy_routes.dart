import 'package:go_router/go_router.dart';

import '../../../core/router/app_paths.dart';
import '../domain/energy_models.dart';
import 'pages/energy_page.dart';

/// Tela de energia, fora do shell de abas (`AppPaths.energy`). O escopo vem
/// da query; cada nível do ranking empilha uma nova tela.
List<RouteBase> energyRoutes() => [
  GoRoute(
    path: AppPaths.energyRoot,
    builder: (context, state) => EnergyPage(
      key: state.pageKey,
      scope: EnergyScope.fromQuery(state.uri.queryParameters),
    ),
  ),
];
