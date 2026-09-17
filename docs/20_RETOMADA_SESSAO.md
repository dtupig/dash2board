# Retomada de sessão — estado em 03/09/2026

Documento vivo. O `docs/17_PONTO_DE_RETOMADA.md` descreve o estado até
25/08/2026 e **está desatualizado num ponto crítico** (ver item 1). Este aqui
é o estado real.

**Palavra-chave para retomar:** escreva **`RETOMAR D2B`** no início da conversa.

---

## 1. Correção importante ao docs/17 — ~~pendente~~ resolvido

~~O `docs/17` diz que o **prompt 11 está "destravado, pronto para
executar"**. Ele **já foi executado**. Existe o branch
`prompt/11-relatorios-especialistas` e o **PR #18, aberto e verde desde
25/08/2026**, nunca mesclado.~~

**Mesclado em 04/09/2026.** As 3 suposições de produto do PR foram aprovadas
pelo PO no mesmo dia (board nunca baixa relatório; `operational` nunca vê
`personalData`/`chainOfCustody`; visão do board é curada, não filtrada). O
`docs/17` segue desatualizado nesse ponto especificamente - o resto deste
documento (seções 4 em diante) é o estado real desde então.

## 2. Decisões tomadas pelo PO em 03/09/2026

| # | Decisão | Valor |
|---|---|---|
| Marco | Próximo objetivo de negócio | **Demo vendável para prospect** |
| Web | Quando a trilha web entra | **Em paralelo, a partir de S2** |
| Config nativa | `GoogleService-Info.plist` no git? | **Versionar e afrouxar o guardrail** |
| PR #18 | As 3 regras assumidas | **Aprovadas como estão** |

## 3. Plano vigente — sprints por valor de negócio

| Sprint | Entrega | Duração | Status em 17/09/2026 |
|---|---|---|---|
| **S1** | Relatórios entram no produto (merge do PR #18 + correções) | 3 dias | ✅ concluído |
| **S2** | Repositório confiável (config versionada + job de build na CI) | 2 dias | ✅ concluído |
| **S3** | Web no ar — `HU-W-01` a `05` do épico E-W | 1 semana | 🔶 parcial — `01`/`02`/`03` feitos; só `HU-W-04`/`05` pendentes |
| **S4** | A cena da demo — `W2` + `W3`, painéis em tela larga | 2 semanas | 🔶 parcial — `W2` completo; `W3`: `09`/`10`/`14` feitos (Fase 1 do mockup web, seção 10), `11`/`12`/`13` pendentes |
| **S5** | Catálogo e RFS na web — `W4` | 1 semana | não iniciado |

**Desvio registrado (não é erro, é decisão de fato):** a execução pulou
direto de `HU-W-01` para as histórias de entrada de `W2` (`06`-`08`),
sem fechar `HU-W-02` a `05` primeiro - a ordem do plano previa o shell
adaptativo e o roteamento antes da jornada de entrada. Na prática,
`HU-W-06` e `07` já vinham prontas do produto mobile (autofill, mensagem
genérica de credencial, tela de acesso pendente) e só precisaram de
validação; só `HU-W-08` exigiu código novo. **`HU-W-02` e `HU-W-03` foram
fechadas logo em seguida** (PR#36/#37, ver seção 9) - só `HU-W-04` (sessão
de 12h) e `HU-W-05` (endurecimento de segurança da entrega web) restam do
Sprint W1.

**Parqueado até depois da demo:** identidade do consultor (prompt 12),
autoria de relatórios (prompt 13), estrutura física de dados (prompt 14).
São invisíveis numa demo — mas viram caminho crítico no dia em que a demo
converter.

Épico web completo em [`19_HISTORIAS_INTERFACE_WEB.md`](19_HISTORIAS_INTERFACE_WEB.md)
(24 histórias, 141 pontos).

## 4. Achados técnicos abertos (do PR #18)

1. ~~**A lista de relatórios quebra no Firestore real.**~~ **Corrigido.**
   `watchReports` fazia query de coleção sem `where`, e as rules decidiam por
   documento — um documento reprovado derrubava a query inteira. Corrigido
   desnormalizando `audienceRoles` no documento e filtrando por
   `array-contains` na query (`roleWire`, antes ignorado pela implementação
   Firestore, agora tem uso); `firestore.rules` passa a decidir `list` por
   `audienceRoles`, mantendo `get` em `canOpenReport`. Novo teste de rules com
   `getDocs` prova as duas pontas (query sem `where` falha, query com `where`
   retorna só o subconjunto visível) — cobertura que não existia (zero
   `getDocs` em todo `test/rules/` antes desta correção). **Pendência
   herdada:** não existe hoje nenhum caminho de escrita para `reports` (nem
   seed, nem Cloud Function) — quem gravar `audienceRoles` na origem é o
   módulo de autoria (prompt 13, ver nota em
   `docs/prompts/13_MODULO_AUTORIA_RELATORIOS.md`). **Achado novo, descoberto
   ao investigar este:** `watchSections` tem exatamente o mesmo problema
   (query de coleção sem `where`, `canSeeSection` decidindo por
   `resource.data.sensitivity`) — não corrigido nesta rodada, ver item 5.
2. ~~**`recordReadReceipt` é um no-op.**~~ **Corrigido.** Nova Cloud Function
   `recordReadReceipt` (callable) recalcula o acesso a partir do documento
   real via Admin SDK — espelha `canOpenReport`/`ReportAccessPolicy.canOpen`
   (terceira cópia da mesma regra, junto de `firestore.rules` e do Dart) — e
   grava em `audit_logs` via `writeAudit`. O cliente Flutter chama a function
   (`cloud_functions`, nova dependência) em vez de fazer no-op; a tela trata
   falha (antes assumia sucesso incondicional). ~~**Pendência não
   resolvida:** `functions/` não tem suíte de testes automatizados.~~
   **Corrigido em 04/09/2026** (docs/21_BACKLOG_ACHADOS_TECNICOS.md, item
   4): 12 testes (as 6 functions × positivo/negativo) em
   `functions/test/functions.spec.ts`, chamando cada handler direto contra
   Firestore/Auth emulator, rodando num job novo (`functions`) da CI.
3. ~~**Índice defasado.**~~ **Corrigido junto com o item 1** — o índice morto
   `reports: ['audience','publishedAt']` (campos que não existem em nenhum
   documento, query ou rule) virou
   `reports: [audienceRoles CONTAINS, deliveredAt DESC]`, o índice composto
   que a nova query realmente exige.
4. ~~**`scripts/audit.sh` valida menos que o `CLAUDE.md` exige.**~~
   **Checagens adicionadas** (4a): `CardTheme(`, `DialogTheme(`,
   `TabBarTheme(`, `pageTransitionsTheme`, `ColorScheme.background` isolado,
   fronteiras de camada (`domain/` sem Flutter/Firebase, `presentation/` sem
   `cloud_firestore`/`firebase_auth`) e o limite de 250 linhas. Bug encontrado
   e corrigido no processo: o filtro de comentário de `check_absent` nunca
   funcionava (`grep -rn` prefixa `arquivo:linha:`, então `^\s*//` nunca
   ancorava no início do código real) — afetava todas as checagens antigas,
   não só as novas. **4b, não feito nesta rodada:** ainda há **14 arquivos**
   acima de 250 linhas no `main` (o maior com 744) — a checagem agora
   *detecta* isso (`audit.sh` reprova), mas os arquivos não foram
   refatorados; é um esforço maior, separado, a decidir se entra antes da
   demo. *Correção ao texto anterior:* o `audit.sh` **já** checava
   `pumpAndSettle` desde o commit inicial — a menção anterior a essa lacuna
   estava errada.
5. ~~**`watchSections` tem o mesmo bug de lista do item 1.**~~ **Corrigido.**
   Mesmo padrão: `visibleRoles` desnormalizado por seção (combina
   `canOpenReport` do relatório pai com `canSeeSection` da própria seção),
   `firestore.rules` decide `list` por esse campo mantendo `get` em
   `canSeeSection`, `watchSections` ganhou parâmetro `roleWire` e
   `.where('visibleRoles', arrayContains: roleWire)`. Novo teste de rules com
   `getDocs` prova as duas pontas, mesmo molde do item 1. **Pendência
   herdada:** mesma de "quem grava" do item 1, agora para `visibleRoles`
   (prompt 13). **Achado de UX/segurança descoberto ao investigar este:** o
   mock de seções devolve todas sem filtrar e `ReportSectionTile` mostra um
   aviso de "seção suprimida" para quem não pode ver — mas essa seção nunca
   chega ao cliente Firestore (fica fora da lista, sem aviso). O aviso só é
   alcançável na demonstração, nunca em produção. Documentado em
   `docs/prompts/13_MODULO_AUTORIA_RELATORIOS.md` como decisão do módulo de
   autoria: investir num "stub" de seção redigida (título + motivo, sem
   corpo) que sobreviva ao filtro de `list`, ou aceitar que o aviso é só
   recurso de demonstração.

## 5. Ambiente

- **O clone limpo não compila.** Causa e contorno em
  [`.claude/skills/rodar-o-app/SKILL.md`](../.claude/skills/rodar-o-app/SKILL.md)
  — o skill é carregado sozinho quando se pede para rodar o app.
- ~~A CI tem 3 jobs e nenhum roda `flutter build`.~~ **Corrigido em
  04/09/2026** (S2, docs/21_BACKLOG_ACHADOS_TECNICOS.md item 3): dois jobs
  novos, `build-android` (`flutter build apk --debug`, assinatura de debug,
  sem secret) e `build-ios` (`flutter build ios --simulator --no-codesign`,
  runner macOS, sem assinatura). Ao implementar, o build iOS local
  **quebrou de verdade**: `ios/Podfile.lock` estava em `Firebase/CoreOnly
  12.17.0`, incompatível com o que `firebase_core` exige hoje (12.18.0), e
  a família inteira (`firebase_auth`, `cloud_firestore`, `cloud_functions`)
  estava com versões defasadas no `pubspec.lock` mesmo com constraints
  `^` permissivas — `flutter pub get` não avança versão sozinho, só
  `flutter pub upgrade`. Corrigido subindo os quatro pacotes juntos (são
  lançados como família pelo FlutterFire; atualizar um sem os outros causa
  conflito de símbolo Swift/ObjC) e regenerando `ios/Podfile.lock`. Build
  validado local (`flutter build ios --simulator --no-codesign` e `flutter
  run` com screenshot) antes de confiar na CI. Ver
  `docs/22_INSIGHTS_BUILD_NATIVO.md` para o caminho até um build assinado de
  verdade e `docs/23_TRACKER_ANDROID_LOCAL.md` para o tracker do emulador
  Android local (ainda não configurado nesta máquina).
- Config nativa regenerada em 03/09/2026 via
  `flutterfire configure --project=elytron-d2b-dev --platforms=ios,android`.
- App validado rodando no simulador iPhone 17 / iOS 26.5 em 03/09/2026 e de
  novo em 04/09/2026 após o upgrade da família Firebase.

## 6. Pendências fora do código

- [x] Mesclar o PR #18 — feito em 04/09/2026
- [ ] `sudo rm -rf ~/.npm` — 80 arquivos do `root` sobraram no cache
- [ ] Exclusões do Defender para `DerivedData`, `CoreSimulator` e `.pub-cache`
- [ ] Reiniciar a máquina (swap com 7,3 GB presos do período de disco cheio)
- [x] Revisar o `git status` do `pod install`/`flutterfire configure` — as
      mudanças em `firebase.json`, `ios/Flutter/*.xcconfig`, `project.pbxproj`
      e os `Package.resolved` já foram commitadas em ciclos anteriores;
      `git status` na raiz está limpo hoje (05/09/2026), fora do estado
      normal de arquivo de build local já coberto pelo `.gitignore`.

## 7. Novo neste ciclo

- [`prompts/12A_PROVISIONAMENTO_DE_TENANT.md`](prompts/12A_PROVISIONAMENTO_DE_TENANT.md)
  — fecha o **D-21**, que estava registrado como decisão pendente mas era, na
  verdade, especificação faltando: nenhum prompt de 11 a 14 descrevia a função
  de criação de tenant nem resolvia o bootstrap do primeiro `staffAdmin`.

## 8. Sessão de 05/09/2026 — UAT, épico web (S3 parcial + S4 parcial)

Fechou o backlog técnico das 4 frentes (item 4 do backlog, `docs/21`) e
avançou o épico web a partir de um roteiro de teste de usuário por persona.

- **PR #31 — correção dos achados do UAT.** Duas telas (`ServicesHubScreen`,
  `RequestInboxScreen`) e mais duas (`InsightsScreen`,
  `ExecutiveBriefingScreen`, `ComplianceScreen`) navegavam com `context.go()`
  a partir de outra tela — isso substitui a pilha de navegação inteira, então
  quem chegasse por elas ficava sem botão de voltar. Trocado por
  `context.push()` nos pontos de entrada, e criado `BackOrHomeButton`
  (`lib/features/shell/back_or_home_button.dart`) para as telas que não
  tinham nenhum jeito de sair. Também corrigido overflow de 77px no bottom
  sheet "Ver dados" de `ChartFrame` (faltava `isScrollControlled: true`).
  **Investigado e não é bug do app:** o relato de acentuação quebrada no
  teclado é uma limitação conhecida do Flutter Engine com teclado físico no
  iOS Simulator (flutter/flutter#96638, #96277, #117294) - nenhum
  `TextField` do projeto tem lógica própria de acentuação para corrigir.
- **PR #32 — HU-W-01, alvo web habilitado.** `flutter create . --platforms=web`,
  `web/index.html`/`manifest.json` com branding real (não o boilerplate:
  título, descrição, cor de tema `#070B12`) e ícones redesenhados a partir
  do hexágono da marca (`lib/core/widgets/elytron_logo.dart`). Validado com
  `flutter build web --release` e `flutter run -d chrome`.
- **PR #33 — guia de publicação em Google Sites** do plano do épico
  (`docs/20_PUBLICAR_NO_GOOGLE_SITES.md`), sem relação com código de produto.
- **PR #34 — Sprint W2 (HU-W-06/07/08), jornada de entrada.** `HU-W-06`
  (login) e `HU-W-07` (acesso pendente) já vinham prontas do produto mobile
  antes deste épico existir - autofill/Enter já ligados, mensagem de
  credencial sempre genérica, `PendingAccessScreen` já com "verificar
  liberação" e "sair". Só validadas, sem mudança de código.
  **`HU-W-08` exigiu código novo e corrigiu um bug real:** o "onboarding já
  visto" vivia em `shared_preferences` por *dispositivo*, não por conta -
  quem completasse a introdução no mobile a veria de novo ao abrir a web,
  pela primeira vez, no mesmo navegador. Nova `FirestoreOnboardingRepository`
  grava a flag por `uid` em `/tenants/{tenantId}/preferences/{uid}` (coleção
  e regra de segurança que já existiam, sem uso até então) quando fora do
  modo mock. Também criado `lib/core/layout/breakpoints.dart` (`LayoutSize`,
  limiares de P-8 do épico) - infraestrutura mínima para o layout lado a
  lado do onboarding em telas `>=1200px`, reutilizável quando `HU-W-02`
  (shell adaptativo) começar.
- **Sync de repositório** (este commit): `git remote prune origin` (10 refs
  de branch já deletadas no GitHub, só a referência local sobrava);
  removida a pasta solta `Claude outputs/` (duplicata bit-a-bit de
  `docs/19_PLANO_INTERFACE_WEB_googlesites.txt`, já commitado);
  `.claude/settings.json` e `.claude/scheduled_tasks.lock` (estado local
  desta máquina/sessão, não conhecimento do projeto) adicionados ao
  `.gitignore` — `.claude/skills/` continua versionado normalmente, sem
  mudança (já estava desde o PR #19).

**O que ficou pendente do épico web ao final desta sessão:** `HU-W-02`
(shell adaptativo com `NavigationRail` - hoje não existe nenhuma navegação
além de tela cheia com `context.go/push`, nem bottom nav mobile) e
`HU-W-03` (negativa explícita em link profundo sem permissão) e `HU-W-04`
(sessão de 12h / limpeza de armazenamento no logout). **Os dois primeiros
foram fechados na sequência, mesmo dia - ver seção 9.**

## 9. Ainda 05/09/2026 — fecha HU-W-02 e HU-W-03

- **PR #35 — sync de repositório.** `git remote prune origin` (10 refs de
  branch já deletadas no GitHub); removida a pasta solta `Claude outputs/`
  (duplicata já commitada em `docs/`); corrigido um bug literal em
  `docs/21` (item 4 terminava com duas linhas de "Status" contraditórias -
  "concluído" e "não iniciado" ao mesmo tempo); `docs/20` sincronizado com
  os PRs até então.
- **PR #36 — HU-W-02, shell adaptativo por breakpoint.** Achado: o app
  **não tinha navegação persistente nenhuma antes disso**, nem bottom nav
  no mobile - trocar de painel/serviços/relatórios era só botão dentro da
  própria tela. Como o épico assume um único código Flutter (P-1) e
  paridade de caso de uso entre plataformas (P-2), o shell novo vale para
  mobile **e** web, variando só a chrome pelo breakpoint (P-8): `compact`
  ganha `NavigationBar` (novidade também no celular), `medium`/`expanded`
  ganham `NavigationRail` recolhido, `large` ganha rail expandido com
  rótulo. `lib/app/router_shell_branches.dart` (novo) move os 5 destinos
  de topo para branches de um `StatefulShellRoute.indexedStack` - cada
  branch preserva seu próprio `Navigator`/estado ao trocar de aba.
  `lib/features/shell/home_shell.dart` (novo) é a chrome em si, com 4
  testes cobrindo breakpoint e preservação de estado
  (`test/shell/home_shell_test.dart`).
- **PR #37 — HU-W-03, negativa explícita em link profundo.** Dos 3
  critérios da história, 2 já vinham de graça do PR#36 (URL própria por
  tela, voltar do navegador respeitando a ordem). O gap real: abrir o
  dashboard de outra persona já batia de volta ao próprio painel, mas em
  silêncio. Como o `redirect` do GoRouter só retorna uma URL (não carrega
  `extra`), o aviso viaja como `?acessoNegado=1` no destino do bounce -
  `HomeShell` lê esse parâmetro uma vez, mostra um `SnackBar` explícito e
  limpa a URL. 3 testes novos em `test/app/router_redirect_denial_test.dart`.

Sprint W1 fica só com `HU-W-04` (sessão de 12h) e `HU-W-05` (endurecimento
de segurança da entrega web) pendentes.

## 10. 14-17/09/2026 — Fase 1 do mockup web (RETOMAR D2B)

Sessão retomada com `RETOMAR D2B`. Achado de integridade ao retomar:
`docs/20` estava 3 PRs atrasado (#35/#36/#37 já mesclados, não
registrados) - corrigido no PR#38 (sync), mesma convenção de sempre.

O usuário trouxe `App platform UI mockups.zip` na raiz do projeto - um
canvas do Claude Design (`Dash2Board Web.dc.html`, não um export de
Figma) com 4 telas: boas-vindas/login + os 3 painéis (Operação, CISO,
Board). Lendo o HTML/CSS fonte: as cores batem **byte a byte** com
`AppColors` já existente - não é identidade visual nova, é a mesma marca
numa composição de tela larga (sidebar + grade de cards) que o app não
tinha em lugar nenhum. Decisão combinada com o usuário: Fase 1 é só essas
4 telas, uma história por PR, mesmo ritmo desta sessão.

- **PR #39 — fundação visual.** `google_fonts` + 3 famílias (Archivo em
  títulos/números, IBM Plex Sans no corpo, IBM Plex Mono em rótulos -
  muda a tipografia do app inteiro, mobile incluso).
  `lib/features/shell/web_sidebar.dart` (novo) reestiliza o
  `NavigationRail` que HU-W-02 já criava - logo + saudação + papel no
  topo, item ativo com pílula tintada na cor da persona, "Sair" fixo
  embaixo. Bug corrigido no processo: `Container(width: double.infinity)`
  dentro do `trailing`/`leading` do `NavigationRail` recebe largura
  irrestrita e quebrava ("BoxConstraints forces an infinite width").
- **PR #40 — HU-W-06 (refinamento).** Boas-vindas/login em duas colunas
  na `large`, com o login já embutido (sem navegar a `/entrar`) -
  `SignInFormCard` extraído de `SignInScreen` para reaproveitar nos dois
  lugares sem duplicar estado. `/entrar` continua existindo normalmente
  em qualquer largura.
- **PR #41 — HU-W-10.** Índice de postura + tendência + risco por domínio
  lado a lado na `large`, sem rolagem. AC3 (tooltip no hover do mouse):
  `trend_line_chart.dart` já tinha crosshair+tooltip completo, só
  disparava por toque - adicionado `MouseRegion.onHover`.
- **PR #42 — HU-W-14, fecha 1/5 do Bucket B.** Exposição financeira +
  impacto por unidade lado a lado; decisões pendentes em grade.
  `board_dashboard_screen.dart` (672 linhas, o maior do Bucket B) dividido
  *junto* com o redesenho - exatamente o cenário que a decisão do PO de
  04/09 evitava (retrabalho). Bug pego pelo teste antes do commit: flex
  desproporcional (`10:12` vs `1:12` por engano) espremia o card de
  exposição a ~54px e estourava o `DeltaBadge`.
- **PR #43 — HU-W-09, com ressalva.** `operational_dashboard_screen.dart`
  é **inteiramente demonstração** hoje (`PlaceholderPanel`, "Em breve") -
  não existe fila de incidente, priorização de vulnerabilidade nem
  triagem real em lugar nenhum do app. Entregue só a disposição de 3
  colunas em `large` sobre o mesmo conteúdo honesto - continuar dizendo
  "em breve" pesa mais do que fingir dado real para bater o mockup ao pé
  da letra.

**Ao final:** `flutter analyze` limpo, 158 testes verdes,
`./scripts/prompt check` aprovado, Bucket B em 1/5 (era 0/5).
`docs/19`/`docs/21` atualizados no mesmo commit desta seção.

**O que fica para depois** (não é regressão, é o resto do épico):
`HU-W-11`/`12`/`13` (compliance/insights/briefing - as 3 telas restantes
de W3, nenhuma delas no mockup); `HU-W-04`/`05` (Sprint W1); todo o `W4`
em diante (serviços, wizard, relatório, especialista, transversais). O
sidebar/tipografia da Fase 1 já são a base reutilizável para todas elas.
