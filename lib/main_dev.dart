import 'bootstrap.dart';
import 'core/config/flavor.dart';

/// Entrypoint de desenvolvimento: `flutter run -t lib/main_dev.dart`.
Future<void> main() => runAutoUni(Flavor.dev);
