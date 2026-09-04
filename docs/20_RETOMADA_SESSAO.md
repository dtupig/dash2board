# Retomada de sessão — estado em 03/09/2026

Documento vivo. O `docs/17_PONTO_DE_RETOMADA.md` descreve o estado até
25/08/2026 e **está desatualizado num ponto crítico** (ver item 1). Este aqui
é o estado real.

**Palavra-chave para retomar:** escreva **`RETOMAR D2B`** no início da conversa.

---

## 1. Correção importante ao docs/17

O `docs/17` diz que o **prompt 11 está "destravado, pronto para executar"**.
Ele **já foi executado**. Existe o branch `prompt/11-relatorios-especialistas`
e o **PR #18, aberto e verde desde 25/08/2026**, nunca mesclado.

| PR #18 | |
|---|---|
| Estado | `OPEN`, `MERGEABLE`, `mergeStateStatus: CLEAN`, não-draft |
| Checks | 3/3 `SUCCESS` |
| Tamanho | 53 arquivos, +4.906 / −63 |
| Validado localmente | `flutter analyze` limpo · `flutter test` 142 testes verdes (Flutter 3.47.1) |
| Conteúdo | 8 modelos especialistas, `ReportAccessPolicy`, `MaterialFactEvaluator`, visualizador em 3 profundidades, mock + Firestore, rules e `test/rules/reports.spec.ts` |

**Ação pendente:** mesclar. As 3 suposições de produto do PR foram aprovadas
pelo PO em 03/09/2026 (board nunca baixa relatório; `operational` nunca vê
`personalData`/`chainOfCustody`; visão do board é curada, não filtrada).

## 2. Decisões tomadas pelo PO em 03/09/2026

| # | Decisão | Valor |
|---|---|---|
| Marco | Próximo objetivo de negócio | **Demo vendável para prospect** |
| Web | Quando a trilha web entra | **Em paralelo, a partir de S2** |
| Config nativa | `GoogleService-Info.plist` no git? | **Versionar e afrouxar o guardrail** |
| PR #18 | As 3 regras assumidas | **Aprovadas como estão** |

## 3. Plano vigente — sprints por valor de negócio

| Sprint | Entrega | Duração |
|---|---|---|
| **S1** | Relatórios entram no produto (merge do PR #18 + correções) | 3 dias |
| **S2** | Repositório confiável (config versionada + job de build na CI) | 2 dias |
| **S3** | Web no ar — `HU-W-01` a `05` do épico E-W | 1 semana |
| **S4** | A cena da demo — `W2` + `W3`, painéis em tela larga | 2 semanas |
| **S5** | Catálogo e RFS na web — `W4` | 1 semana |

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
   falha (antes assumia sucesso incondicional). **Pendência não resolvida:**
   `functions/` não tem suíte de testes automatizados (nenhuma das 6
   functions tem) — a validação desta PR foi só `tsc --noEmit` limpo, mesmo
   nível de rigor das functions vizinhas. Registrar como achado de
   infraestrutura de teste se isso incomodar antes da demo.
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
5. **Novo — `watchSections` tem o mesmo bug de lista do item 1.** A regra de
   `list` em `reports/{reportId}/sections/{sectionId}` decide por
   `canSeeSection(resource.data.sensitivity, ...)`, variável por documento e
   sem `where` correspondente na query (`firestore_reports_repository.dart`,
   `watchSections`). Mesma correção do item 1 se aplica: desnormalizar um
   `visibleRoles` por seção e filtrar por `array-contains`. Não corrigido
   nesta rodada para manter o PR do item 1 revisável; mesma pendência de
   "quem grava" (prompt 13).

## 5. Ambiente

- **O clone limpo não compila.** Causa e contorno em
  [`.claude/skills/rodar-o-app/SKILL.md`](../.claude/skills/rodar-o-app/SKILL.md)
  — o skill é carregado sozinho quando se pede para rodar o app.
- A CI tem 3 jobs e **nenhum roda `flutter build`**.
- Config nativa regenerada em 03/09/2026 via
  `flutterfire configure --project=elytron-d2b-dev --platforms=ios,android`.
- App validado rodando no simulador iPhone 17 / iOS 26.5 em 03/09/2026.

## 6. Pendências fora do código

- [ ] Mesclar o PR #18 (aguarda aval)
- [ ] `sudo rm -rf ~/.npm` — 80 arquivos do `root` sobraram no cache
- [ ] Exclusões do Defender para `DerivedData`, `CoreSimulator` e `.pub-cache`
- [ ] Reiniciar a máquina (swap com 7,3 GB presos do período de disco cheio)
- [ ] Revisar o `git status`: há mudanças não commitadas em `firebase.json`,
      `ios/Flutter/*.xcconfig`, `project.pbxproj` e 2 `Package.resolved`
      **deletados** (o `pod install` migrou de SwiftPM para CocoaPods)

## 7. Novo neste ciclo

- [`prompts/12A_PROVISIONAMENTO_DE_TENANT.md`](prompts/12A_PROVISIONAMENTO_DE_TENANT.md)
  — fecha o **D-21**, que estava registrado como decisão pendente mas era, na
  verdade, especificação faltando: nenhum prompt de 11 a 14 descrevia a função
  de criação de tenant nem resolvia o bootstrap do primeiro `staffAdmin`.
