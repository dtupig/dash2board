# Ponto de retomada — Elytron Dash2Board

Documento de handoff. Serve para abrir uma conversa nova de arquitetura sem
perder contexto, e para qualquer pessoa entender em cinco minutos onde o
projeto está e o que vem a seguir.

**Atualizado em:** 20/08/2026

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
| `firebase_options.dart` | configurado via `flutterfire configure`, **sem placeholder** — dia a dia ainda roda com `MOCK=true` |

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

### Fase C · Fundação Firestore real *(fechada)*

| # | Passo | Estado |
|---|---|---|
| C1 | Criar banco em `southamerica-east1` | ✅ feito |
| C2 | `flutterfire configure --project=elytron-d2b-dev` | ✅ feito — `firebase_options.dart` sem `PLACEHOLDER` |
| C3 | Emuladores + seed + rodar com `DATA_SOURCE=firestore` | ✅ fechado (20/08/2026) — boot confirmado e, nesta sessão, login por gesto testado manualmente no simulador iOS para as 3 personas (`operacao@`, `ciso@`, `board@demo.elytron`): roteamento e conteúdo de cada persona corretos contra o Firestore real do emulador |
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

### Fase D · Rede de segurança *(fechada)*

✅ `test/rules` criado com `@firebase/rules-unit-testing` (20/08/2026) — 18
testes, caso positivo **e** negativo por regra: isolamento entre tenants,
`board` não lê `incidents`/`compliance`, `operational` não lê `risks`,
ninguém lê `audit_logs` pelo client SDK, cliente não escreve o próprio
`role`. Fecha o achado **A-02** e a decisão **D-26**. O job "Testes das
security rules" do CI passou a executar de verdade (antes só emitia
`::warning::` porque o diretório não existia).

### Fase E · Prompts pendentes

| # | Prompt | Escopo | Bloqueado por |
|---|---|---|---|
| 10 | `10_CATALOGO_E_WIZARD` | Catálogo dos 44 serviços, bifurcação relatórios/demanda, wizard de RFS em 5 passos, `RequestPolicy` com a alçada técnico→CISO→board | Nenhum bloqueio técnico — D-30 já confirmado |
| 11 | `11_RELATORIOS_ESPECIALISTAS` | 8 modelos por categoria, visualizador em 3 profundidades, `ReportAccessPolicy`, 8 gatilhos de fato relevante | D-27 (agendado para 21/08/2026) |
| 12 | `12_PERSONA_ESPECIALISTA_RETROFIT` | 4ª persona (staff Elytron), identidade cross-tenant, `TenantScope`, `StaffPolicy`, reescrita das rules | D-21 (Cloud Function de criação de tenant, ainda não implementada) — Fase D e D-18 já resolvidos |
| 13 | `13_MODULO_AUTORIA_RELATORIOS` | Cadeia de custódia offline, revisão, verificação de redação, publicação | Nenhum bloqueio técnico — D-05/06/07 já confirmados |
| 14 | `14_ESTRUTURA_DADOS_FIREBASE` | Schema, conversores, `TenantGuard`, rules das 4 personas, TTL, agregados, seed, RTDB de presença | Nenhum bloqueio técnico — D-12/13 já confirmados |

---

## 4. Decisões — status

Detalhe completo em `docs/13_DECISOES_PENDENTES.md`.

**Confirmadas em 19/08/2026** — destravam os prompts 10, 13 e 14, e as
pré-condições dos prompts 11 e 12:

| # | Decisão | Valor confirmado | Destravava |
|---|---|---|---|
| D-05 | App guarda evidência forense ou só o registro de custódia? | Só o registro + ponteiro para o cofre | 13 |
| D-06 | Prazos separados para registro e evidência? | Sim: registro 10 anos, evidência 12 meses pós-contrato | 14 |
| D-07 | Como aplicar o prazo? | `retentionUntil` + `legalHold` por registro, nunca TTL global | 14 |
| D-12 | Plano de faturamento | Spark em dev/staging · Blaze em produção, com alerta de orçamento | 14, Functions (produção) |
| D-13 | Retenção de `audit_logs` | 5 anos | 14 |
| D-18 | Um build ou dois flavors (cliente/staff)? | Dois | 12 |
| D-29 | Limite de fato relevante | 25% da receita do cliente, por tenant | 11 |
| D-30 | SLA de resposta a RFS | Crise 2h · urgente 1 dia · planejado 5 dias | 10 |

**Ainda aberta — D-27.** Validar os 8 modelos de relatório com as
disciplinas: escopo definido, falta agendar 1h com pentest, forense, GRC,
AppSec lead e SOC/Threat Intel lead. **É o de maior risco de retrabalho do
projeto** — campo errado num modelo de relatório contamina código, banco e
histórico. Trava o prompt 11.

---

## 5. Achados de auditoria ainda abertos

| Achado | Situação |
|---|---|
| **A-02** `test/rules` ausente | Fase D — CI tem job `rules`, mas ele só roda se o diretório existir; hoje passa com `::warning::`, sem cobertura nenhuma |
| **M-03** `sections` sem regra explícita | Entra no prompt 11 |
| **M-05** `bootstrap.sh` não idempotente | Baixa prioridade |
| **B-01** 2 TODOs de `url_launcher` | Dívida consciente |

Fechados: **C-01** (git), **A-01** (`.firebaserc`), **A-03**
(`firebase_options.dart` sem placeholder, Fase C2), **A-04** (nenhum índice
composto necessário para as queries atuais, Fase C4 — revisitar quando os
prompts 10-14 implementarem novas coleções/filtros), **A-05** (doc 04),
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
- Repositório dtupig/dash2board, main protegido, CI com 3 jobs verdes de
  verdade (o job "Testes das security rules" agora roda test/rules, não é
  mais um warning)
- flutter analyze limpo, flutter test verde
- Prompts 1 a 9 executados: jornada de entrada, design system, kit de gráficos,
  módulo estratégico do CISO completo, onboarding, seed
- Fase C fechada: flutterfire configure feito, emuladores + seed corrigidos e
  funcionando, login por gesto testado manualmente para as 3 personas contra o
  Firestore real do emulador, nenhum índice composto faltante hoje. App ainda
  roda no dia a dia com --dart-define=MOCK=true
- Fase D fechada: test/rules com 18 testes (positivo e negativo por regra),
  fecha A-02 e D-26
- 8 das 9 decisões urgentes já confirmadas em 19/08/2026 (docs/13); D-27 tem
  reunião agendada para 21/08/2026 16h-17h

PRÓXIMOS PASSOS, NESTA ORDEM
1. Fase E: prompts 10, 13 e 14 já sem bloqueio técnico — podem entrar na
   esteira em docs/prompts/
2. Prompt 11 aguarda a reunião de D-27 (21/08/2026)
3. Prompt 12 aguarda D-21 (Cloud Function de criação de tenant, ainda não
   implementada) — Fase D e D-18 já resolvidos

REGRAS DO PROJETO
Estão em CLAUDE.md e são inegociáveis: flutter analyze em "No issues found!",
Color.withValues (nunca withOpacity), sem MaterialState/pageTransitionsTheme/
CardTheme em ThemeData, Riverpod só com APIs estáveis, nunca pumpAndSettle,
domain/ em Dart puro, presentation/ sem Firebase, tenantId sempre explícito.

DECISÃO ABERTA QUE TRAVA
Só D-27 (validar os 8 modelos de relatório com as disciplinas) continua
aberta — trava o prompt 11, e é a de maior risco de retrabalho do projeto.
Todas as outras 8 decisões urgentes (D-05/06/07/12/13/18/29/30) já foram
confirmadas em 19/08/2026. Detalhe em docs/13.

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
7. **Um job de CI "protegido por `if [ -d ... ]`" pode passar sem testar
   nada.** O job `rules` ficou verde por semanas só imprimindo `::warning::`
   porque `test/rules` não existia — "CI verde" não provava cobertura de
   segurança. Vale desconfiar de qualquer job condicional assim.
8. **`firebase-tools` recente exige JDK 21+ para o emulador do Firestore.**
   O runner padrão do GitHub Actions tem uma versão mais antiga; sem
   `actions/setup-java@v4` (Temurin 21), o job `rules` falha só nisso.
