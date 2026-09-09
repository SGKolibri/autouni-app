import 'bootstrap.dart';
import 'core/config/flavor.dart';

/// Entrypoint de produção: `flutter run -t lib/main_prod.dart`.
void main() => runAutoUni(Flavor.prod);
