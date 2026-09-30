# Estrutura do `lib/` — arquitetura feature-first

```
lib/
├── main.dart            # entrypoint padrão (FLAVOR via --dart-define, fallback dev)
├── main_dev.dart        # entrypoint de desenvolvimento
├── main_prod.dart       # entrypoint de produção
├── bootstrap.dart       # monta o ProviderScope raiz + runApp
├── app.dart             # AutoUniApp (MaterialApp.router + tema + faixa de flavor)
│
├── core/                # infraestrutura transversal, sem regra de negócio
│   ├── config/          # flavors, AppConfig, providers de config
│   ├── network/         # dio + interceptors (JWT, refresh, erro)
│   ├── realtime/        # cliente WebSocket (socket_io)
│   └── router/          # go_router: shell com bottom nav (5 abas) + rotas
│
├── features/            # uma pasta por módulo do produto (auth, dashboard, ...)
│                        # cada feature: data/ · domain/ · presentation/
│
└── shared/              # design system (S1-T4), modelos e utilitários comuns
```

Regras:
- `features/` nunca importa de outra `features/`; o que é compartilhado sobe para `shared/` ou `core/`.
- `core/` e `shared/` não importam de `features/`.
- Configuração de ambiente só via `AppConfig` / `appConfigProvider` — nada de `String.fromEnvironment` espalhado.
