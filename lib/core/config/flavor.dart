/// Ambientes de build do app.
///
/// O flavor é escolhido pelo entrypoint (`lib/main_dev.dart` / `lib/main_prod.dart`)
/// e carregado no [AppConfig] correspondente.
enum Flavor {
  dev('DEV'),
  prod('PROD');

  const Flavor(this.label);

  /// Rótulo curto usado na faixa de identificação do ambiente.
  final String label;

  bool get isDev => this == Flavor.dev;

  /// Resolve um flavor a partir de um nome (ex.: vindo de `--dart-define=FLAVOR=prod`).
  ///
  /// Nomes desconhecidos ou vazios caem em [fallback], para que um define
  /// errado nunca promova um build a produção por acidente.
  static Flavor fromName(String name, {Flavor fallback = Flavor.dev}) {
    final normalized = name.trim().toLowerCase();
    for (final flavor in Flavor.values) {
      if (flavor.name == normalized) return flavor;
    }
    return fallback;
  }
}
