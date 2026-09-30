# Definition of Ready / Definition of Done — AutoUni Mobile

Critérios acordados para toda task do roadmap (`ROADMAP.md`). A DoD é
verificada no PR pelo checklist do template (`.github/pull_request_template.md`)
e, no que é automatizável, pela CI (`.github/workflows/main.yml`).

## Definition of Ready — a task pode entrar na sprint quando

- [ ] **Critérios de aceite claros**, escritos de forma testável (viram os primeiros testes).
- [ ] **Design disponível** no handoff do Claude Design, quando a task tem UI.
- [ ] **Contrato conhecido**: endpoint, payload, códigos de erro e eventos WebSocket envolvidos.
- [ ] **Dependências resolvidas**: tasks anteriores mergeadas na branch de camada (ver §6 do roadmap).
- [ ] **Camada e branch definidas**: branch de camada de origem e nome da branch da task.

## Definition of Done — a task só fecha quando

### Automático (a CI bloqueia o PR)
- [ ] `dart format` sem alterações (`lib/`, `test/`, `tool/`).
- [ ] `flutter analyze` sem nenhum issue.
- [ ] Todos os testes verdes, inclusive os goldens.
- [ ] Cobertura de linhas **≥ 80%** sobre todo o `lib/`. Arquivos sem nenhum teste
      contam como 0%. Ficam fora só o código gerado (`*.g.dart`, `*.freezed.dart`)
      e os entrypoints (`lib/main*.dart`).

### Revisão humana (checklist do PR)
- [ ] **TDD**: testes escritos antes da implementação (red → green → refactor).
- [ ] **Estados cobertos** quando aplicável: carregando, vazio, erro e offline/ws-desconectado.
- [ ] **RBAC verificado** quando aplicável: VIEWER é somente leitura, e as ações nem renderizam.
- [ ] **Sem segredos hardcoded**: URLs e chaves vêm da `AppConfig` / `--dart-define`.
- [ ] **Goldens** só são regenerados (`flutter test --update-goldens`) quando a mudança
      visual é intencional e está conferida com o handoff. O PNG novo entra no diff do PR.
- [ ] **Code review aprovado** e PR mirando a branch de camada correta.

## Como verificar localmente

```bash
./tool/check.sh     # mesmos gates da CI: format, analyze, testes, cobertura
```

## Tipos de teste por camada

| Camada | Tipo de teste | Ferramentas / helpers |
|--------|---------------|------------------------|
| Lógica, mappers, providers | Unit | `flutter_test`, `mocktail`, `ProviderContainer.test` |
| Repositórios / serviços | Unit com HTTP/ws falsos | `test/support/fake_http_adapter.dart`, `fake_realtime_socket.dart` |
| Modelos (freezed) | (De)serialização | `flutter_test` |
| Telas | Widget | `test/support/pump_app.dart` (`tester.pumpApp`) |
| Design system | Golden | `test/support/component_harness.dart` + `matchesGoldenFile` |
| Fluxos críticos | Integração e2e | `integration_test` (Sprint 6) |
