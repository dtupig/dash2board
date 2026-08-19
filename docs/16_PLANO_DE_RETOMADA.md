# Plano de retomada — features após a auditoria

Ordem de execução das próximas frentes, com os bloqueios da auditoria fechados
antes das features. Cada passo tem um **portão**: só avance quando ele passar.

Estado atual: repositório publicado em `dtupig/dash2board`, tag
`v0.1.0-auditado`, prompts 2 a 9 executados, prompts 10 a 14 pendentes.

---

## Por que não começar direto no prompt 10

| Bloqueio | Consequência de ignorar |
|---|---|
| **A-03/A-04** — Firestore nunca exercitado, índices defasados | Prompts 10/11 criam consultas novas. Sem base real, o índice faltante só aparece na demo |
| **A-02** — nenhum teste de security rule | O prompt 12 reescreve `firestore.rules` inteiro. Sem teste, um erro de autorização passa silencioso |
| **Decisões pendentes** | O prompt 10 precisa do SLA de RFS; o 11 precisa dos modelos validados e do limite de fato relevante. Sem eles, o agente inventa — e inventar em relatório de segurança é caro de desfazer |
| **CI não ativa** | As regras do `CLAUDE.md` continuam dependendo de disciplina manual |

Fechar isso custa cerca de um dia. Ignorar custa uma refatoração.

---

## Fase A · Baseline e trilhos  *(hoje, ~1 h)*

| # | Passo | Portão |
|---|---|---|
| A1 | `./scripts/audit.sh` | `analyze` limpo e `test` verde. **Se falhar, para tudo aqui** |
| A2 | Criar `.github/` com `ci.yaml` e template de PR, comitar e empurrar | Actions verde nos jobs `flutter` e `guardrails` |
| A3 | Ruleset `protect-main` com os dois checks obrigatórios | PR direto no `main` bloqueado |
| A4 | Adotar branch por prompt | `git switch -c prompt/10-catalogo` funciona |

## Fase B · Decisões que destravam  *(você + equipe)*

Detalhe em `docs/13_DECISOES_PENDENTES.md`. O mínimo por prompt:

| Prompt | Decisões necessárias |
|---|---|
| 10 | **D-30** SLA de resposta a RFS |
| 11 | **D-27** modelos validados pelas disciplinas · **D-29** limite de fato relevante como % da receita |
| 12 | **D-18** um build ou dois flavors |
| 13 | **D-05/06/07** custódia: o app guarda evidência? prazos? `legalHold`? |
| 14 | **D-12** Blaze · **D-13** retenção de `audit_logs` |

D-30 sai em dois minutos. D-27 é a que exige agenda: uma hora com pentest,
forense e GRC revisando os 8 modelos. É o item de maior risco de retrabalho do
projeto inteiro.

## Fase C · Fundação Firestore real  *(fecha A-03 e A-04)*

| # | Passo | Portão |
|---|---|---|
| C1 | `flutterfire configure` no projeto real | `firebase_options.dart` sem `PLACEHOLDER` |
| C2 | `firebase emulators:start` + `npm --prefix scripts/seed run seed` | Seed conclui e imprime o resumo |
| C3 | `flutter run --dart-define=DATA_SOURCE=firestore` | Painel do CISO idêntico ao modo mock |
| C4 | Colher no console os índices faltantes e comitar | Nenhum aviso de índice em nenhuma tela |

O Firestore imprime no console o link exato para criar cada índice que falta.
É a forma correta de descobrir — não adivinhando.

## Fase D · Rede de segurança  *(fecha A-02)*

| # | Passo | Portão |
|---|---|---|
| D1 | `test/rules` com `@firebase/rules-unit-testing` | Caso positivo **e** negativo para cada regra; job `rules` verde |

Mínimo obrigatório: cliente do tenant A não lê nada de B; `board` não lê
`incidents` nem `compliance`; `operational` não lê `risks`; ninguém lê
`audit_logs`; cliente não escreve o próprio `role`.

## Fase E · Features

| # | Prompt | Depende de |
|---|---|---|
| E1 | `10_CATALOGO_E_WIZARD` | A, D-30 |
| E2 | `11_RELATORIOS_ESPECIALISTAS` | E1, D-27, D-29, C |
| E3 | `12_PERSONA_ESPECIALISTA_RETROFIT` | E2, **D1**, D-18 |
| E4 | `13_MODULO_AUTORIA_RELATORIOS` | E3, D-05/06/07 |
| E5 | `14_ESTRUTURA_DADOS_FIREBASE` | E4, D-12, D-13 |

---

## Ritual de execução de cada prompt

Sempre igual. É o que mantém a qualidade sem depender de memória.

```bash
# 1. branch próprio
git switch -c prompt/10-catalogo-servicos

# 2. rodar o prompt no Claude Code (cole o bloco ```text do arquivo)

# 3. portões locais
dart format lib test
flutter analyze          # precisa dar "No issues found!"
flutter test
./scripts/audit.sh       # confere as regras do CLAUDE.md

# 4. commit com convenção
git add -A
git commit -m "feat(servicos): catálogo dos 44 serviços e wizard de RFS"

# 5. publicar e abrir PR
git push -u origin HEAD
gh pr create --fill

# 6. só faça merge com a CI verde
```

**Se o prompt der errado:** `git switch main && git branch -D prompt/...`.
Nada se perde. Era exatamente isso que faltava antes do git.

### Convenção de mensagem

`tipo(escopo): resumo no imperativo` — tipos `feat`, `fix`, `refactor`, `test`,
`docs`, `chore`, `perf`, `sec`.

Use **`sec(...)`** para qualquer mudança em `firestore.rules`, política de
acesso ou classificação de relatório. Facilita auditar depois só o que mexeu em
segurança.

### Marcos com tag

```bash
git tag -a v0.2.0-catalogo -m "Catálogo de serviços e wizard de RFS"
git push --follow-tags
```

Uma tag por prompt concluído dá pontos de retorno granulares — e o prompt 12,
que reescreve autorização, merece um antes e um depois.
