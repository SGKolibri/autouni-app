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

### Push (FCM)

Sem configuração o push fica desligado e o resto do app funciona igual. Para
ligar, passe as credenciais públicas do app no Firebase (Console → Configurações
do projeto → Seus apps). Nada disso vai para o repositório:

```bash
flutter run -t lib/main_dev.dart \
  --dart-define=FIREBASE_API_KEY=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_ANDROID_APP_ID=... \
  --dart-define=FIREBASE_IOS_APP_ID=... \
  --dart-define=FIREBASE_IOS_BUNDLE_ID=...
```

Ou junte tudo em `firebase.env.json` (ignorado pelo git) e use
`--dart-define-from-file=firebase.env.json`. No iOS também é preciso a chave APNs no Firebase e a capability
*Push Notifications* no Xcode. O backend precisa das variáveis `FIREBASE_*`
(ver `docs/PUSH_FCM.md` no autouni-backend).

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
