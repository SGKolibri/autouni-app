## Task

<!-- Ex.: S2-T2 — Login e-mail/senha. Branch da task → branch de camada. -->

## O que muda

<!-- Resumo curto. Para UI, anexe print/gif. -->

## Como testar

<!-- Comandos ou passos. `./tool/check.sh` roda os mesmos gates da CI. -->

## Definition of Done

Detalhes em [`docs/definition_of_ready_and_done.md`](../docs/definition_of_ready_and_done.md).
Format, analyze, testes e cobertura ≥ 80% são checados pela CI.

- [ ] Testes escritos antes da implementação (red → green → refactor)
- [ ] Estados cobertos: carregando / vazio / erro / offline-ws (ou não se aplica)
- [ ] RBAC verificado: VIEWER somente leitura (ou não se aplica)
- [ ] Sem segredos hardcoded
- [ ] Goldens alterados só por mudança visual intencional, conferida com o handoff (ou não se aplica)
- [ ] PR mirando a branch de camada correta
