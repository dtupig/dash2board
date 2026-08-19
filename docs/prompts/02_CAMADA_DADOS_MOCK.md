# Prompt 2 — Camada de dados com fonte alternável (mock ↔ Firestore)

**Entrega:** modelos de domínio, contratos de repositório, implementação mock
com dados realistas, implementação Firestore, e um modo de execução que roda o
app inteiro **sem Firebase configurado**.

**Por que primeiro:** o app não abre sem projeto Firebase válido. Isso
desbloqueia todo o trabalho visual e evita que as telas nasçam acopladas ao
Firestore.

> **A parte A (modo sem Firebase + mock de autenticação) já está implementada**
> no repositório: `AuthRepository` virou interface, com
> `FirebaseAuthRepository` e `MockAuthRepository`, e `main.dart` só inicializa
> o Firebase quando `AppConfig.useMockData` é falso. Ao rodar este prompt, o
> agente deve **conferir** a parte A e seguir direto para a parte B.

---

````text
# CONTEXTO FIXO
Projeto: Elytron Dash2Board (`elytron_dash2board`), Flutter + Material 3 + Firebase.
Antes de escrever qualquer código, LEIA: README.md, docs/00_ARQUITETURA.md,
docs/01_MODELO_DADOS_FIRESTORE.md e docs/02_PERSONAS.md. Siga a arquitetura que
já existe em lib/ (feature-first, domínio puro sem Flutter, Riverpod, go_router).

# REGRAS DE CÓDIGO (obrigatórias, sem exceção)
- `flutter analyze` deve terminar em "No issues found!". `deprecated_member_use`
  é tratado como ERRO neste projeto.
- Opacidade: somente `Color.withValues(alpha: ...)`. `withOpacity` é proibido.
- Proibido: `ColorScheme.background`/`onBackground`/`surfaceVariant`;
  `CardTheme`/`DialogTheme`/`TabBarTheme` dentro de `ThemeData`;
  `pageTransitionsTheme`; `MaterialState*` (use `WidgetState*`).
- Riverpod: use APENAS APIs estáveis entre 2.x e 3.x — `Provider`,
  `StreamProvider`, `FutureProvider`, `Notifier`/`NotifierProvider`,
  `AsyncNotifier`/`AsyncNotifierProvider`. NÃO use `AutoDispose*Notifier`,
  `StateNotifier` nem code generation.
- Interface e comentários em pt-BR; identificadores em inglês.
- Arquivos completos, com todos os imports. Nunca escreva "...".

# TAREFA

## A) Modo de execução sem Firebase
Adicione em `lib/core/config/app_config.dart`:
- `static const bool mockMode = bool.fromEnvironment('MOCK');`
- `static const String dataSource = String.fromEnvironment('DATA_SOURCE', defaultValue: 'auto');`
  Valores: `auto` (mock se `mockMode`, senão firestore), `mock`, `firestore`.

Em `lib/main.dart`: quando `AppConfig.mockMode` for verdadeiro, NÃO chame
`Firebase.initializeApp` nem configure `FirebaseFirestore.settings`. O app deve
subir normalmente.

Crie `lib/features/auth/data/mock_auth_repository.dart` implementando o MESMO
contrato de `AuthRepository` (extraia uma classe base abstrata
`AuthRepository` se necessário, mantendo o nome atual para a implementação
Firebase, ex.: `FirebaseAuthRepository`). O mock:
- expõe três contas de demonstração, uma por persona:
  `operacao@demo.elytron`, `ciso@demo.elytron`, `board@demo.elytron`,
  qualquer senha com 12+ caracteres;
- entra com `tenantId: 'tenant-demo'` e o `role` correspondente;
- simula latência de 600ms e devolve `AppFailure.invalidCredentials()` para
  credencial errada.

Ajuste `authRepositoryProvider` para escolher a implementação conforme
`AppConfig`. Nenhuma tela pode saber qual está ativa.

Adicione em `.vscode/launch.json` uma configuração "Dash2Board · mock".

## B) Modelos de domínio (Dart puro, sem import de Flutter nem de Firebase)
Em `lib/features/strategic/domain/`:

1. `security_domain.dart` — enum `SecurityDomain` com `identity`, `endpoint`,
   `cloud`, `appsec`, `data`, `thirdParty`; `wireValue`, `label` em pt-BR e
   `fromWire` com fallback seguro.
2. `posture_snapshot.dart` — `PostureSnapshot`: `domain`, `score` (0–100),
   `capturedAt`, `peerMedian`, `delta30d`. Com `fromMap`/`toMap`.
3. `posture_index.dart` — `PostureIndex`: `overallScore`, `previousScore`,
   `capturedAt`, `byDomain` (`Map<SecurityDomain,int>`), `peerMedian`.
   Getters derivados: `delta`, `trendDirection` (`up`/`down`/`flat`),
   `weakestDomain`, `strongestDomain`.
4. `compliance_control.dart` — `ComplianceControl`: `framework`
   (enum `ComplianceFramework`: `iso27001`, `nistCsf`, `lgpd`, `pciDss`),
   `controlId`, `title`, `status` (enum `ControlStatus`: `compliant`,
   `partial`, `gap`), `ownerName`, `lastReviewedAt`, `evidenceUrl`.
5. `risk_item.dart` — `RiskItem`: `id`, `title` em linguagem de negócio,
   `businessUnit`, `domain`, `inherentScore`, `residualScore`,
   `annualLossExpectancy`, `currency`, `treatment`, `acceptance`,
   `reviewDueAt`.
6. `insight_item.dart` — `InsightItem`: `id`, `topic`, `title`, `summary`,
   `publishedAt`, `sourceName`, `sourceUrl`, `isBenchmark`.

Todos com `==`, `hashCode` e `copyWith`. Datas como `DateTime` (a conversão de
`Timestamp` fica na camada de dados, não no domínio).

## C) Contrato de repositório
`lib/features/strategic/data/strategic_repository.dart`:

```
abstract interface class StrategicRepository {
  Stream<PostureIndex> watchPostureIndex(String tenantId);
  Stream<List<PostureSnapshot>> watchPostureHistory(String tenantId, {int months = 12});
  Stream<List<ComplianceControl>> watchCompliance(String tenantId, {ComplianceFramework? framework});
  Stream<List<RiskItem>> watchTopRisks(String tenantId, {int limit = 5});
  Stream<List<InsightItem>> watchInsights(String tenantId, {int limit = 10});
}
```

## D) Implementação mock com dados que sustentam uma demo
`lib/features/strategic/data/mock_strategic_repository.dart`.

Os dados precisam contar uma história crível de empresa brasileira de médio
porte, e NÃO podem ser aleatórios a cada execução (use uma seed fixa para que a
demo seja reproduzível):
- índice geral hoje em **72**, contra **64** doze meses atrás — melhora
  consistente porém com um recuo em dois meses do meio do período;
- mediana do setor em **68**;
- por domínio: identity 81, endpoint 76, cloud 63, appsec 58, data 74,
  thirdParty 55 — ou seja, terceiros e appsec são a história a contar;
- 24 controles de compliance distribuídos em ISO 27001, NIST CSF, LGPD e PCI
  DSS, com mistura realista de `compliant`/`partial`/`gap`;
- 6 riscos de negócio com ALE entre R$ 180 mil e R$ 4,2 milhões, atribuídos a
  unidades de negócio plausíveis (Varejo, Indústria, Serviços Financeiros,
  Corporativo);
- 8 insights, sendo 3 marcados como benchmark de setor.

Emita os streams com um pequeno atraso inicial (400ms) para que os estados de
carregamento das telas sejam exercitados de verdade.

## E) Implementação Firestore
`lib/features/strategic/data/firestore_strategic_repository.dart`, usando
`FirestorePaths` já existente. Converta `Timestamp` para `DateTime` aqui.
Trate erro de permissão devolvendo `AppFailure` — nunca deixe exceção do
Firebase chegar à UI.

## F) Providers
`lib/features/strategic/data/strategic_providers.dart`:
- `strategicRepositoryProvider` escolhendo mock/firestore por `AppConfig`;
- `postureIndexProvider`, `postureHistoryProvider`, `complianceProvider`,
  `topRisksProvider`, `insightsProvider` — todos `StreamProvider` que leem o
  `tenantId` do `appUserProvider` e devolvem `AsyncValue`.
  Se não houver usuário ou tenant, emita lista vazia (não lance exceção).

# TESTES
Em `test/strategic/`:
- `posture_index_test.dart`: `delta`, `trendDirection`, `weakestDomain`.
- `mock_strategic_repository_test.dart`: histórico tem 12 pontos, índice geral
  é 72, mediana 68, e duas execuções seguidas produzem exatamente os mesmos
  dados (reprodutibilidade).
- `security_domain_test.dart`: `fromWire` desconhecido cai em fallback seguro.

# CRITÉRIOS DE ACEITE
1. `flutter run --dart-define=MOCK=true` sobe o app SEM nenhum arquivo do
   Firebase configurado.
2. Login com `ciso@demo.elytron` e senha de 12+ caracteres cai em `/estrategia`.
3. As outras duas contas de demo caem em `/operacao` e `/board`.
4. Nenhum arquivo em `lib/features/*/presentation/` importa
   `cloud_firestore` ou `firebase_auth`.
5. `flutter analyze` limpo e `flutter test` verde.

# COMO RESPONDER
Escreva os arquivos direto no projeto, do domínio para fora. Não peça
confirmação entre arquivos. Ao final rode `flutter analyze` e `flutter test` e
corrija até zerar. Depois liste, em tabela, arquivo → responsabilidade.
````
