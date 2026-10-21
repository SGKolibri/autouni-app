# Estrutura do `lib/` — arquitetura feature-first

```
lib/
├── main.dart            # entrypoint padrão (FLAVOR via --dart-define, fallback dev)
├── main_dev.dart        # entrypoint de desenvolvimento
├── main_prod.dart       # entrypoint de produção
├── bootstrap.dart       # ProviderScope raiz com as implementações de produção + runApp
├── app.dart             # AutoUniApp (MaterialApp.router + tema + tempo real/ciclo de vida)
├── routing/             # monta o GoRouter com as telas das features + guard de sessão
│
├── core/                # infraestrutura transversal, sem regra de negócio
│   ├── biometrics/      # abstração da biometria (local_auth)
│   ├── cache/           # cache local (Hive) + leitura "cache primeiro, depois rede"
│   ├── config/          # flavors, AppConfig, providers de config, política de retry
│   ├── network/         # dio + interceptors (JWT, refresh, erro), helpers JSON
│   ├── realtime/        # cliente WebSocket (socket_io)
│   ├── router/          # shell com bottom nav (5 abas), guard de sessão, caminhos
│   └── session/         # eventos de sessão (expiração) da rede para a autenticação
│
├── features/            # uma pasta por módulo do produto
│   ├── auth/            # login, biometria, recuperação de senha, logout, ajustes da conta
│   ├── dashboard/       # aba Início: KPIs, status, prédios, alertas recentes
│   ├── environments/    # Prédios → Andares → Salas → detalhe da sala
│   ├── devices/         # lista global (busca, filtros, scroll infinito)
│   ├── energy/          # consumo por período e nível: KPIs, histórico, potência, ranking
│   └── automations/     # lista, toggle, executar, histórico, criar/editar (agenda → cron), excluir
│
└── shared/              # usado por mais de uma feature
    ├── design_system/   # tokens, tema e componentes (inclui estados vazio/erro/skeleton)
    ├── devices/         # controle de dispositivos: estado ao vivo, comandos, widgets
    ├── models/          # UserRole, NotificationType, Building/Floor/Room/Device
    ├── rbac/            # permissões por papel + PermissionGate
    ├── realtime/        # eventos device:status / device:online
    ├── utils/           # formatação pt-BR, mensagens de erro
    └── widgets/         # banners de tempo real/offline, top bar ao vivo, CachedAsyncView
```

Regras:
- `features/` nunca importa de outra `features/`; o que é compartilhado sobe para `shared/` ou `core/`.
- `core/` e `shared/` não importam de `features/`. Quando o `shared/` precisa
  de algo da sessão (ex.: o papel do usuário para o RBAC), o bootstrap faz o
  override do provider.
- Só `routing/`, `app.dart` e `bootstrap.dart` juntam features (telas nas rotas,
  overrides de produção).
- Configuração de ambiente só via `AppConfig` / `appConfigProvider` — nada de `String.fromEnvironment` espalhado.
