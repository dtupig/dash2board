# Prompt 11 — Relatórios especialistas por categoria e por persona

**Entrega:** os 8 modelos de relatório (um por categoria de serviço), o
visualizador que apresenta o **mesmo relatório em três profundidades**
conforme a persona, e o mecanismo de fato relevante que leva ao board apenas o
que muda decisão.

**Decisões já tomadas** (não reabra no prompt):
- 8 modelos por categoria, com campos específicos por serviço quando necessário.
- Relatório só existe para serviço contratado.
- Board não abre nem aprova demanda; recebe relatório apenas por gatilho de
  fato relevante.

> **Este prompt tem um eixo que os anteriores não têm: proteção de conteúdo.**
> Relatório de pentest carrega prova de conceito de exploração. Relatório
> forense carrega cadeia de custódia e, muitas vezes, dado pessoal. Tratar isso
> como "mais uma tela" é o erro que transforma um produto de segurança em um
> vetor de vazamento.

---

````text
# CONTEXTO FIXO
Projeto: Elytron Dash2Board (`elytron_dash2board`), Flutter + Material 3 + Firebase.
LEIA ANTES, como fonte de verdade:
  docs/08_CATALOGO_SERVICOS.md   <- 8 categorias, 44 serviços, classificações
  docs/02_PERSONAS.md            <- as três personas e o que cada uma precisa
  docs/01_MODELO_DADOS_FIRESTORE.md
  lib/features/services/          <- catálogo e RFS (prompt 10)
  lib/core/widgets/charts/        <- kit de visualização (prompt 3)
NÃO invente categoria, serviço nem classificação fora do catálogo.

# REGRAS DE CÓDIGO (obrigatórias, sem exceção)
- `flutter analyze` deve terminar em "No issues found!"; `deprecated_member_use`
  é tratado como ERRO.
- Opacidade: somente `Color.withValues(alpha: ...)`. `withOpacity` proibido.
- Proibido: `ColorScheme.background`/`onBackground`/`surfaceVariant`;
  `CardTheme`/`DialogTheme`/`TabBarTheme` em `ThemeData`;
  `pageTransitionsTheme`; `MaterialState*`.
- Riverpod só com APIs estáveis (`Provider`, `StreamProvider`, `Notifier`,
  `AsyncNotifier`). Sem code generation.
- Gráfico só dentro de `ChartFrame`; cor de gráfico só de `ChartTokens`.
- Domínio em Dart puro. Nenhum arquivo de `presentation/` importa
  `cloud_firestore` ou `firebase_auth`.
- pt-BR na interface e comentários; identificadores em inglês.
- Arquivos completos com imports. Nunca escreva "...". Máximo 250 linhas por
  arquivo.

# PARTE 1 — MODELO COMUM

`lib/features/reports/domain/report.dart`:

`ServiceReport` (base de todos): `id`, `tenantId`, `serviceKey`, `category`,
`title`, `referencePeriod`, `deliveredAt`, `version`, `elytronLeadName`,
`classification` (enum `ReportClassification`: `publicInternal`, `restricted`,
`confidential`, `secret`), `executiveSummary` (3 a 5 frases, linguagem de
negócio), `businessImpact`, `materialFacts` (List<MaterialFact>),
`nextSteps` (List<ActionItem>), `attachments` (List<ReportAttachment>).

`ReportSection`: `key`, `title`, `minimumRole` (a persona mais restrita que
pode ver esta seção), `sensitivity` (enum `SectionSensitivity`: `narrative`,
`technical`, `exploitProof`, `personalData`, `chainOfCustody`), `body`.

`ActionItem`: `title`, `ownerName`, `dueAt`, `effort`, `priority`.

`ReportAttachment`: `label`, `storagePath`, `sizeBytes`, `sha256`,
`classification`.

# PARTE 2 — OS 8 MODELOS ESPECIALISTAS

Um arquivo por modelo em `lib/features/reports/domain/models/`. Cada um estende
o comum e acrescenta o que a disciplina realmente entrega. Se você não souber o
que um campo significa no ofício, **pergunte em vez de inventar** — dado errado
num relatório de segurança é pior que dado ausente.

1. `pentest_report.dart` — `PentestReport`
   `findings` (`PentestFinding`: `title`, `cvssVector`, `cvssScore`,
   `severity`, `cweId`, `affectedAssets`, `businessConsequence`,
   `reproductionSteps` **[exploitProof]**, `evidenceRefs` **[exploitProof]**,
   `remediation`, `retestStatus`), `scopeCovered`, `methodology`
   (PTES/OWASP/OSSTMM), `testWindow`, `retestSummary`.
   Campos por serviço: `mobile` acrescenta plataformas e versão do app;
   `code_review` acrescenta repositórios, commit e cobertura;
   `reverse_engineering` acrescenta binário, hash e proteções encontradas;
   `ai_pentest` acrescenta modelo, vetor (prompt injection, extração de dados,
   envenenamento) e guardrails testados.

2. `appsec_report.dart` — `AppSecReport`
   `pipelineCoverage`, `findingsByStage` (SAST/DAST/manual),
   `securityDebtTrend`, `falsePositiveRate`, `trainedDevelopers`,
   `championsActive`, `policyAdoption`.

3. `attack_surface_report.dart` — `AttackSurfaceReport`
   `assetsDiscovered`, `newExposures`, `closedExposures`, `shadowItFound`,
   `certificateIssues`, `exposedServices`, `changeTimeline`.

4. `incident_response_report.dart` — `IncidentResponseReport`
   `incidentTimeline` (List<TimelineEvent>), `initialVector`, `dwellTimeHours`,
   `containmentAt`, `eradicationAt`, `iocs` **[technical]**,
   `chainOfCustody` **[chainOfCustody]**, `affectedDataSubjects`
   **[personalData]**, `regulatoryNotificationRequired` (bool),
   `lessonsLearned`, `exerciseScore` (para tabletop/wargame/simulação).
   Campos por serviço: as coletas forenses acrescentam `deviceIdentifiers`,
   `acquisitionHash`, `custodianName`, `acquisitionMethod`;
   `forensics_uam` acrescenta `monitoredUsers` e a base legal do monitoramento.

5. `governance_report.dart` — `GovernanceReport`
   `framework`, `maturityByDomain`, `targetMaturity`, `gaps`,
   `roadmapPhases`, `estimatedInvestment`, `regulatoryDeadlines`.

6. `vuln_management_report.dart` — `VulnManagementReport`
   `openBySeverity`, `slaCompliance`, `meanTimeToRemediate`, `backlogTrend`,
   `activelyExploitedOpen`, `topOffendingAssets`.

7. `third_party_report.dart` — `ThirdPartyReport`
   `suppliersAssessed`, `riskTierDistribution`, `criticalSuppliers`,
   `contractClauseGaps`, `concentrationRisk`, `fourthPartyExposure`.

8. `defense_report.dart` — `DefenseReport`
   `controlCoverage`, `detectionsByTactic` (MITRE ATT&CK), `tuningActions`,
   `falsePositiveReduction`, `phishingClickRate`, `credentialsFoundInLeaks`
   **[personalData]**, `hardeningRecommendations`.

# PARTE 3 — PROTEÇÃO DE CONTEÚDO (o eixo crítico)

`lib/features/reports/domain/report_access_policy.dart` — Dart puro, testável:

```
abstract final class ReportAccessPolicy {
  static bool canOpen(UserRole role, ReportClassification c, {required bool isMaterialFact});
  static bool canSeeSection(UserRole role, SectionSensitivity s);
  static bool canDownload(UserRole role, ReportClassification c);
  static bool requiresReadReceipt(ReportClassification c);
  static String redactionNotice(UserRole role);
}
```

Regras, e elas são duras:
- `board` **nunca** vê seção com sensibilidade `exploitProof`, `personalData`
  ou `chainOfCustody`. Em nenhuma classificação, sob nenhuma condição.
- `board` só abre relatório quando `isMaterialFact == true` OU a classificação
  é `publicInternal`.
- `operational` vê `technical` e `exploitProof`, mas apenas em relatórios
  `restricted`/`confidential` — nunca em `secret`.
- `strategic` vê tudo, e leitura de `secret` **exige registro** (`readReceipt`)
  gravado em `audit_logs` antes de renderizar o conteúdo.
- Seção suprimida **aparece como suprimida**, com o motivo em uma frase. Nunca
  simplesmente some: o leitor precisa saber que existe conteúdo que ele não
  está vendo — essa é a diferença entre redação e engano.

Implementação obrigatória no visualizador:
- Marca d'água diagonal contínua com `uid`, nome e data-hora em toda tela de
  relatório `confidential` ou `secret`, e no PDF exportado.
- `canDownload` falso desabilita compartilhar e exportar, com explicação.
- Nada de anexo sensível em cache no disco: baixe para memória, renderize e
  descarte. Se precisar de arquivo temporário, apague no `dispose`.
- Toda abertura de relatório grava evento em `audit_logs` (no mock, em
  memória): quem, qual, quando, qual classificação.
- Android: aplique `FLAG_SECURE` nas telas `secret`. **Declare no código, em
  comentário, que o iOS não oferece equivalente confiável** — não finja
  proteção que não existe.

# PARTE 4 — FATO RELEVANTE (o gatilho para o board)

`lib/features/reports/domain/material_fact.dart`:

`MaterialFact`: `trigger` (enum), `title` em linguagem de negócio,
`consequence` (o que acontece se nada for feito), `detectedAt`,
`estimatedExposure` (valor em Real, opcional), `decisionRequired` (bool).

`MaterialFactTrigger` — a lista fechada, e cada gatilho tem uma regra
determinística implementada em `MaterialFactEvaluator.evaluate(report)`:

| Gatilho | Dispara quando |
|---|---|
| `confirmedCompromise` | há evidência de comprometimento ativo |
| `personalDataExposure` | dado pessoal exposto ou `regulatoryNotificationRequired` |
| `criticalInternetFacing` | achado crítico em ativo exposto à internet |
| `regulatoryDeadlineRisk` | prazo regulatório em risco nos próximos 90 dias |
| `businessContinuityRisk` | processo crítico de negócio ameaçado |
| `financialExposureThreshold` | exposição estimada acima do limite do tenant |
| `criticalSupplierRisk` | fornecedor crítico com risco não tratado |
| `leakedCorporateCredentials` | credencial corporativa válida achada em vazamento |

`MaterialFactEvaluator` é **pura e determinística**: mesmo relatório, mesmo
resultado. Nada de heurística implícita. O limite financeiro vem da
configuração do tenant, não de constante no código.

Quando um relatório entra com fato relevante:
- ele passa a ser visível ao `board`, **apenas na visão de board**;
- gera uma entrada na lista de "decisões pendentes" do painel do board;
- notifica CISO e board (no mock, uma lista em memória; a integração com push
  fica para depois).

# PARTE 5 — O VISUALIZADOR

`lib/features/reports/presentation/report_viewer_screen.dart`, rota
`/relatorios/:reportId`. **Um relatório, três profundidades.**

Cabeçalho comum: serviço, período, versão, responsável Elytron, selo de
classificação (com cor de status, ícone e rótulo — nunca só cor) e, quando
houver, o selo de fato relevante.

- **Visão `board`**: sumário executivo, os fatos relevantes com consequência e
  exposição financeira, e as decisões que dependem dele. Nada mais. Sem CVE,
  sem CVSS, sem nome de ferramenta, sem passo de reprodução. Se uma sigla é
  inevitável, ela vem explicada na mesma linha.
- **Visão `strategic`**: sumário, impacto no negócio, achados agregados por
  severidade e por domínio, tendência contra a entrega anterior do mesmo
  serviço, compliance afetado, plano de ação com dono e prazo, e o caminho
  para a evidência.
- **Visão `operational`**: tudo o que a alçada permite, com a lista completa de
  achados, filtros por severidade/status/ativo, passos de reprodução e
  remediação, e o estado de reteste.

Comum às três: navegação por seções, busca dentro do relatório, comparação com
a entrega anterior do mesmo serviço (quando existir) e exportação respeitando
`canDownload`.

`lib/features/reports/presentation/reports_list_screen.dart`, rota
`/relatorios`: agrupada por serviço contratado, com filtro por categoria,
período e classificação; destaque para os não lidos e para os com fato
relevante.

# PARTE 6 — DADOS
`reports_repository.dart` (interface) + mock + firestore, no padrão já
existente. Coleção `/tenants/{tenantId}/reports/{reportId}` com `audience`
derivado da classificação, e subcoleção `sections`.

O mock precisa de **8 relatórios, um por categoria**, com dados que sustentem
uma demonstração: pelo menos dois com fato relevante (um
`criticalInternetFacing`, um `personalDataExposure`), um `secret` (perícia
forense) para exercitar o registro de leitura, e um com comparação contra
entrega anterior.

Atualize `firestore.rules`: leitura de relatório governada por classificação +
persona + `materialFact`, espelhando `ReportAccessPolicy`. A regra e a classe
Dart precisam concordar — divergência entre as duas é uma falha de segurança,
não um detalhe.

# TESTES
`test/reports/`:
- `report_access_policy_test.dart` — matriz COMPLETA persona × classificação ×
  sensibilidade de seção. Inclua explicitamente: board nunca vê `exploitProof`,
  `personalData` nem `chainOfCustody`; operational não abre `secret`; leitura de
  `secret` exige registro.
- `material_fact_evaluator_test.dart` — um caso positivo e um negativo para
  cada um dos 8 gatilhos; determinismo (mesmo relatório duas vezes, mesmo
  resultado).
- `report_viewer_test.dart` — na visão board, varra a árvore de widgets e
  garanta que NENHUM texto contém termo da lista proibida (CVE, CVSS, payload,
  exploit, hash, IOC, nome de ferramenta); seção suprimida aparece com aviso.
- `reports_list_test.dart` — só lista serviços contratados.
Use `pump(Duration)`, nunca `pumpAndSettle`.

# CRITÉRIOS DE ACEITE
1. O mesmo relatório de pentest aberto pelas três personas mostra três
   conteúdos diferentes, e o do board não contém nenhum termo técnico proibido.
2. Nenhuma seção some em silêncio: toda supressão é visível e justificada.
3. Relatório `secret` só abre para `strategic` e grava o registro de leitura
   ANTES de renderizar.
4. Os 8 gatilhos de fato relevante têm teste positivo e negativo.
5. `ReportAccessPolicy` e `firestore.rules` concordam — demonstre isso.
6. `flutter analyze` limpo e `flutter test` verde.

# COMO RESPONDER
Ordem obrigatória: modelo comum → `ReportAccessPolicy` + testes → os 8 modelos
→ `MaterialFactEvaluator` + testes → dados mock → telas. A política vem antes
das telas de propósito: é ela que define o que a tela pode mostrar.

Ao final rode `flutter analyze` e `flutter test`, corrija até zerar, e
apresente: (a) a matriz de acesso implementada, (b) o texto integral da visão
`board` de um relatório de pentest do mock, para eu conferir se está mesmo
livre de jargão e de conteúdo sensível.
````
