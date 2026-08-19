# Modelo de dados — Cloud Firestore

Convenções: coleções em `snake_case` plural; datas como `Timestamp`; todo
documento tem `createdAt` e `updatedAt`; agregados são pré-calculados por
Cloud Functions para que cada card do dashboard custe **uma** leitura.

## Raiz

```
/users/{uid}                     índice global uid → tenant (mínimo)
/invites/{emailMinusculo}        allowlist de admissão
/tenants/{tenantId}              organização cliente
```

### `/users/{uid}`

| Campo | Tipo | Observação |
|---|---|---|
| `tenantId` | string | escrito só por Cloud Function |
| `role` | string | espelho do claim, só para suporte |
| `displayName`, `jobTitle`, `businessUnit`, `photoUrl`, `locale` | string? | editáveis pelo próprio usuário |
| `updatedAt` | timestamp | |

### `/invites/{email}`

| Campo | Tipo |
|---|---|
| `tenantId` | string |
| `role` | `operational` \| `strategic` \| `board` |
| `tenantAdmin` | bool |
| `displayName`, `jobTitle`, `businessUnit` | string? |
| `consumedAt` | timestamp? |

## Por tenant

### `/tenants/{tenantId}` (documento raiz)
`name`, `annualRevenue` (número, mesma moeda dos riscos - usado pelo painel
do board para expressar exposição como percentual da receita),
`businessUnitOwners` (map `businessUnit` → nome/cargo do executivo dono,
para que todo risco tenha um responsável nomeado), `previousQuarterAle`
(soma de `annualLossExpectancy` um trimestre atrás, pré-calculada, só para
o selo de variação trimestral - o cliente nunca soma o histórico de riscos).

```
/tenants/{tenantId}
  ├── members/{uid}
  ├── preferences/{uid}
  ├── metrics/{metricId}
  ├── posture_snapshots/{snapshotId}
  ├── incidents/{incidentId}
  ├── vulnerabilities/{vulnId}
  ├── compliance/{controlId}
  ├── risks/{riskId}
  ├── insights/{insightId}
  ├── surveys/{surveyId}/responses/{uid}
  ├── reports/{reportId}
  └── audit_logs/{logId}
```

### `members/{uid}`
`uid`, `email`, `role`, `tenantId`, `tenantAdmin`, `status`
(`active`|`suspended`), `displayName`, `jobTitle`, `businessUnit`, `photoUrl`.

### `metrics/posture_index` — estratégica e board
Documento único, pré-calculado por Cloud Function para custar uma única
leitura (o cabeçalho "hero number" do painel do CISO lê só este documento).
`overallScore` (0–100), `previousScore` (mês anterior, usado só para o
`delta` mês a mês do domínio), `capturedAt`, `peerMedian` (mediana do setor
para o índice geral - usada também como a única referência de mediana em
todo o painel, inclusive por domínio), `byDomain` (map `domain` → nota
0–100) e `byDomainDelta30d` (map `domain` → variação nos últimos 30 dias,
consumido só pelo detalhe de domínio; um domínio ausente vale 0).

### `incidents/{id}` — persona operacional
`title`, `status` (`open`|`triage`|`contained`|`closed`), `severity`
(`critical`|`high`|`medium`|`low`), `severityRank` (int, para ordenação),
`source`, `assetIds[]`, `assigneeUid`, `openedAt`, `slaDueAt`,
`acknowledgedAt`, `notes`.

### `vulnerabilities/{id}` — operacional e estratégica
`cveId`, `cvssScore`, `epssScore`, `activelyExploited` (bool),
`assetCriticality` (int 1–5), `internetFacing` (bool), `remediationStatus`
(`open`|`in_progress`|`accepted`|`fixed`), `ownerUid`, `dueDate`.

### `posture_snapshots/{id}` — estratégica e board
`domain` (`identity`, `endpoint`, `cloud`, `appsec`, `data`, `thirdparty`),
`score` (0–100), `capturedAt`, `peerMedian`, `delta30d`.

### `compliance/{controlId}` — estratégica
`framework` (`ISO27001`|`NIST_CSF`|`LGPD`|`PCI_DSS`), `controlId`, `status`
(`compliant`|`partial`|`gap`), `evidenceUrl`, `ownerUid`, `lastReviewedAt`,
`domain` (mesmos valores de `posture_snapshots.domain` — permite o
drill-down do painel de postura por domínio até a lista de controles).

### `risks/{id}` — estratégica e board
`title` em linguagem de negócio, `businessUnit`, `inherentScore`,
`residualScore`, `annualLossExpectancy` (número, moeda em `currency`),
`treatment` (`mitigate`|`transfer`|`accept`|`avoid`), `acceptance`
(`pending`|`accepted`|`rejected`|`plan_requested` - o board pediu um plano de
mitigação em vez de aceitar o risco como está), `acceptedByUid`,
`acceptedAt`, `boardNote`, `reviewDueAt`.

A escrita de `acceptance`/`acceptedByUid`/`acceptedAt`/`boardNote` pelo papel
`board` é observada pela Cloud Function `logRiskDecision`, que registra o
evento em `audit_logs` - o cliente nunca escreve a trilha de auditoria
diretamente.

### `reports/{id}`
`title`, `audience` (`operational`|`strategic`|`board`) — **este campo é usado
pela security rule**, `period`, `publishedAt`, `storagePath`, `summary`.

### `insights/{id}` e `surveys/{id}`
`insights`: `topic`, `title`, `summary`, `publishedAt`, `sourceName`,
`sourceUrl`, `isBenchmark` (bool - selo de benchmark de setor).

`surveys`: `title`, `description`, `active` (bool - só uma pesquisa ativa por
vez), `respondentCount` (agregado pré-calculado por Cloud Function) e
`questions[]`, cada uma com `id`, `prompt`, `options[]` e `peerDistribution[]`
(percentual por opção, mesmo índice de `options[]`, também pré-calculado - o
cliente nunca soma respostas). As respostas individuais ficam em
`responses/{uid}` (`answers`, `submittedAt`), isoladas por usuário e
gravadas pelo próprio usuário ao responder.

### `audit_logs/{id}`
`action`, `actorUid`, `payload`, `at`. **Append-only pelo Admin SDK e
ilegível pelo aplicativo.**

## Matriz de acesso (resumo do `firestore.rules`)

| Coleção | operational | strategic | board |
|---|:--:|:--:|:--:|
| `members` | só o próprio | todos | só o próprio |
| `metrics` | leitura | leitura | leitura |
| `posture_snapshots` | — | leitura | leitura |
| `incidents` | leitura + triagem | leitura | — |
| `vulnerabilities` | leitura + remediação | leitura | — |
| `compliance` | — | leitura | — |
| `risks` | — | leitura | leitura + aceite |
| `insights` / `surveys` | — | leitura | leitura |
| `reports` | só `audience` igual ao papel | idem | idem |
| `audit_logs` | — | — | — |

Escrita de dado analítico é sempre exclusiva das Cloud Functions.
