# Prompt 14 — Estrutura física de dados no Firebase

**Entrega:** o esquema materializado — módulo de schema em Dart, conversores
tipados, regras consolidadas para as 4 personas, índices, seed determinístico,
agregados por Cloud Function, presença em RTDB, políticas de TTL e testes.

**Leia antes:** [`../11_MODELO_FISICO_DADOS.md`](../11_MODELO_FISICO_DADOS.md)
(o modelo) e [`../12_OPERACAO_FIREBASE.md`](../12_OPERACAO_FIREBASE.md)
(os comandos). Este prompt implementa o que está lá; não redecide.

**Pré-requisito:** prompts 10, 11 e 12 aplicados. Este prompt consolida.

---

````text
# CONTEXTO FIXO
Projeto: Elytron Dash2Board (`elytron_dash2board`), Flutter + Firebase.
Atue como DBA especialista em Firestore, não como desenvolvedor de UI.
LEIA ANTES, como fonte de verdade:
  docs/11_MODELO_FISICO_DADOS.md   <- ESQUEMA. Não invente coleção nem campo.
  docs/12_OPERACAO_FIREBASE.md
  docs/08_CATALOGO_SERVICOS.md     <- os 44 serviços
  docs/09_PERSONA_ESPECIALISTA.md  <- a 4ª persona e o modelo de staff
  firestore.rules, firestore.indexes.json, functions/src/index.ts
  lib/core/config/firestore_paths.dart

# REGRAS DE CÓDIGO (obrigatórias)
- `flutter analyze` em "No issues found!"; `deprecated_member_use` é ERRO.
- Opacidade só com `Color.withValues(alpha: ...)`; sem `MaterialState*`;
  sem `pageTransitionsTheme`; sem `CardTheme`/`DialogTheme`/`TabBarTheme`.
- Riverpod só com APIs estáveis. Sem code generation.
- Domínio em Dart puro; `presentation/` não importa Firebase.
- Todo repositório recebe `tenantId` explícito.
- pt-BR na interface e comentários; identificadores em inglês.
- Arquivos completos com imports. Nunca escreva "...". Máximo 250 linhas.

# TAREFA

## A) Contrato de esquema — `lib/core/data/schema.dart`
Constantes de nome de coleção e campo, uma única vez, sem string mágica em
lugar nenhum. Inclui `kSchemaVersion` (comece em 1) e os nomes dos documentos
agregados.

Estenda `firestore_paths.dart` com os caminhos novos: `staff`, `assignments`,
`contracts`, `contractedServices`, `serviceRequests`, `reportSections`,
`reportFindings`, `custodyRecords`, `notifications`, `config`.

## B) Conversores tipados — `lib/core/data/converters/`
Para cada entidade, um par `fromFirestore` / `toFirestore` **explícito**, com:
- `Timestamp` → `DateTime` na entrada e `FieldValue.serverTimestamp()` na saída;
- enum ↔ string `snake_case`, com fallback seguro na leitura;
- `schemaVersion` escrito sempre; leitura de versão desconhecida **futura**
  registra aviso e degrada com segurança, nunca explode;
- campo ausente vira o padrão declarado, nunca `null` inesperado.

Use `withConverter<T>` nas referências. Nada de `Map<String, dynamic>` cru
atravessando para o domínio.

## C) Guarda anti-vazamento — `lib/core/data/tenant_guard.dart`
Toda leitura/escrita passa por um helper que exige `tenantId` não vazio e
compara com o tenant em foco. Divergência lança em debug e é bloqueada em
produção, com registro. Esta é a defesa em profundidade contra o erro de
programação que a regra de segurança não pega — por exemplo, ler o documento
certo do tenant errado que também está atribuído ao especialista.

## D) Regras consolidadas — `firestore.rules`
Reescreva o arquivo inteiro, cobrindo as **4 personas** e todas as coleções do
esquema. Requisitos que precisam estar explícitos:

1. `audit_logs` e `custody_records`: leitura **negada a todos** no cliente
   (inclusive staff). `custody_records` aceita apenas `create` — sem `update`,
   sem `delete`, por ninguém.
2. `reports`: cliente lê apenas `status in ['published','amended','retracted']`.
   Staff atribuído lê qualquer status.
3. `reports/{id}/sections/{key}`: nega quando `sensitivity` é `exploitProof`,
   `personalData` ou `chainOfCustody` **e** o papel é `board`. A regra da seção
   é independente da regra do relatório — é por isso que sections é subcoleção.
4. `service_requests`: criação só por `operational` e `strategic`, com
   `requestedByUid == request.auth.uid` e `status` inicial coerente com a
   alçada; aprovação só por `strategic`, e só nos campos `status`, `approval`,
   `updatedAt`; `board` lê apenas onde `materialFact == true`.
5. Staff só alcança tenant presente em `token.tenants`.
6. `config/*`: leitura para autenticado; escrita nunca.
7. `metrics/*`: leitura conforme papel; escrita **nunca** pelo cliente.
8. Escrita de cliente valida `schemaVersion`, `updatedAt == request.time` e
   proíbe alterar `tenantId`, `role`, `classification` e `materialFact`.
9. `custody_records`: recusa criação sem `legalBasis` e `purpose` preenchidos.
   Conformidade como invariante do banco, não como disciplina do usuário.
10. Catch-all final continua negando tudo.

Comente cada bloco explicando **por que** a regra existe. Regra sem porquê é
regra que alguém afrouxa em seis meses.

## E) Índices — `firestore.indexes.json`
Acrescente os índices da seção 5 do modelo físico, mais os que suas consultas
exigirem. Inclua a exceção de índice para campos grandes que nunca são
filtrados (`sections.body`, `audit_logs.payload`) — indexar texto longo é
desperdício de armazenamento e de escrita.

## F) TTL
Documente e crie as políticas de TTL em `expiresAt` para `audit_logs`
(5 anos) e `notifications` (180 dias). Escreva `expiresAt` no momento da
criação, via Cloud Function. **Não** crie TTL em `custody_records`.

## G) Agregados — `functions/src/aggregations.ts`
Triggers `onDocumentWritten` que recalculam os cinco documentos de
`metrics/*` descritos no modelo físico. Requisitos:
- idempotente: reprocessar o mesmo evento não corrompe o agregado;
- transação ou incremento atômico, nunca leitura-modificação-escrita solta;
- uma função `rebuildAllMetrics(tenantId)` chamável, para reconstrução após
  importação ou correção;
- limite de fan-out documentado.

## H) Seed determinístico — `scripts/seed/`
TypeScript, contra emulador por padrão, `CONFIRM_PROD=1` para produção.
Gera, com IDs determinísticos e **exatamente os mesmos números do mock Dart**:
- `config/service_catalog` com os 44 serviços;
- dois tenants: `tenant-demo` e `tenant-acme`, com dados visivelmente
  diferentes;
- 3 usuários de cliente por tenant (uma persona cada) + 2 contas de staff
  com atribuição aos dois tenants;
- contratos, incluindo um retainer com horas consumidas;
- 9 serviços contratados em `tenant-demo`;
- 12 meses de `posture_snapshots`; 24 controles; 6 riscos; 8 insights;
- 6 RFS em estados diferentes; 8 relatórios (um por categoria), sendo dois
  com fato relevante, um `secret`, um `draft` e um com errata;
- 2 registros de cadeia de custódia selados.

Idempotência é critério de aceite: rodar duas vezes produz o mesmo estado.
Ao final, o script imprime um resumo contando documentos por coleção.

## I) RTDB — presença e efêmeros
`database.rules.json` com o anexo do modelo físico. No app,
`lib/features/presence/` com `onDisconnect` e o espelho
`staff_assignments` mantido pela Cloud Function `assignSpecialist`.
**Nada sensível na árvore do RTDB** — isso é critério de revisão.

## J) Migração de esquema — `functions/src/migrations.ts`
Estrutura para migração versionada: registro `config/schema_version`, função
`migrateTo(n)` idempotente, e execução registrada em auditoria. Mesmo sem
migração hoje, a estrutura precisa existir antes da primeira, não depois.

# TESTES
`test/rules/` (Node, `@firebase/rules-unit-testing`) — positivo E negativo para
cada item da seção D. Obrigatórios:
- especialista atribuído a A não lê nada de B;
- board não lê seção `exploitProof` do relatório que ele **pode** abrir;
- cliente não lê `draft`;
- ninguém lê `audit_logs`;
- `custody_records` recusa `update` e `delete` de qualquer papel;
- `custody_records` recusa criação sem `legalBasis`;
- cliente não altera `role`, `classification` nem `materialFact`.

`test/data/` (Dart):
- `converters_test.dart` — ida e volta preserva o valor; enum desconhecido cai
  no fallback; `schemaVersion` futuro degrada sem explodir;
- `tenant_guard_test.dart` — tenant divergente é bloqueado.

`scripts/seed/test/` — idempotência: rodar duas vezes gera contagens idênticas.

# CRITÉRIOS DE ACEITE
1. `firebase emulators:start` + `npm run seed` + app com
   `--dart-define=DATA_SOURCE=firestore` mostra as MESMAS telas do modo mock.
2. `npm run test:rules` passa, com positivo e negativo para cada regra.
3. `grep -rn "collection('" lib/ | grep -v "core/data/schema.dart"` não retorna
   nada — sem string mágica de coleção.
4. Seed rodado duas vezes: contagens idênticas.
5. O painel do CISO abre com **menos de 15 leituras** — comprove pelo painel de
   uso do emulador.
6. `flutter analyze` limpo, `flutter test` verde.

# COMO RESPONDER
Ordem: schema e conversores → guarda de tenant → regras + testes de regras →
índices → agregados → seed → RTDB → migração. As regras vêm antes do seed de
propósito: seed que roda com regra permissiva esconde erro de regra.

Ao final apresente: (a) o mapa final de coleções como ficou, (b) a matriz
persona × coleção × operação, (c) a contagem de leituras do painel do CISO,
(d) a saída de `npm run test:rules`.
````
