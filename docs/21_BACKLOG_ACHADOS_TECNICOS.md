# Backlog técnico — achados pós-PR #18

Documento vivo, no mesmo espírito do `docs/20_RETOMADA_SESSAO.md`: registra o
backlog dos 4 itens que o PO pediu para tratar em sequência em 04/09/2026,
como histórias com critério de aceite, e os pontos onde a decisão é de
negócio, não técnica.

Item 1 (Bucket B) e item 3 tiveram decisão de negócio já tomada pelo PO —
ver cada seção. Itens 1 (Bucket A), 2, 3 e 4 concluídos — backlog fechado.

---

## 1. Arquivos acima de 250 linhas (achado 4b)

**Story:** Como time de engenharia, quero que todo arquivo `.dart` caiba no
limite de 250 linhas do `CLAUDE.md`, para que `./scripts/prompt check` pare de
reprovar e o código continue fácil de revisar.

**Critério de aceite:** os 14 arquivos abaixo ficam ≤ 250 linhas, sem mudar
comportamento (`flutter analyze` limpo, `flutter test` verde, sem diff visual
- widget dividido em arquivos, não reescrito).

### Inventário e split proposto

| Linhas | Arquivo | Bucket | Split proposto | Status |
|---|---|---|---|---|
| 744 | `lib/features/strategic/data/mock_strategic_repository.dart` | A | Extrair dado de demonstração por domínio (posture, riscos, compliance, insights) para `data/mock/mock_strategic_*.dart`, mesmo padrão já usado em `features/reports/data/mock/` | ✅ 159 linhas |
| 670 | `lib/features/dashboard/presentation/board_dashboard_screen.dart` | **B** | Extrair cards/seções para `widgets/` | parqueado |
| 648 | `lib/features/strategic/presentation/compliance_screen.dart` | **B** | Extrair tabela de controles e filtros para `widgets/` | parqueado |
| 564 | `lib/core/widgets/charts/trend_line_chart.dart` | A | Separar builder de série/eixo/tooltip do widget principal | ✅ 193 linhas (+4 arquivos auxiliares) |
| 549 | `lib/features/auth/presentation/welcome_screen.dart` | A | Extrair seções (hero, proposta de valor, CTA) para `widgets/` | ✅ 194 linhas (+4 arquivos auxiliares) |
| 520 | `lib/features/strategic/presentation/executive_briefing_screen.dart` | **B** | Extrair seções do briefing para `widgets/` | parqueado |
| 468 | `lib/features/strategic/presentation/survey_screen.dart` | **B** | Extrair perguntas/etapas para `widgets/` | parqueado |
| 466 | `lib/features/auth/presentation/sign_in_screen.dart` | A | Extrair formulário e estados de erro para `widgets/` | ✅ 218 linhas (+4 arquivos auxiliares) |
| 463 | `lib/features/strategic/presentation/briefing_pdf_builder.dart` | A | Dividir por seção do PDF (é builder puro, sem UI reativa) | ✅ 139 linhas (+3 arquivos auxiliares, +1 teste novo) |
| 382 | `lib/features/strategic/presentation/insights_screen.dart` | **B** | Extrair cards de insight para `widgets/` | parqueado |
| 309 | `lib/core/widgets/charts/domain_bar_chart.dart` | A | Separar builder de barra/legenda | ✅ 172 linhas (+1 arquivo auxiliar) |
| 296 | `lib/core/widgets/charts/chart_frame.dart` | A | Extrair header/legenda do frame | ✅ 112 linhas (+1 arquivo auxiliar) |
| 295 | `lib/app/router.dart` | A | Agrupar rotas por feature em `router_*.dart` | ✅ 198 linhas (+2 arquivos auxiliares) |
| 290 | `lib/features/strategic/data/firestore_strategic_repository.dart` | A | Extrair mappers, mesmo padrão de `firestore_reports_mappers.dart` | ✅ 195 linhas (+1 arquivo auxiliar) |

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

**Status:** Bucket A **concluído** (9/9 arquivos). Bucket B parqueado (decisão
do PO, 04/09/2026) — revisitar quando o S4 definir o layout de tela larga.
`./scripts/prompt check` só reprova mais nos 5 arquivos do Bucket B, como
esperado.

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

> **Achado de UX/segurança encontrado ao implementar:** o mock de seções
> devolve todas sem filtrar, e `ReportSectionTile` mostra um aviso de "seção
> suprimida" para quem não pode ver o conteúdo (`redactionNotice`, "nunca
> some em silêncio"). Mas com a correção deste achado, uma seção fora de
> `visibleRoles` nunca chega ao cliente Firestore — fica fora da lista, sem
> aviso algum. Esse aviso só é alcançável hoje na demonstração (`MOCK=true`),
> nunca em produção. Não é regressão desta correção (o `get()` individual já
> bloqueava a seção com `permission-denied` antes desta mudança, sem chegar a
> renderizar o aviso) — é um gap de design pré-existente que a correção só
> tornou visível. Documentado como decisão do módulo de autoria (prompt 13):
> investir num "stub" de seção redigida (título + motivo, sem corpo) que
> sobreviva ao filtro de `list` para o aviso funcionar também em produção, ou
> aceitar que é só recurso de demonstração. Não é escopo desta história —
> fica registrado para quando o módulo de autoria (prompt 13) for
> implementado.

**Status:** ✅ concluído. Índice composto **não** foi necessário — um único
`where(arrayContains)` sem `orderBy` adicional não exige índice composto no
Firestore (diferente do achado 1, que combinava `array-contains` com
`orderBy`).

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
>
> **Decisão do PO em 04/09/2026:** os dois, como build de simulação
> (`--debug`/`--no-codesign`, sem assinatura real) — ver
> `docs/22_INSIGHTS_BUILD_NATIVO.md` para o caminho até a distribuição real
> e `docs/23_TRACKER_ANDROID_LOCAL.md` para o tracker do emulador Android
> local, pedido junto com a decisão.

**Status:** ✅ concluído. Dois jobs novos em `.github/workflows/ci.yaml`:
`build-android` (`flutter build apk --debug`) e `build-ios` (`flutter build
ios --simulator --no-codesign`, runner macOS). Achado ao implementar: o
build iOS estava genuinamente quebrado em `main` por uma família de pacotes
Firebase (`firebase_core`/`firebase_auth`/`cloud_firestore`/
`cloud_functions`) com versões defasadas e mutuamente incompatíveis no
`pubspec.lock`/`ios/Podfile.lock` - corrigido subindo a família inteira
junto (detalhe em `docs/20_RETOMADA_SESSAO.md`, seção Ambiente). Validado
local com `flutter build ios --simulator --no-codesign` e `flutter run` com
screenshot antes de confiar só na CI.

---

## 4. Testes automatizados para `functions/`

**Story:** Como time de engenharia, quero cobertura mínima das Cloud
Functions (`syncMemberClaims`, `assignRole`, `claimInvite`,
`recordReadReceipt` e as demais), para que uma regressão numa regra de
autorização do backend seja pega antes do deploy, não em produção.

**Critério de aceite:** framework leve (`mocha`, mesmo runner já usado em
`test/rules/`) cobrindo as 6 functions existentes (`gateSignUp`,
`syncMemberClaims`, `logRiskDecision`, `assignRole`, `claimInvite`,
`recordReadReceipt` - a história original citava "7", contagem errada)
com pelo menos um caso positivo e um negativo cada, rodando na CI. Escopo
deliberadamente mínimo - não é o objetivo desta história construir uma
suíte exaustiva, e se o escopo começar a crescer além disso, o PO é
consultado antes de continuar.

**Status:** ✅ concluído. 12 testes (6 functions × positivo/negativo) em
`functions/test/functions.spec.ts`, rodando via `firebase emulators:exec
--only firestore,auth "mocha"` (job `functions` novo em
`.github/workflows/ci.yaml`) - **sem** o emulador de Functions: cada
handler é chamado direto (`handleAssignRole(request)`, não `assignRole`
via HTTP), com o Admin SDK real (o mesmo usado em produção) falando com os
emuladores Firestore/Auth para estado de verdade. Isso testa a *lógica* de
cada function (autorização, o que grava, o que rejeita), não a *fiação*
(será que o Firebase de fato invoca a function quando um cliente real
assina/chama/escreve) - essa segunda camada ficaria bem mais cara de testar
(token real, emulador de Functions, polling de trigger assíncrono) para um
ganho de cobertura pequeno frente ao risco real (regressão de autorização).
Refatoração necessária: os 6 handlers, antes definidos inline dentro da
chamada do trigger (`onCall(async (request) => {...})`), foram extraídos
para funções nomeadas e exportadas (`handleAssignRole`, etc.) - mesmo
comportamento em produção, só isso que torna a chamada direta possível nos
testes.

**Status:** não iniciado.
