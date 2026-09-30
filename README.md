# AutoUni Mobile

App Flutter do AutoUni: monitoramento e controle dos dispositivos do campus.
Plano de entrega em [`ROADMAP.md`](ROADMAP.md) e estrutura do código em
[`lib/README.md`](lib/README.md).

## Rodando

Flutter **3.47.0** (a mesma versão fixada na CI).

```bash
flutter pub get
flutter run -t lib/main_dev.dart     # desenvolvimento
flutter run -t lib/main_prod.dart    # produção
```

Endpoints podem ser sobrescritos em build:
`--dart-define=API_BASE_URL=... --dart-define=WS_BASE_URL=...`.

## Testes e qualidade

```bash
./tool/check.sh                      # tudo que a CI checa: format, analyze, testes, cobertura
flutter test                         # só os testes
flutter test --update-goldens        # regenera goldens (só para mudança visual intencional)
```

O gate de cobertura (`tool/coverage.dart`) conta **todo** o `lib/`: arquivos sem
nenhum teste entram como 0%. O limiar é 80%.

Critérios de pronto e de entrada de tasks:
[`docs/definition_of_ready_and_done.md`](docs/definition_of_ready_and_done.md).

## Fluxo de branches

Cada task nasce da sua **branch de camada** (`core_infra`, `apresentacao`,
`dados`, `dominio`) e volta para ela por PR. As camadas são integradas em
`develop`.
