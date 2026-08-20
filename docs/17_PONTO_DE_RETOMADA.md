# Ponto de retomada — Elytron Dash2Board

Documento de handoff. Serve para abrir uma conversa nova de arquitetura sem
perder contexto, e para qualquer pessoa entender em cinco minutos onde o
projeto está e o que vem a seguir.

**Atualizado em:** 19/08/2026

---

## 1. Estado atual

### Repositório
| | |
|---|---|
| Remote | `git@github.com:dtupig/dash2board.git` (privado) |
| Branch padrão | `main`, protegido por ruleset `protect-main` |
| Fluxo | branch por prompt → PR → CI verde → squash merge |
| CI | 3 jobs: `Análise e testes Flutter`, `Regras inegociáveis do projeto`, `Testes das security rules` |
| Guardas locais | `pre-push` e `pre-commit` (`./scripts/hooks/install.sh`) |
| Tag de referência | `v0.1.0-auditado` |
| Chave SSH | `~/.ssh/id_ed25519_elytron`, amarrada por `core.sshCommand` |

### Qualidade
`flutter analyze` limpo · `flutter test` verde · zero violações reais das 12
regras do `CLAUDE.md` em 85 arquivos Dart · 18 arquivos de teste.

### Backend
| | |
|---|---|
| Projeto Firebase | `elytron-d2b-dev` (alias `default`) |
| Firestore | recriado em **`southamerica-east1`** (era `eur3`) |
| Plano (dev) | Spark — intencional (D-12): Functions/Storage/exportação exigem Blaze e só serão ativados no projeto de produção |
| Rules/índices | escritos no repositório, **nunca deployados** |
| `firebase_options.dart` | **ainda é placeholder** — o app só roda em `MOCK=true` |

### Como rodar hoje
```bash
flutter run --dart-define=MOCK=true
# contas: operacao@ / ciso@ / board@demo.elytron · senha com 12+ caracteres
```

---

## 2. O que já foi construído

**Prompts 1 a 9 executados.** Jornada de entrada completa (splash, boas-vindas,
login, roteamento por persona, acesso pendente); design system dark-first em
Material 3; kit de gráficos com paleta validada em OKLCH; módulo estratégico do
CISO (postura, tendência 12 meses, risco por domínio, compliance com
drill-down, insights, survey, briefing executivo em PDF); onboarding de
primeiro uso; modo de demonstração sem Firebase; security rules, índices,
5 Cloud Functions e seed determinístico em TypeScript.

**Fase A da retomada concluída:** git, CI, proteção de branch, `CLAUDE.md`.

---

## 3. O que falta — mapa completo

### Fase C · Fundação Firestore real *(em andamento)*

| # | Passo | Estado |
|---|---|---|
| C1 | Criar banco em `southamerica-east1` | ✅ feito |
| C2 | `flutterfire configure --project=elytron-d2b-dev` | ✅ feito — `firebase_options.dart` sem `PLACEHOLDER` |
| C3 | Emuladores + seed + rodar com `DATA_SOURCE=firestore` | ✅ boot confirmado (20/08/2026) — app inicializa e renderiza igual ao mock. Login por persona não foi exercitado por gesto (sem `idb`/XCUITest no ambiente); pendente QA manual ou `integration_test` |
| C4 | Colher índices faltantes no console e comitar | ✅ analisado (20/08/2026) — **nenhum índice composto é necessário hoje**: as 5 queries de `FirestoreStrategicRepository` usam no máximo um `where` ou um `orderBy` isolado (índice automático de campo único). Os 11 índices em `firestore.indexes.json` são especulativos, para coleções (`incidents`, `vulnerabilities`, `reports`, `members`) e filtros combinados que ainda não existem em código — revisar contra a query real quando os prompts 10-14 as implementarem, não antes |

Fecha o achado **A-03**. **A-04** revisado: não há índice faltante para o código atual, mas os índices declarados não correspondem a nenhuma query existente — ver nota C4.

**Bug encontrado e corrigido nesta verificação:** `main.dart` não tinha nenhuma
chamada `useFirestoreEmulator`/`useAuthEmulator` — `DATA_SOURCE=firestore`
sozinho falava com o projeto real, nunca com o emulador. Criado o flag
`AppConfig.useEmulator` (`--dart-define=USE_EMULATOR=true`). Também corrigido
`scripts/seed/seed.ts`: o `require()` do `.firebaserc` (a) apontava para o
caminho errado relativo ao JS compilado e (b) tentava usar `require` num
arquivo sem extensão `.json`, que o Node compila como JS e quebra — trocado
por leitura de arquivo + `JSON.parse`. O seed nunca tinha rodado com sucesso
contra o build compilado até esta correção.

### Fase D · Rede de segurança

`test/rules` com `@firebase/rules-unit-testing`, caso positivo **e** negativo
por regra. Fecha o achado **A-02** e é **pré-requisito do prompt 12**.

Cobertura mínima: tenant A não lê B · `board` não lê `incidents` nem
`compliance` · `operational` não lê `risks` · ninguém lê `audit_logs` ·
cliente não escreve o próprio `role`.

### Fase E · Prompts pendentes

| # | Prompt | Escopo | Bloqueado por |
|---|---|---|---|
| 10 | `10_CATALOGO_E_WIZARD` | Catálogo dos 44 serviços, bifurcação relatórios/demanda, wizard de RFS em 5 passos, `RequestPolicy` com a alçada técnico→CISO→board | D-30 |
| 11 | `11_RELATORIOS_ESPECIALISTAS` | 8 modelos por categoria, visualizador em 3 profundidades, `ReportAccessPolicy`, 8 gatilhos de fato relevante | D-27, D-29, Fase C |
| 12 | `12_PERSONA_ESPECIALISTA_RETROFIT` | 4ª persona (staff Elytron), identidade cross-tenant, `TenantScope`, `StaffPolicy`, reescrita das rules | **Fase D**, D-18 |
| 13 | `13_MODULO_AUTORIA_RELATORIOS` | Cadeia de custódia offline, revisão, verificação de redação, publicação | D-05, D-06, D-07 |
| 14 | `14_ESTRUTURA_DADOS_FIREBASE` | Schema, conversores, `TenantGuard`, rules das 4 personas, TTL, agregados, seed, RTDB de presença | D-12, D-13 |

---

## 4. Decisões que travam — as 8 urgentes

Detalhe completo em `docs/13_DECISOES_PENDENTES.md`.

| # | Decisão | Recomendação | Trava |
|---|---|---|---|
| D-05 | App guarda evidência forense ou só o registro de custódia? | **Só o registro** + ponteiro para o cofre | 13 |
| D-06 | Prazos separados para registro e evidência? | **Sim**: registro 10 anos, evidência 12 meses pós-contrato | 14 |
| D-07 | Como aplicar o prazo? | `retentionUntil` + `legalHold` por registro, **nunca TTL global** | 14 |
| D-12 | Plano de faturamento | **Spark** em dev/staging · **Blaze** em produção, com alerta de orçamento | 14, Functions (produção) |
| D-13 | Retenção de `audit_logs` | 5 anos | 14 |
| D-18 | Um build ou dois flavors (cliente/staff)? | **Dois** | 12 |
| D-27 | Validar os 8 modelos de relatório com as disciplinas | 1h com pentest, forense e GRC | **11** |
| D-29 | Limite de fato relevante | **% da receita**, não valor fixo | 11 |
| D-30 | SLA de resposta a RFS | Crise 2h · urgente 1 dia · planejado 5 dias | 10 |

**D-27 é o de maior risco de retrabalho do projeto.** Campo errado num modelo
de relatório contamina código, banco e histórico.

---

## 5. Achados de auditoria ainda abertos

| Achado | Situação |
|---|---|
| **A-02** `test/rules` ausente | Fase D |
| **A-03** `firebase_options.dart` placeholder | Fase C2 |
| **A-04** Índices defasados | Fase C4 |
| **M-03** `sections` sem regra explícita | Entra no prompt 11 |
| **M-05** `bootstrap.sh` não idempotente | Baixa prioridade |
| **B-01** 2 TODOs de `url_launcher` | Dívida consciente |

Fechados: **C-01** (git), **A-01** (`.firebaserc`), **A-05** (doc 04),
**M-01** (CI), **M-02** (`CLAUDE.md`), **M-04** (`.firebaserc` versionado).

---

## 6. Ritual de execução de cada prompt

```bash
git switch -c prompt/NN-descricao
# rodar o prompt no Claude Code (colar o bloco ```text do arquivo)
dart format lib test
flutter analyze
flutter test
./scripts/audit.sh
git add -A && git commit -m "feat(escopo): resumo no imperativo"
git push -u origin HEAD
gh pr create --fill
gh pr checks --watch
gh pr merge --squash --delete-branch
git switch main && git pull
git tag -a vX.Y.0-nome -m "…" && git push --follow-tags
```

Deu errado? `git switch main && git branch -D prompt/...`. Nada se perde.

Use `sec(...)` no commit para qualquer mudança em `firestore.rules`, política
de acesso ou classificação de relatório.

---

## 7. Abertura da nova conversa

Cole o bloco abaixo na primeira mensagem da conversa nova.

````text
Retomando o projeto Elytron Dash2Board. Leia docs/17_PONTO_DE_RETOMADA.md no
repositório para o estado completo — abaixo o essencial.

CONTEXTO
App mobile Flutter + Material 3 sobre Firebase (Firestore + Auth), multi-tenant,
de relatórios e inteligência de cibersegurança para CISOs. Quatro personas:
operational (SOC), strategic (CISO, público primário), board (C-level) e
staff (especialista Elytron, cross-tenant, ainda não implementada).

ESTADO
- Repositório dtupig/dash2board, main protegido, CI com 3 jobs verdes
- flutter analyze limpo, flutter test verde, 85 arquivos Dart
- Prompts 1 a 9 executados: jornada de entrada, design system, kit de gráficos,
  módulo estratégico do CISO completo, onboarding, seed
- App roda hoje só com --dart-define=MOCK=true
- Firestore criado em southamerica-east1; firebase_options.dart ainda placeholder

PRÓXIMOS PASSOS, NESTA ORDEM
1. Fase C: flutterfire configure, emuladores + seed, rodar com
   DATA_SOURCE=firestore, corrigir índices
2. Fase D: test/rules com @firebase/rules-unit-testing (pré-requisito do prompt 12)
3. Fase E: prompts 10 a 14, em docs/prompts/

REGRAS DO PROJETO
Estão em CLAUDE.md e são inegociáveis: flutter analyze em "No issues found!",
Color.withValues (nunca withOpacity), sem MaterialState/pageTransitionsTheme/
CardTheme em ThemeData, Riverpod só com APIs estáveis, nunca pumpAndSettle,
domain/ em Dart puro, presentation/ sem Firebase, tenantId sempre explícito.

DECISÕES ABERTAS QUE TRAVAM
D-30 (SLA de RFS) trava o prompt 10 · D-27 (validar os 8 modelos de relatório
com as disciplinas) e D-29 (limite de fato relevante como % da receita) travam
o 11 · D-18 (dois flavors) trava o 12 · D-05/06/07 (custódia) travam o 13 ·
D-12 (Spark em dev/staging, Blaze em produção) e D-13 (retenção) travam o 14.
Detalhe em docs/13.

COMO EU QUERO TRABALHAR
Um passo por vez, com confirmação minha antes do próximo. Arquitetura e
estratégia nesta conversa; execução de código no Claude Code do VSCode, um
branch por prompt.
````

---

## 8. Mapa de documentos

| Documento | Para quê |
|---|---|
| `CLAUDE.md` | Regras do projeto — lido automaticamente pelo Claude Code |
| `docs/00_ARQUITETURA.md` | Camadas, estado, navegação, decisões de segurança |
| `docs/01_MODELO_DADOS_FIRESTORE.md` | Coleções e matriz de acesso |
| `docs/02_PERSONAS.md` | As quatro personas |
| `docs/08_CATALOGO_SERVICOS.md` | Taxonomia canônica: 8 categorias, 44 serviços |
| `docs/09_PERSONA_ESPECIALISTA.md` | ERS da 4ª persona e modelo cross-tenant |
| `docs/10_OPORTUNIDADES_PRODUTO.md` | Personas e casos de uso ainda não modelados |
| `docs/11_MODELO_FISICO_DADOS.md` | Firestore vs RTDB, esquema físico, custo, retenção |
| `docs/12_OPERACAO_FIREBASE.md` | Runbook de provisionamento, backup, IAM |
| `docs/13_DECISOES_PENDENTES.md` | **As 31 decisões, com recomendação** |
| `docs/14_AUDITORIA_QUALIDADE.md` | Relatório de auditoria e achados |
| `docs/15_GIT_E_GITHUB.md` | Repositório, CI, fluxo de trabalho |
| `docs/16_PLANO_DE_RETOMADA.md` | As 5 fases e o ritual |
| `docs/prompts/00_INDICE.md` | Índice dos prompts 2 a 14 |

---

## 9. O que aprendemos e não pode se perder

1. **Nome de status check em ruleset se seleciona, nunca se digita.** Um
   caractere de diferença produz espera eterna que parece bug de plataforma.
2. **`.gitignore` antes do primeiro commit.** `node_modules` de subprojeto que
   entra no histórico só sai reescrevendo a história.
3. **`dart format` antes do commit**, não depois da CI reprovar.
4. **Placeholder que compila mas explode em runtime** é a pior combinação:
   passa no `analyze` e falha em silêncio. `main` nunca deve morrer antes do
   `runApp`.
5. **ID de exemplo em arquivo de configuração deve parecer exemplo.**
   `<SEU_PROJETO_DEV>`, nunca algo que pareça real.
6. **Região de Firestore é permanente.** Confira antes de criar; se estiver
   errada e o banco estiver vazio, recrie na hora — nunca vai custar tão pouco.
