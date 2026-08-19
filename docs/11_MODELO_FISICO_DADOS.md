# Modelo físico de dados — Firebase

Documento de DBA: decisão de motor, convenções, mapa completo de coleções,
estratégia de agregação, índices, ciclo de vida, custo e recuperação.

---

## 1. Decisão de motor: por que **não** Realtime Database no núcleo

O pedido original citava Realtime Database. Recomendo **Cloud Firestore como
sistema de registro**, e RTDB apenas para presença e sinais efêmeros. O motivo
não é preferência — é um impedimento de segurança.

### O impedimento

**As regras do RTDB são em cascata.** Conceder leitura em um nó libera
**todo** o conteúdo abaixo dele, e não existe forma de restringir um filho
depois. A documentação do Firebase é explícita: regras em um nó mais raso
sobrescrevem regras mais profundas.

Nosso modelo depende exatamente do contrário. Dentro de um mesmo cliente:

| Precisa | RTDB consegue? |
|---|---|
| Board lê `reports` mas **nunca** as seções `exploitProof` | Não |
| Ninguém lê `audit_logs`, nem staff | Não, se estiver sob um nó legível |
| Cliente não lê relatório em `draft`, mas lê `published` na mesma coleção | Não |
| `operational` lê só as próprias RFS; `strategic` lê todas | Não sem duplicar a árvore |

No Firestore, regras são **por documento e não cascateiam**. `match
/reports/{id}` pode liberar, e `match /reports/{id}/sections/{s}` pode negar.
É essa propriedade que sustenta a matriz de acesso das quatro personas.

### Os outros motivos

| Critério | Firestore | RTDB |
|---|---|---|
| Consulta composta (2+ campos) | Sim, com índice | Não — um `orderByChild` por vez |
| Filtrar por severidade **e** status **e** ordenar por data | Sim | Exigiria campo concatenado artificial |
| Collection group (buscar em todos os tenants) | Sim | Não existe |
| Escala por documento | Horizontal | Um único JSON; hot node vira gargalo |
| Exportação e PITR nativos | Sim | Backup diário, sem PITR |
| Regras com `get()` de outro documento | Sim | Limitado |

### Onde o RTDB ganha, e onde vamos usá-lo

RTDB tem latência menor e um recurso que o Firestore não tem: **presença
confiável via `onDisconnect`**. Usaremos para:

1. `presence` — quem está online (útil no war room de crise);
2. `sync_status` — heartbeat da coleta forense offline do especialista;
3. `warroom` — mensagens efêmeras durante um incidente ativo.

**Regra dura: nada sensível no RTDB.** Sem achado, sem evidência, sem dado
pessoal, sem conteúdo de relatório. A árvore é rasa e o conteúdo é descartável.

> Se você quiser o núcleo em RTDB mesmo assim, é possível — mas exigiria
> duplicar a árvore por nível de acesso (`/tenants/{t}/public`,
> `/restricted`, `/confidential`…), triplicando escrita e criando risco de
> divergência entre cópias. Como especialista, não recomendo, e registro aqui
> que a alternativa foi avaliada.

---

## 2. Convenções (valem para todo documento)

| Convenção | Regra |
|---|---|
| Nomes de coleção | `snake_case`, plural |
| Nomes de campo | `camelCase` |
| Enum | string `snake_case`, **nunca** inteiro — inteiro quebra em silêncio quando a ordem muda |
| Data | `Timestamp`, sempre `FieldValue.serverTimestamp()` na escrita |
| Auditoria mínima | `createdAt`, `updatedAt`, `createdBy`, `updatedBy` |
| Versão de esquema | `schemaVersion` (int) em todo documento raiz |
| Tenant desnormalizado | `tenantId` em **todo** documento, mesmo sob `/tenants/{tenantId}` — habilita collection group com filtro seguro |
| Exclusão | `deletedAt` (soft delete). `audit_logs` e `custody_records` **nunca** são apagados |
| ID | Determinístico quando existe chave natural; `auto-id` quando não existe |

### IDs determinísticos (tornam o seed idempotente)

```
contracted_services/{serviceKey}              → "web_api"
posture_snapshots/{yyyy-MM}_{domain}          → "2026-08_cloud"
compliance/{framework}_{controlId}            → "iso27001_A.8.9"
members/{uid}
preferences/{uid}
```

Rodar o seed duas vezes não duplica nada — requisito do prompt 7.

---

## 3. Mapa de coleções

```
/config/service_catalog                 versão publicada dos 44 serviços
/config/regulatory_deadlines            prazos por regime (revisado pelo jurídico)

/users/{uid}                            índice global: uid → tenant ou staff
/invites/{emailLower}                   allowlist de admissão
/staff/{uid}                            perfil do especialista Elytron
/staff/{uid}/assignments/{tenantId}     atribuição explícita (espelha o claim)

/tenants/{tenantId}
  ├── members/{uid}
  ├── preferences/{uid}
  ├── contracts/{contractId}
  ├── contracted_services/{serviceKey}
  ├── service_requests/{requestId}
  │     └── events/{eventId}            trilha da RFS (append-only)
  ├── metrics/{metricId}                agregados prontos para o painel
  ├── posture_snapshots/{id}
  ├── incidents/{incidentId}
  ├── vulnerabilities/{vulnId}
  ├── compliance/{controlId}
  ├── risks/{riskId}
  ├── insights/{insightId}
  ├── surveys/{surveyId}/responses/{uid}
  ├── reports/{reportId}
  │     ├── sections/{sectionKey}       classificação POR SEÇÃO
  │     ├── findings/{findingId}
  │     ├── comments/{commentId}
  │     └── versions/{version}
  ├── custody_records/{recordId}        append-only, sem update, sem delete
  ├── notifications/{notificationId}
  └── audit_logs/{logId}                append-only, ilegível por TODOS no cliente
```

### Por que `sections` é subcoleção e não campo

Porque a classificação é **por seção**. Se as seções fossem um array dentro do
documento do relatório, a regra de segurança só poderia liberar ou negar o
documento inteiro — e o board veria a prova de conceito de exploração. Esta é a
decisão de modelagem mais importante do esquema.

### Documentos-chave

**`/tenants/{tid}`** — `name`, `cnpj`, `segment`, `annualRevenue`, `currency`,
`dataResidency`, `materialFactThreshold`, `locale`, `contractIds[]`,
`retentionPolicy`, `status`, `schemaVersion`.

**`/tenants/{tid}/contracts/{id}`** — `type` (`project`|`retainer`|`managed`),
`startsAt`, `endsAt`, `totalHours`, `consumedHours`, `slaHours`, `serviceKeys[]`,
`renewalAt`. É o que responde "quanto do meu retainer sobrou".

**`/tenants/{tid}/reports/{id}`** — `serviceKey`, `category`, `title`,
`status`, `classification`, `version`, `authorUid`, `reviewerUid`,
`publishedAt`, `materialFact` (bool), `audienceRoles[]` (derivado),
`executiveSummary`, `referencePeriod`.
`materialFact` e `audienceRoles` são **calculados no backend** e usados
diretamente pela regra — a regra nunca recalcula lógica de negócio.

**`/tenants/{tid}/reports/{id}/sections/{key}`** — `title`, `order`,
`sensitivity`, `minimumRole`, `body`, `redactedFor[]`.

**`/tenants/{tid}/custody_records/{id}`** — `serviceKey`, `deviceType`,
`serial`, `imei`, `acquisitionMethod`, `acquisitionHash`, `photoHashes[]`,
`custodianName`, `custodianDocument`, `signatureStoragePath`, `legalBasis`,
`purpose`, `collectedAt`, `geo`, `collectedByUid`, `sealHash`,
`supersedesRecordId`. Correção cria novo registro encadeado.

**`/tenants/{tid}/audit_logs/{id}`** — `action`, `actorUid`, `actorKind`
(`client`|`staff`), `targetPath`, `payload`, `at`, `expiresAt`.

---

## 4. Agregação: onde o custo é decidido

O painel do CISO, lido "ingenuamente", custa ~200 leituras por abertura. Com
agregados, custa **~12**. A diferença não é otimização: é a diferença entre
caber e não caber no orçamento com 50 clientes.

Documentos agregados, escritos **só** por Cloud Functions:

| Documento | Contém | Atualizado por |
|---|---|---|
| `metrics/posture_summary` | índice geral, por domínio, mediana do setor, delta | trigger em `posture_snapshots` |
| `metrics/compliance_summary` | % por framework, contagem de lacunas | trigger em `compliance` |
| `metrics/risk_summary` | ALE total, top 5, por unidade de negócio | trigger em `risks` |
| `metrics/vuln_summary` | abertas por severidade, SLA, MTTR | trigger em `vulnerabilities` |
| `metrics/delivery_summary` | entregas, RFS por estado, retainer consumido | trigger em `service_requests`, `reports` |

Regra: **a UI lê agregado; a lista detalhada só é carregada no drill-down.**

---

## 5. Índices

Já existem em `firestore.indexes.json` os de postura, vulnerabilidade, risco,
compliance, relatórios e insights. Acrescentar:

| Coleção | Campos |
|---|---|
| `service_requests` | `status` ASC, `createdAt` DESC |
| `service_requests` | `requestedByUid` ASC, `createdAt` DESC |
| `reports` | `status` ASC, `publishedAt` DESC |
| `reports` | `serviceKey` ASC, `publishedAt` DESC |
| `reports` | `materialFact` ASC, `publishedAt` DESC |
| `custody_records` | `serviceKey` ASC, `collectedAt` DESC |
| `notifications` | `readAt` ASC, `createdAt` DESC |

Collection group em `reports` (para a fila do especialista entre clientes) exige
índice de grupo **e** filtro obrigatório por `tenantId in [atribuídos]`.

---

## 6. Ciclo de vida, retenção e LGPD

| Dado | Retenção sugerida | Mecanismo |
|---|---|---|
| `audit_logs` | 5 anos | TTL nativo em `expiresAt` |
| `custody_records` | conforme contrato e processo judicial | **sem TTL**; expurgo manual documentado |
| Evidência forense (Storage) | conforme contrato | regra de ciclo de vida no bucket |
| `notifications` | 180 dias | TTL |
| `posture_snapshots` | 5 anos | sem TTL (série histórica é o produto) |
| Relatórios publicados | vida do contrato + 5 anos | sem TTL |

Dado pessoal em coleta forense exige `legalBasis` e `purpose` gravados no
próprio registro. Sem esses campos, a escrita é recusada pela regra — a
conformidade vira invariante do banco, não disciplina do usuário.

---

## 7. Recuperação e ambientes

- **PITR habilitado** (janela de 7 dias) nos três ambientes.
- **Exportação diária agendada** para bucket GCS com versionamento e bloqueio
  de exclusão.
- **Teste de restauração trimestral** em projeto descartável. Backup não
  testado não é backup.
- Três projetos: `dev`, `stg`, `prd`. Promoção só por CI, nunca manual.
- **App Check obrigatório** em produção: sem ele, qualquer um com a chave
  pública do app fala direto com o seu banco.

---

## 8. Anexo — Realtime Database (apenas efêmero)

```
/presence/{tenantId}/{uid}      { state, lastChangedAt, kind }
/sync_status/{uid}              { pendingCustodyRecords, lastSyncAt }
/warroom/{tenantId}/{incidentId}/messages/{msgId}
                                { uid, name, text, at }
```

Regras (cascata é aceitável aqui porque **nada sensível vive nesta árvore**):

```json
{
  "rules": {
    "presence": {
      "$tenantId": {
        ".read": "auth != null && (auth.token.tenantId === $tenantId || (auth.token.staff === true && root.child('staff_assignments/' + auth.uid + '/' + $tenantId).exists()))",
        "$uid": { ".write": "auth != null && auth.uid === $uid" }
      }
    },
    "sync_status": {
      "$uid": {
        ".read": "auth != null && auth.uid === $uid",
        ".write": "auth != null && auth.uid === $uid"
      }
    },
    "warroom": {
      "$tenantId": {
        ".read": "auth != null && auth.token.tenantId === $tenantId",
        "$incidentId": {
          "messages": {
            ".write": "auth != null && auth.token.tenantId === $tenantId",
            "$msgId": { ".validate": "newData.child('text').val().length <= 2000" }
          }
        }
      }
    },
    "staff_assignments": { ".read": false, ".write": false },
    "$other": { ".read": false, ".write": false }
  }
}
```

`staff_assignments` é espelhado pela Cloud Function `assignSpecialist`, porque
o RTDB não enxerga os claims com a mesma flexibilidade do Firestore.
