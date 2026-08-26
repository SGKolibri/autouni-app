# Roadmap de Desenvolvimento — AutoUni Mobile

**Abordagem:** Scrum + Test-Driven Development (TDD)
**Stack:** Flutter (Riverpod, dio, socket_io_client, flutter_secure_storage, hive/drift, firebase_messaging, go_router, freezed, fl_chart, local_auth)
**Pré-requisitos concluídos:** PRD, design fase 1 (loop P0) e fase 2 (telas secundárias) — handoffs do Claude Design finalizados.

---

## 1. Visão geral da abordagem

Dois princípios guiam a ordem do trabalho:

1. **Fundações primeiro.** A Sprint 1 entrega arquitetura, camada core (rede, WebSocket, storage), biblioteca de componentes e o harness de testes + CI. Sem isso, TDD nas features vira improviso.
2. **Fatias verticais por prioridade.** Cada sprint seguinte entrega uma feature ponta-a-ponta (modelo → dados → estado → UI → testes), começando pelo núcleo P0 (auth, navegação, controle de dispositivos) e avançando para as telas secundárias.

**Cadência sugerida:** sprints de 2 semanas, com planning, daily, review e retrospectiva. Papéis: Product Owner, Scrum Master e time de desenvolvimento (adaptável ao tamanho da equipe acadêmica).

---

## 2. Módulos do sistema (arquitetura feature-first)

| Módulo | Responsabilidade |
|--------|------------------|
| **core** | Config/flavors, cliente HTTP (dio + interceptors), cliente WebSocket, armazenamento seguro, roteador, tema, tratamento de erro |
| **shared** | Biblioteca de componentes (design system), modelos e utilitários comuns |
| **auth** | Login, refresh, biometria, RBAC, sessão |
| **dashboard** | KPIs e visão geral em tempo real |
| **environments** | Drill-down Prédios → Andares → Salas → Dispositivos |
| **devices** | Controle (toggle, massa, dimmer, termostato), lista global |
| **energy** | Monitoramento energético (subconjunto mobile) |
| **automations** | CRUD de automações + execução/histórico |
| **notifications** | Central de notificações + push (FCM) |
| **reports** | Gerar, listar e baixar relatórios |
| **settings** | Perfil, preferências, aparência, segurança |
| **[backend] fcm** | Registro de device token + disparo FCM (única alteração no backend) |

---

## 3. Estratégia de TDD

Ciclo **red → green → refactor** em cada task: escreve-se o teste que falha antes da implementação.

| Camada | Tipo de teste | Ferramenta |
|--------|---------------|-----------|
| Lógica / mappers / providers | Unit | flutter_test + mocktail, ProviderContainer |
| Repositórios / serviços | Unit com HTTP/ws mockados | mocktail |
| Modelos (freezed) | (De)serialização | flutter_test |
| Telas / componentes | Widget | flutter_test |
| Design system | Golden (trava consistência visual com o handoff) | golden_toolkit |
| Fluxos críticos | Integração e2e | integration_test |
| Backend FCM | Unit + e2e | Jest |

Alvos naturais de teste puro: interceptor de refresh de token, mapeamento **agenda→cron** das automações, atualização otimista do toggle de dispositivo, regras de RBAC.

---

## 4. Definition of Ready / Definition of Done

**Ready (para entrar na sprint):** critérios de aceite claros; design disponível no handoff; endpoint/contrato conhecido; dependências resolvidas.

**Done (para fechar a task):**
- Testes escritos antes da implementação (red-green-refactor) e todos verdes na CI.
- Cobertura acima do limiar definido (ex.: ≥80% nas camadas de domínio/dados).
- `flutter analyze` e `dart format` limpos.
- Code review aprovado.
- Estados cobertos (carregando, vazio, erro, offline/ws-desconectado) quando aplicável.
- RBAC verificado quando aplicável (VIEWER somente leitura).
- Sem segredos hardcoded.

---

## 5. Sprints

### Sprint 1 — Fundações, arquitetura e design system
*Objetivo: base técnica e de testes que sustenta todo o resto.*
- **S1-T1** — Bootstrap do projeto Flutter, estrutura feature-first (core/features/shared), dependências e flavors dev/prod.
- **S1-T2** — Camada core de rede: dio com interceptors (JWT, refresh automático, erro). *(TDD: unit dos interceptors com dio mockado.)*
- **S1-T3** — Cliente WebSocket (socket_io_client) autenticado por JWT, reconexão e ciclo de vida background/foreground. *(TDD: handler de reconexão com socket mockado.)*
- **S1-T4** — Biblioteca de componentes do design system a partir do handoff (tokens, KPI card, device row, badges, bottom nav, app bar, banners). *(TDD: golden de cada componente.)*
- **S1-T5** — Shell de navegação com go_router (bottom nav 5 abas) e rotas placeholder. *(TDD: widget test de troca de abas.)*
- **S1-T6** — Harness de testes + CI (GitHub Actions: analyze + format + testes + cobertura com threshold); definir DoR/DoD.

### Sprint 2 — Autenticação, sessão e RBAC
*Objetivo: entrar no app com segurança e respeitar papéis.*
- **S2-T1** — Modelos User/Tokens/enum de papéis (freezed). *(TDD: (de)serialização.)*
- **S2-T2** — Login e-mail/senha (POST /auth/login, GET /auth/me) — repo + provider. *(TDD: sucesso/erro com dio mockado.)*
- **S2-T3** — Refresh automático + armazenamento seguro (flutter_secure_storage, POST /auth/refresh). *(TDD: renova em 401 e repete a request.)*
- **S2-T4** — Login por biometria (local_auth) após primeiro acesso. *(TDD: fluxo com biometria mockada.)*
- **S2-T5** — Recuperação de senha (POST /auth/forgot-password).
- **S2-T6** — RBAC (guard de rotas + gating de UI; VIEWER somente leitura) e logout (limpa tokens + encerra ws). *(TDD: ações não renderizam para VIEWER.)*

### Sprint 3 — Navegação hierárquica, Dashboard e tempo real
*Objetivo: ver o estado do campus em tempo real e navegar a hierarquia.*
- **S3-T1** — Modelos Building/Floor/Room/Device + enums (tipos e status). *(TDD: serialização + enums.)*
- **S3-T2** — Dashboard: KPIs, donut de status, lista de prédios, alertas recentes. *(TDD: provider mockado + widget dos KPIs.)*
- **S3-T3** — Drill-down Prédios→Andares→Salas→Dispositivos (GET /buildings, /:id, /floors/:id, /rooms/:id). *(TDD: pilha de navegação preserva o caminho completo — corrige o breadcrumb.)*
- **S3-T4** — Tempo real (device.status, device.online) atualizando dashboard/listas. *(TDD: eventos mockados atualizam o estado.)*
- **S3-T5** — Cache local (hive/drift) do último estado para abertura rápida/offline. *(TDD: leitura sem rede.)*
- **S3-T6** — Estados transversais: skeleton, vazio, erro, banner de ws-desconectado. *(TDD: widget de cada estado.)*

### Sprint 4 — Controle de dispositivos (núcleo P0)
*Objetivo: o "coração" — controlar dispositivos de qualquer lugar.*
- **S4-T1** — Detalhe da sala: KPIs + lista de dispositivos (GET /rooms/:id).
- **S4-T2** — Toggle individual com estado otimista + confirmação por ws (POST /devices/:id/control). *(TDD: update otimista e rollback em erro.)*
- **S4-T3** — "Desligar Todos" em massa (POST /devices/bulk-control) + confirmação. *(TDD: confirmação e chamada correta.)*
- **S4-T4** — Controle contextual: dimmer 0–100% (LIGHT), termostato 16–30 °C (AC). *(TDD: validação de limites.)*
- **S4-T5** — Lista global de dispositivos (GET /devices): busca, filtros (bottom sheet), scroll infinito (977 itens). *(TDD: filtro/paginação mockados.)*
- **S4-T6** — Tratamento de dispositivo offline (controle indisponível). *(TDD: offline desabilita ação.)*

### Sprint 5 — Energia, Automações (CRUD) e Backend FCM
*Objetivo: ferramentas de análise e automação; preparar a base do push.*
- **S5-T1** — Energia: seletor de período/nível + KPIs (GET /energy/.../stats). *(TDD: provider por nível/período.)*
- **S5-T2** — Energia: histórico (linha), gauge de potência, ranking (fl_chart). *(TDD: golden dos gráficos + mapeamento.)*
- **S5-T3** — Automações: lista + toggle (PATCH /:id/toggle) + executar (POST /:id/execute) + histórico (GET /:id/history). *(TDD: ações com repo mockado.)*
- **S5-T4** — Automações: formulário criar/editar (POST/PUT) com construtor de agenda (dias+horário → cron) + cron avançado + validações. *(TDD: unit puro do mapeamento agenda→cron.)*
- **S5-T5** — Automações: excluir (DELETE) + confirmações.
- **S5-T6 [Backend]** — FCM: endpoint de registro de device token por usuário + disparo FCM ao criar notificação. *(TDD: Jest unit/e2e.)* **Deve concluir antes do push da Sprint 6.**

### Sprint 6 — Notificações + Push, Relatórios, Configurações e release
*Objetivo: fechar o escopo e endurecer para release.*
- **S6-T1** — Registro do device token no app (firebase_messaging) + fluxo de permissão de push no momento certo. *(TDD: fluxo com plugin mockado.)*
- **S6-T2** — Central de notificações: lista por tipo (INFO/WARNING/ERROR/SUCCESS), lido/não-lido, deep link p/ dispositivo/sala. *(TDD: widget + navegação por deep link.)*
- **S6-T3** — Relatórios: tipos + gerar (tipo/período/localização/formato) + lista com status (PENDING/PROCESSING/COMPLETED/FAILED). *(TDD: estados de status.)*
- **S6-T4** — Relatórios: download/abertura via share sheet/visualizador (PDF/CSV/XLSX). *(TDD: share com arquivo mockado.)*
- **S6-T5** — Configurações/perfil: perfil, preferências de push, tema, idioma, biometria, trocar senha, logout. *(TDD: preferências persistem.)*
- **S6-T6** — Hardening & release: integração e2e dos fluxos críticos (login, controlar dispositivo, push→deep link), acessibilidade, build iOS/Android, revisão de cobertura. *(TDD: integration_test end-to-end.)*

---

## 6. Dependências e sequenciamento

- **Sprint 1 bloqueia tudo:** camada core + harness de testes são pré-requisito do TDD nas features.
- **Auth (S2) antes de qualquer tela autenticada** (S3+).
- **Modelos e tempo real (S3) antes do controle (S4)**, que reusa Device e eventos ws.
- **FCM backend (S5-T6) antes do push app-side (S6-T1).** É a razão de o backend entrar na Sprint 5, mesmo sendo trilha paralela — dá folga para o time de backend enquanto o mobile avança em energia/automações.
- **Release (S6-T6) por último**, consolidando integração e cobertura.

## 7. Riscos e mitigação

- **Construtor de agenda (cron):** parte mais propensa a erro; isolar o mapeamento agenda→cron como função pura testável (S5-T4).
- **Tempo real instável:** cache local (S3-T5) + banner de ws-desconectado garantem uso mesmo sem conexão estável.
- **Lista de 977 dispositivos:** paginação/scroll infinito desde o início (S4-T5) para não degradar performance.
- **Dependência de backend (FCM):** trilha paralela com prazo na Sprint 5; se atrasar, push escorrega para uma sprint de buffer sem travar o resto.
