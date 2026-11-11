import '../support/e2e/critical_flows.dart';

/// Fluxos críticos rodando na VM (CI). Os mesmos rodam em aparelho por
/// `integration_test/critical_flows_test.dart`.
void main() => criticalFlows();
