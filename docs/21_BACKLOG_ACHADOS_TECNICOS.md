# Backlog técnico — achados pós-PR #18

Documento vivo, no mesmo espírito do `docs/20_RETOMADA_SESSAO.md`: registra o
backlog dos 4 itens que o PO pediu para tratar em sequência em 04/09/2026,
como histórias com critério de aceite, e os pontos onde a decisão é de
negócio, não técnica.

Itens 1 (parcial) e 3 têm pergunta de negócio em aberto — ver cada seção.

---

## 1. Arquivos acima de 250 linhas (achado 4b)

**Story:** Como time de engenharia, quero que todo arquivo `.dart` caiba no
limite de 250 linhas do `CLAUDE.md`, para que `./scripts/prompt check` pare de
reprovar e o código continue fácil de revisar.

**Critério de aceite:** os 14 arquivos abaixo ficam ≤ 250 linhas, sem mudar
comportamento (`flutter analyze` limpo, `flutter test` verde, sem diff visual
- widget dividido em arquivos, não reescrito).

### Inventário e split proposto

| Linhas | Arquivo | Bucket | Split proposto |
|---|---|---|---|
| 744 | `lib/features/strategic/data/mock_strategic_repository.dart` | A | Extrair dado de demonstração por domínio (posture, riscos, compliance, insights) para `data/mock/mock_strategic_*.dart`, mesmo padrão já usado em `features/reports/data/mock/` |
| 670 | `lib/features/dashboard/presentation/board_dashboard_screen.dart` | **B** | Extrair cards/seções para `widgets/` |
| 648 | `lib/features/strategic/presentation/compliance_screen.dart` | **B** | Extrair tabela de controles e filtros para `widgets/` |
| 564 | `lib/core/widgets/charts/trend_line_chart.dart` | A | Separar builder de série/eixo/tooltip do widget principal |
| 549 | `lib/features/auth/presentation/welcome_screen.dart` | A | Extrair seções (hero, proposta de valor, CTA) para `widgets/` |
| 520 | `lib/features/strategic/presentation/executive_briefing_screen.dart` | **B** | Extrair seções do briefing para `widgets/` |
| 468 | `lib/features/strategic/presentation/survey_screen.dart` | **B** | Extrair perguntas/etapas para `widgets/` |
| 466 | `lib/features/auth/presentation/sign_in_screen.dart` | A | Extrair formulário e estados de erro para `widgets/` |
| 463 | `lib/features/strategic/presentation/briefing_pdf_builder.dart` | A | Dividir por seção do PDF (é builder puro, sem UI reativa) |
| 382 | `lib/features/strategic/presentation/insights_screen.dart` | **B** | Extrair cards de insight para `widgets/` |
| 309 | `lib/core/widgets/charts/domain_bar_chart.dart` | A | Separar builder de barra/legenda |
| 296 | `lib/core/widgets/charts/chart_frame.dart` | A | Extrair header/legenda do frame |
| 295 | `lib/app/router.dart` | A | Agrupar rotas por feature em `router_*.dart` |
| 290 | `lib/features/strategic/data/firestore_strategic_repository.dart` | A | Extrair mappers, mesmo padrão de `firestore_reports_mappers.dart` |

**Bucket A** (9 arquivos - repositórios, gráficos, router, telas de auth): sem
sobreposição com trabalho planejado. Refatorar agora é seguro.

**Bucket B** (5 arquivos - `board_dashboard_screen`, `compliance_screen`,
`executive_briefing_screen`, `survey_screen`, `insights_screen`): são
exatamente as telas que o **S4 ("a cena da demo — painéis em tela larga")**
vai redesenhar para layout de tela larga. Refatorar a estrutura interna agora
e redesenhar o layout depois no S4 é retrabalho plausível - divide um arquivo
em widgets internos hoje, S4 pode reagrupar esses mesmos widgets num grid de
3 colunas amanhã.

> **Decisão do PO em 04/09/2026:** Bucket B fica parqueado até o S4 decidir a
> estrutura de tela larga — evita dividir a estrutura interna agora e o S4
> reagrupar o mesmo código em poucas semanas. `./scripts/prompt check` vai
> continuar reprovando nesses 5 arquivos até lá; é esperado, não é regressão.

**Status:** Bucket A em execução. Bucket B parqueado (decisão do PO,
04/09/2026) — revisitar quando o S4 definir o layout de tela larga.

---

## 2. Achado 5 — `watchSections` com o mesmo bug de lista do achado 1

**Story:** Como usuário `operational` ou `board` abrindo um relatório com
seções de sensibilidades variadas, quero que a lista de seções carregue
mesmo quando alguma seção individual está fora do meu alcance, para não cair
em "acesso não provisionado" ao abrir um relatório que eu deveria conseguir
ler.

**Critério de aceite:** mesmo padrão do achado 1 — campo desnormalizado
`visibleRoles` por seção, rule de `list` decidindo por esse campo (`get`
continua em `canSeeSection`), índice composto correspondente, teste de rules
com `getDocs` provando o bug e a correção.

**Status:** não iniciado.

---

## 3. S2 — job de build na CI

**Story:** Como time de engenharia, quero que a CI rode `flutter build` de
verdade, para que um erro de build nativo (iOS/Android) seja pego no PR, não
depois, no clone de alguém.

> **Ponto de decisão de negócio:** um job de build iOS precisa de runner
> macOS (mais lento e mais caro em minutos de CI do que o Linux usado hoje
> nos 3 jobs existentes) e de uma decisão sobre assinatura - build
> `--no-codesign` (mais simples, não valida o que a App Store exigirá) ou
> build assinado de verdade (exige certificado e provisioning profile como
> secret da CI). Qual escopo faz sentido agora: só Android (runner Linux,
> sem custo extra), só iOS `--no-codesign`, ou os dois?

**Status:** não iniciado — aguardando decisão de escopo.

---

## 4. Testes automatizados para `functions/`

**Story:** Como time de engenharia, quero cobertura mínima das Cloud
Functions (`syncMemberClaims`, `assignRole`, `claimInvite`,
`recordReadReceipt` e as demais), para que uma regressão numa regra de
autorização do backend seja pega antes do deploy, não em produção.

**Critério de aceite:** framework leve (`firebase-functions-test` +
`mocha`, mesmo par já usado em `test/rules/`) cobrindo as 7 functions
existentes com pelo menos um caso positivo e um negativo cada, rodando na CI.
Escopo deliberadamente mínimo - não é o objetivo desta história construir uma
suíte exaustiva, e se o escopo começar a crescer além disso, o PO é
consultado antes de continuar.

**Status:** não iniciado.
