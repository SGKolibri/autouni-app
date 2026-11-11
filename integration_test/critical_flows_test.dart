import 'package:integration_test/integration_test.dart';

import '../test/support/e2e/critical_flows.dart';

/// Fluxos críticos no emulador/aparelho, com o app inteiro contra o backend
/// em memória:
///
///     flutter test integration_test -d <aparelho>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  criticalFlows();
}
