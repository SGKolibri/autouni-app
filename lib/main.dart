import 'bootstrap.dart';
import 'core/config/flavor.dart';

/// Entrypoint padrão (usado por `flutter run` sem `-t`).
///
/// Resolve o ambiente por `--dart-define=FLAVOR=dev|prod`, caindo em
/// [Flavor.dev] quando ausente. Para builds explícitos prefira os entrypoints
/// dedicados `lib/main_dev.dart` e `lib/main_prod.dart`.
void main() {
  const flavorName = String.fromEnvironment('FLAVOR');
  runAutoUni(Flavor.fromName(flavorName));
}
