import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Alertas não lidos do usuário logado — badge da aba Alertas e KPI do
/// Início. `null` = ainda não se sabe (sem badge).
///
/// O core não conhece a central de notificações: o bootstrap sobrescreve
/// com a contagem da feature.
final unreadAlertsCountProvider = Provider<int?>(
  (ref) => null,
  name: 'unreadAlertsCountProvider',
);
