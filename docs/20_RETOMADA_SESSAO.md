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

1. **A lista de relatórios quebra no Firestore real.** `watchReports` faz query
   de coleção sem `where`, e as rules decidem por documento — se um documento
   reprovar, a query inteira retorna `permission-denied`. Um usuário
   `operational` num tenant com qualquer relatório `secret` não vê lista
   nenhuma, e cai na tela de "acesso não provisionado". Invisível hoje porque o
   dia a dia roda com `MOCK=true` e **nenhum teste de rules usa query** (zero
   `getDocs` em todo `test/rules/`).
   *Correção:* desnormalizar `audienceRoles` no documento e filtrar por
   `array-contains` na query — o parâmetro `roleWire`, hoje ignorado pela
   implementação Firestore, passa a ter uso.
2. **`recordReadReceipt` é um no-op.** O invariante "relatório `secret` exige
   registro de leitura antes de renderizar" não é cumprido: falta a Cloud
   Function. `functions/src/index.ts` já tem o helper `writeAudit`.
3. **Índice defasado.** `firestore.indexes.json` declara
   `reports: ['audience','publishedAt']`; o código abandonou `audience` e
   ordena por `deliveredAt`.
4. **`scripts/audit.sh` valida menos que o `CLAUDE.md` exige** — não checa
   `pumpAndSettle`, `CardTheme(`, `pageTransitionsTheme`, as fronteiras de
   camada, nem o limite de 250 linhas (há **14 arquivos** acima dele no `main`,
   o maior com 744).

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
