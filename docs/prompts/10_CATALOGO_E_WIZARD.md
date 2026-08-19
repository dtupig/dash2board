# Prompt 10 — Catálogo de serviços e wizard de demanda (RFS)

**Entrega:** o ponto de bifurcação do app — "quero ver relatórios" ou "quero
demandar um serviço" — mais o wizard que transforma uma intenção vaga em uma
solicitação com escopo suficiente para virar proposta.

**Decisões já tomadas** (não reabra no prompt):
- Concluir o wizard gera uma **RFS** (solicitação comercial) que vai para a
  Elytron e volta como proposta. Não é ordem de serviço dentro de contrato.
- Relatórios listam **só o que o cliente contratou**; o catálogo de demanda
  mostra os 44 serviços, com selo distinguindo contratado de não contratado.
- Alçada: **operacional abre, CISO aprova, board não abre nem aprova.**

---

````text
# CONTEXTO FIXO
Projeto: Elytron Dash2Board (`elytron_dash2board`), Flutter + Material 3 + Firebase.
LEIA ANTES de escrever qualquer código, e trate como fonte de verdade:
  docs/08_CATALOGO_SERVICOS.md   <- as 8 categorias e os 44 serviços
  docs/02_PERSONAS.md            <- as três personas
  docs/00_ARQUITETURA.md
  docs/01_MODELO_DADOS_FIRESTORE.md
  lib/features/strategic/         <- padrão de repositório mock/firestore
  lib/core/widgets/               <- SurfaceCard, AppTextField, charts
NÃO invente serviço, categoria nem chave que não esteja no catálogo.

# REGRAS DE CÓDIGO (obrigatórias, sem exceção)
- `flutter analyze` deve terminar em "No issues found!"; `deprecated_member_use`
  é tratado como ERRO.
- Opacidade: somente `Color.withValues(alpha: ...)`. `withOpacity` é proibido.
- Proibido: `ColorScheme.background`/`onBackground`/`surfaceVariant`;
  `CardTheme`/`DialogTheme`/`TabBarTheme` dentro de `ThemeData`;
  `pageTransitionsTheme`; `MaterialState*` (use `WidgetState*`).
- Riverpod: APENAS APIs estáveis entre 2.x e 3.x — `Provider`, `StreamProvider`,
  `FutureProvider`, `Notifier`/`NotifierProvider`,
  `AsyncNotifier`/`AsyncNotifierProvider`. Sem `AutoDispose*Notifier`, sem
  `StateNotifier`, sem code generation.
- Toda origem de dado tem implementação mock E firestore, escolhidas em UM
  único provider. Nenhum arquivo em `presentation/` importa `cloud_firestore`
  ou `firebase_auth`.
- Domínio (`domain/`) é Dart puro: sem import de Flutter e sem import de
  Firebase.
- pt-BR na interface e nos comentários; identificadores em inglês.
- Arquivos completos, com todos os imports. Nunca escreva "...".
- Nenhum arquivo acima de 250 linhas: quebre em widgets/serviços menores.

# TAREFA

## A) Domínio do catálogo — `lib/features/services/domain/`

1. `service_category.dart` — enum `ServiceCategory` com as 8 categorias do
   catálogo (`categoryKey`, `label`, `description` curta em pt-BR, `icon` NÃO
   entra aqui — visual fica em presentation). `fromWire` com fallback seguro.

2. `service_offering.dart` — `ServiceOffering`: `serviceKey`, `category`,
   `label`, `deliveryModel` (enum `DeliveryModel`: `oneOff`, `recurring`,
   `continuous`, `retainer`), `primaryPersona` (`UserRole`),
   `shortPitch` (1 frase, em linguagem de negócio, para o cartão do catálogo),
   `typicalDurationDays`, `requiresScopeAssets` (bool — se o wizard precisa
   pedir a lista de alvos).

3. `service_catalog.dart` — a lista COMPLETA e imutável dos 44 serviços,
   transcrita de `docs/08_CATALOGO_SERVICOS.md`, como
   `static const List<ServiceOffering> all`. Mais os utilitários
   `byCategory`, `byKey`, `search(String termo)` (busca sem acento e sem
   diferenciar maiúsculas).
   Escreva o `shortPitch` de cada serviço você mesmo: uma frase, sem sigla não
   explicada, dizendo o que o cliente ganha — não o que a Elytron faz.

4. `contracted_service.dart` — `ContractedService`: `serviceKey`,
   `contractId`, `startedAt`, `endsAt`, `status` (`active`, `expiring`,
   `expired`), `lastDeliveryAt`, `deliveriesCount`. É o que separa "tenho" de
   "não tenho".

## B) Domínio da demanda — `lib/features/services/domain/service_request.dart`

`ServiceRequest` com: `id`, `tenantId`, `serviceKey`, `requestedByUid`,
`requestedByName`, `createdAt`, `urgency` (enum `RequestUrgency`: `planned`,
`nextQuarter`, `urgent`, `crisis`), `driver` (enum `RequestDriver`:
`auditFinding`, `regulatory`, `incident`, `newProject`, `clientDemand`,
`internalInitiative`), `scopeSummary`, `scopeAssets` (List<String>),
`businessJustification`, `desiredWindow`, `status`, `approval`, `timeline`.

Máquina de estados `RequestStatus`, com as transições VÁLIDAS declaradas em
código (um mapa `Map<RequestStatus, Set<RequestStatus>>`) e um método
`canTransitionTo` — transição inválida lança `StateError`:

```
draft ──► pendingApproval ──► approved ──► sentToElytron ──► proposalReceived
  │             │                 │                                  │
  │             ▼                 ▼                                  ▼
  └──────► cancelled          rejected                          contracted
                                                                     │
                                                                     ▼
                                                                 delivered
```

`ApprovalRecord`: `decidedByUid`, `decidedByName`, `decidedAt`, `decision`
(`approved`/`rejected`), `note` (obrigatória na rejeição).

## C) Alçada — `lib/features/services/domain/request_policy.dart`

Classe pura, testável, SEM Flutter:

```
abstract final class RequestPolicy {
  static bool canOpen(UserRole role);      // operational e strategic
  static bool canApprove(UserRole role);   // apenas strategic
  static bool canView(UserRole role);      // as três
  static bool requiresApproval(UserRole opener); // true para operational
  static String? blockReason(UserRole role, RequestAction action);
}
```

Regras:
- `operational` abre; a solicitação nasce em `pendingApproval`.
- `strategic` abre; a solicitação nasce em `approved`, MAS grava um
  `ApprovalRecord` de auto-aprovação — auditoria não aceita buraco.
- `board` NÃO abre e NÃO aprova. Para o board o módulo é somente leitura, e
  apenas das solicitações que já viraram fato relevante (prompt 11).
- Ninguém aprova a própria solicitação, exceto o caso de auto-aprovação do
  `strategic` acima, que é explicitamente marcado como tal.

**Esta classe é o coração do requisito. Escreva-a antes de qualquer tela e
cubra-a de teste.** Nenhuma tela pode reimplementar a regra: se um widget
precisa saber se um botão aparece, ele pergunta ao `RequestPolicy`.

## D) Bifurcação — a tela que abre o módulo

`lib/features/services/presentation/services_hub_screen.dart`, rota `/servicos`,
acessível pelas três personas a partir do `PersonaScaffold`.

Duas trilhas, apresentadas como duas escolhas grandes e inequívocas:

1. **"Ver relatórios"** → leva ao catálogo FILTRADO pelos serviços contratados,
   com a contagem de entregas disponíveis por serviço. Se o tenant não tem
   nenhum serviço contratado, mostre um estado vazio honesto — não uma lista
   vazia.
2. **"Demandar um serviço"** → leva ao catálogo COMPLETO (44), com selo
   `Contratado` / `Não contratado`. Para `board`, esta trilha aparece
   **desabilitada com explicação** ("solicitações são abertas pelo time técnico
   e aprovadas pelo CISO"), nunca escondida — esconder confunde, explicar
   ensina.

Acima das duas trilhas, uma linha de contexto: nome do cliente, número de
serviços ativos e quantos relatórios novos desde o último acesso.

## E) Catálogo — `service_catalog_screen.dart`

Parâmetro de rota `?modo=relatorios|demanda`.
- Busca no topo (por nome de serviço e por categoria), com resultado ao vivo.
- Agrupado pelas 8 categorias, cada uma com contagem.
- Cartão de serviço: rótulo, `shortPitch`, chip do modelo de entrega, selo de
  contratado, e, no modo relatórios, a data da última entrega.
- No modo demanda, o cartão de serviço não contratado NÃO fica bloqueado: ele é
  justamente o que pode virar uma RFS.
- Ordenação dentro da categoria: contratados primeiro, depois alfabética.

## F) Wizard de demanda — `request_wizard_screen.dart`

Rota `/servicos/demanda/:serviceKey`. **Cinco passos**, com barra de progresso,
"voltar" sempre disponível, e rascunho preservado ao sair (persistido em
`shared_preferences` por `serviceKey`).

1. **Caso de uso** — por que está pedindo: `RequestDriver` em cartões
   selecionáveis, com um campo livre "descreva em uma frase". Este passo existe
   para que a proposta não chegue genérica.
2. **Escopo** — muda conforme `requiresScopeAssets`: lista de alvos
   (domínios, aplicações, repositórios, faixas de IP, contas de nuvem), com
   validação de formato e possibilidade de colar uma lista. Quando o serviço
   não pede alvos, este passo pede volume/abrangência (nº de pessoas, nº de
   fornecedores, nº de sistemas).
3. **Urgência e janela** — `RequestUrgency` mais janela desejada. Selecionar
   `crisis` mostra, de forma destacada, o telefone do plantão DFIR e o aviso de
   que a RFS **não substitui** o acionamento de emergência. Isso é segurança de
   verdade, não texto decorativo.
4. **Justificativa de negócio** — texto obrigatório, com contador de caracteres
   e três exemplos de justificativa boa. É o que o CISO vai ler para aprovar.
5. **Revisão** — resumo completo, com "editar" em cada bloco, e o botão final
   rotulado conforme a alçada: "Enviar para aprovação do CISO" para
   `operational`, "Enviar para a Elytron" para `strategic`.

Regras do wizard:
- Nenhum passo avança com campo obrigatório vazio; o erro aparece no campo, não
  em diálogo.
- O usuário pode voltar sem perder o que digitou.
- Sair do wizard pergunta se quer salvar rascunho.
- O `serviceKey` é validado contra `ServiceCatalog.byKey`: chave desconhecida
  leva a uma tela de erro, nunca a um wizard vazio.

## G) Fila de aprovação — `request_inbox_screen.dart`

Rota `/servicos/solicitacoes`.
- Para `strategic`: aba "Aguardando minha aprovação" (com contagem no badge do
  `PersonaScaffold`), "Em andamento" e "Histórico". Aprovar exige confirmação;
  **rejeitar exige nota escrita** — sem nota o botão fica desabilitado.
- Para `operational`: só as próprias solicitações, com o status e quem está
  com a bola.
- Para `board`: apenas as solicitações marcadas como fato relevante, em modo
  leitura.
- Cada mudança de estado grava em `/tenants/{tenantId}/audit_logs` via a camada
  de dados (no mock, em memória).

## H) Dados — `lib/features/services/data/`
- `services_repository.dart` (interface): `watchContractedServices`,
  `watchRequests`, `watchRequest`, `createRequest`, `submitForApproval`,
  `decideApproval`, `cancelRequest`.
- `mock_services_repository.dart`: tenant de demonstração com **9 serviços
  contratados** distribuídos em pelo menos 5 categorias, 6 solicitações em
  estados diferentes (uma rejeitada com nota, uma em `proposalReceived`, uma
  `crisis`), dados fixos e reproduzíveis.
- `firestore_services_repository.dart`: coleções
  `/tenants/{tenantId}/contracted_services/{serviceKey}` e
  `/tenants/{tenantId}/service_requests/{requestId}`.
- `services_providers.dart` com a escolha mock/firestore no padrão já existente.

## I) Security rules e índices
Atualize `firestore.rules`:
- `contracted_services`: leitura para as três personas do tenant; escrita
  apenas backend.
- `service_requests`: leitura para `operational` (apenas as próprias) e
  `strategic` (todas); `board` só lê documentos com `materialFact == true`.
  Criação apenas por `operational` e `strategic`, com `requestedByUid ==
  request.auth.uid` e `status` inicial coerente com a alçada.
  Atualização de aprovação apenas por `strategic`, e apenas nos campos
  `status`, `approval`, `updatedAt`.
  Ninguém apaga.
Atualize `firestore.indexes.json` com o que as consultas exigirem —
não simplifique consulta para fugir de índice.

# TESTES
`test/services/`:
- `request_policy_test.dart` — matriz COMPLETA persona × ação (abrir, aprovar,
  ver, rejeitar), incluindo os casos negativos: board não abre, board não
  aprova, operational não aprova, ninguém aprova a própria (exceto a
  auto-aprovação marcada do strategic).
- `service_request_transitions_test.dart` — toda transição válida passa e
  **toda inválida lança**; percorra o mapa inteiro programaticamente.
- `service_catalog_test.dart` — são exatamente 44 serviços; todas as
  `serviceKey` são únicas; toda `serviceKey` pertence a uma das 8 categorias;
  toda `shortPitch` é não vazia.
- `request_wizard_test.dart` — não avança com campo vazio; volta preservando
  dado; `crisis` mostra o aviso de plantão; rótulo do botão final muda por
  persona.
Use `pump(Duration)`, nunca `pumpAndSettle`.

# CRITÉRIOS DE ACEITE
1. `flutter run --dart-define=MOCK=true`; logando como cada persona, a tela
   `/servicos` mostra a bifurcação correta e o board vê a trilha de demanda
   desabilitada COM explicação.
2. Abrir uma RFS como `operacao@demo.elytron` a deixa em `pendingApproval` e ela
   aparece na fila do `ciso@demo.elytron`.
3. Rejeitar sem nota é impossível pela interface E pelo domínio.
4. Os 44 serviços estão no catálogo, com busca funcionando sem acento.
5. Nenhuma tela reimplementa regra de alçada — tudo passa por `RequestPolicy`.
6. `flutter analyze` limpo e `flutter test` verde.

# COMO RESPONDER
Ordem: catálogo → domínio da demanda → `RequestPolicy` + testes dela → dados →
telas. Não peça confirmação entre arquivos. Ao final rode `flutter analyze` e
`flutter test`, corrija até zerar, e apresente: (a) tabela arquivo →
responsabilidade e (b) a matriz persona × ação como ela ficou implementada.
````
