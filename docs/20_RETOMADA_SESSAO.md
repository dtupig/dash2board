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

| Sprint | Entrega | Duração | Status em 05/09/2026 |
|---|---|---|---|
| **S1** | Relatórios entram no produto (merge do PR #18 + correções) | 3 dias | ✅ concluído |
| **S2** | Repositório confiável (config versionada + job de build na CI) | 2 dias | ✅ concluído |
| **S3** | Web no ar — `HU-W-01` a `05` do épico E-W | 1 semana | 🔶 parcial — só `HU-W-01`; `02` a `05` pendentes |
| **S4** | A cena da demo — `W2` + `W3`, painéis em tela larga | 2 semanas | 🔶 parcial — `W2` (`06`/`07`/`08`) feito; `W3` pendente |
| **S5** | Catálogo e RFS na web — `W4` | 1 semana | não iniciado |

**Desvio registrado (não é erro, é decisão de fato):** a execução pulou
direto de `HU-W-01` para as histórias de entrada de `W2` (`06`-`08`),
sem fechar `HU-W-02` a `05` primeiro - a ordem do plano previa o shell
adaptativo e o roteamento antes da jornada de entrada. Na prática,
`HU-W-06` e `07` já vinham prontas do produto mobile (autofill, mensagem
genérica de credencial, tela de acesso pendente) e só precisaram de
validação; só `HU-W-08` exigiu código novo. Isso deixou o shell adaptativo
(`HU-W-02`, com `NavigationRail`) e o roteamento com negativa explícita em
link profundo (`HU-W-03`) como a lacuna real do épico até agora - nenhum dos
dois foi iniciado.

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

**O que ficou pendente do épico web:** `HU-W-02` (shell adaptativo com
`NavigationRail` - hoje não existe nenhuma navegação além de tela cheia com
`context.go/push`, nem bottom nav mobile) e `HU-W-03` (negativa explícita em
link profundo sem permissão + preservar a URL de destino para depois do
login - hoje o roteador redireciona em silêncio para o painel do próprio
papel, funciona mas não avisa por quê) e `HU-W-04` (sessão de 12h / limpeza
de armazenamento no logout - nada disso existe ainda).
