# Prompt 12 — Retrofit: introduzir a persona Especialista Elytron

**Entrega:** a quarta persona atravessando tudo que já existe — domínio,
autorização, roteamento, security rules, mocks e testes — **sem quebrar** o que
as três personas de cliente já fazem.

**Leia antes de rodar:** [`../09_PERSONA_ESPECIALISTA.md`](../09_PERSONA_ESPECIALISTA.md)
é a especificação. O prompt implementa o que está lá; ele não redecide.

> Este é um prompt de **refatoração com rede de segurança**, não de recurso
> novo. O critério de sucesso mais importante não é "o especialista funciona":
> é "nenhum teste de cliente quebrou e nenhum cliente enxerga o que não devia".

---

````text
# CONTEXTO FIXO
Projeto: Elytron Dash2Board (`elytron_dash2board`), Flutter + Material 3 + Firebase.
LEIA ANTES, como fonte de verdade:
  docs/09_PERSONA_ESPECIALISTA.md  <- ESPECIFICAÇÃO desta tarefa
  docs/02_PERSONAS.md
  docs/08_CATALOGO_SERVICOS.md
  docs/00_ARQUITETURA.md
  firestore.rules
  lib/features/auth/domain/user_role.dart
  lib/features/services/domain/request_policy.dart
  lib/features/reports/domain/report_access_policy.dart
NÃO redecida nada que a especificação já decidiu.

# REGRAS DE CÓDIGO (obrigatórias)
- `flutter analyze` em "No issues found!"; `deprecated_member_use` é ERRO.
- Opacidade só com `Color.withValues(alpha: ...)`.
- Proibido `ColorScheme.background`/`onBackground`/`surfaceVariant`,
  `CardTheme`/`DialogTheme`/`TabBarTheme` em `ThemeData`,
  `pageTransitionsTheme`, `MaterialState*`.
- Riverpod só com APIs estáveis. Sem code generation.
- Domínio em Dart puro. `presentation/` não importa Firebase.
- pt-BR na interface e comentários; identificadores em inglês.
- Arquivos completos com imports. Nunca escreva "...". Máximo 250 linhas.

# REGRA DE OURO DESTE PROMPT
Rode `flutter test` ANTES de mudar qualquer coisa e guarde o resultado. Ao
final, TODOS os testes que passavam precisam continuar passando. Se um teste de
cliente quebrar, o retrofit está errado — não ajuste o teste para acomodar o
código; conserte o código.

# TAREFA

## A) Identidade e papéis — `lib/features/auth/domain/`

1. Crie `principal_kind.dart`: enum `PrincipalKind { client, staff }`.
   Ele responde "de quem é esta pessoa", e é a primeira bifurcação de
   autorização do sistema.

2. Crie `staff_role.dart`: enum `StaffRole` com `analyst`, `reviewer`,
   `deliveryLead`, `staffAdmin`, mais `unassigned` como fallback seguro.
   `wireValue`, `label` pt-BR, `fromWire` com fallback para `unassigned`.

3. **NÃO** acrescente `specialist` ao enum `UserRole`. `UserRole` descreve a
   persona do CLIENTE e é usado em toda a matriz de acesso; contaminá-lo com um
   papel de staff produziria comparações sem sentido (`board` vs `specialist`)
   espalhadas pelo código. Modele staff como dimensão separada.

4. Estenda `AppUser`: `principalKind`, `staffRole`, `assignedTenantIds`
   (`List<String>`, vazia para cliente), `mfaEnrolled` já existe.
   Getters: `isStaff`, `isClient`, `canAccessTenant(String tenantId)`.
   `AppUser.fromFirestore` lê os claims `staff`, `staffRole`, `tenants`.
   Para staff, `tenantId` (singular) passa a significar **o tenant em foco**,
   não o tenant de origem.

5. `assignedTenantIds` com mais de 45 itens deve lançar em modo debug e
   registrar aviso em produção — é o teto de 1000 bytes do custom claim se
   aproximando. Falhe alto, nunca trunque em silêncio.

## B) Tenant em foco — `lib/features/staff/domain/tenant_scope.dart`

Staff opera em um cliente por vez. Crie um `Notifier<String?>`
(`activeTenantProvider`) e a regra:

- Trocar de tenant **invalida** todos os providers de dados. Nenhum dado de A
  pode sobreviver na tela ao entrar em C.
- Todo repositório usado por staff recebe `tenantId` como parâmetro
  **obrigatório e explícito**. Proíba qualquer assinatura que resolva o tenant
  implicitamente.
- `tenantId` nulo ou não atribuído = negar, nunca "todos".

Escreva um teste que garanta que a troca de tenant limpa o estado.

## C) Autorização — atualize as políticas existentes

`RequestPolicy` (prompt 10) ganha as regras de staff:
- staff **não** abre RFS em nome do cliente; staff **responde** RFS.
- `analyst` e `deliveryLead` podem triar, estimar e anexar proposta.
- staff nunca aprova a RFS do cliente — a aprovação é do CISO. Manter essa
  fronteira é o que preserva a confiança comercial.

`ReportAccessPolicy` (prompt 11) ganha:
- staff atribuído vê todas as seções, inclusive `exploitProof` e
  `chainOfCustody`, apenas nos tenants atribuídos.
- `personalData` exige `staffRole` ∈ {`analyst`, `deliveryLead`} **e** registro
  de leitura.
- staff não atribuído: nega tudo, sem exceção.

Crie `lib/features/staff/domain/staff_policy.dart` com a separação de funções:
```
static bool canAuthor(StaffRole r);
static bool canReview(StaffRole r);
static bool canApprove(StaffRole r, {required String authorUid, required String reviewerUid});
static bool canPublish(StaffRole r);
static bool canManageAssignments(StaffRole r);
static bool requiresSegregationException(String authorUid, String approverUid);
```
`canApprove` retorna falso quando `authorUid == reviewerUid`, salvo exceção
explícita registrada.

## D) Roteamento — `lib/app/router.dart`

- Novo ramo `/elytron/...` para staff. **Sessão de cliente nunca alcança
  `/elytron`; sessão de staff nunca alcança as rotas de dashboard de cliente.**
  As duas direções são bloqueadas no `redirect`, e cada uma tem teste.
- Staff sem `activeTenant` cai em `/elytron/clientes` (seletor), não em
  dashboard.
- Staff sem nenhuma atribuição cai numa tela de "sem atribuição", equivalente
  ao `pending` do cliente.

## E) Security rules — `firestore.rules`

Acrescente, sem afrouxar nada do que já existe:

```
function isStaff() { return isSignedIn() && token().get('staff', false) == true; }
function staffRole() { return isSignedIn() ? token().get('staffRole', 'unassigned') : 'unassigned'; }
function staffAssignedTo(tenantId) { return isStaff() && tenantId in token().get('tenants', []); }
function memberOrStaff(tenantId) { return inTenant(tenantId) || staffAssignedTo(tenantId); }
```

Aplique `staffAssignedTo` nas coleções que staff precisa alcançar. Regras
específicas:
- `audit_logs` continua **ilegível para todos**, inclusive staff.
- staff não escreve `members` nem `role` de ninguém (isso é Cloud Function).
- rascunho de relatório: legível apenas por staff atribuído; **nenhuma persona
  de cliente lê rascunho**, em nenhuma classificação.

## F) Cloud Functions — `functions/src/`
- `assignSpecialist` (callable, apenas `staffAdmin`): adiciona/remove tenant da
  lista de atribuição, atualiza os claims, revoga tokens, cria/remove o
  documento de membro com `role: "specialist"` e grava auditoria nos dois
  tenants envolvidos.
- Estenda `gateSignUp`: conta com domínio `@elytronsecurity.com` só é admitida
  com convite de staff; conta de cliente nunca recebe `staff: true`.
- Valide o teto de 45 tenants e recuse com erro claro.

## G) Dados e mock
- `lib/features/staff/data/` com `staff_repository.dart` (interface), mock e
  firestore.
- O mock ganha **duas contas de staff**:
  `analista@elytronsecurity.com` (`analyst`, atribuído a `tenant-demo` e
  `tenant-acme`) e `lider@elytronsecurity.com` (`deliveryLead`, atribuído aos
  mesmos). Senha: 12+ caracteres, como as demais.
- Crie o segundo tenant `tenant-acme` no mock, com dados **visivelmente
  diferentes** de `tenant-demo` — é assim que a troca de contexto fica
  demonstrável e o vazamento fica visível se acontecer.

## H) Documentação
Atualize `docs/02_PERSONAS.md` com a persona 4 e atualize a matriz de acesso de
`docs/01_MODELO_DADOS_FIRESTORE.md` com a coluna de staff.

# TESTES (o coração deste prompt)
`test/staff/`:
- `tenant_isolation_test.dart` — especialista atribuído a A e C **não** lê B.
  Cubra: leitura direta, consulta, e troca de tenant.
- `tenant_scope_test.dart` — trocar de tenant invalida o estado anterior;
  nenhum dado de A permanece.
- `staff_policy_test.dart` — matriz completa `StaffRole` × ação, com os casos
  negativos: autor não aprova a si mesmo; `analyst` não publica; `staffAdmin`
  não lê conteúdo fora de atribuição.
- `route_guard_test.dart` — cliente em `/elytron/*` é bloqueado; staff em
  `/estrategia` é bloqueado.
`test/rules/` (Node): especialista de A não lê B; staff não lê `audit_logs`;
cliente não lê rascunho.

**Regressão obrigatória:** rode toda a suíte anterior e prove que nada quebrou.

# CRITÉRIOS DE ACEITE
1. Toda a suíte que passava antes continua passando.
2. `analista@elytronsecurity.com` alterna entre `tenant-demo` e `tenant-acme` e
   os dados mudam por completo na tela.
3. Nenhuma tela agrega métrica de dois clientes.
4. Cliente não alcança `/elytron`; staff não alcança dashboard de cliente.
5. `grep -rn "specialist" lib/features/auth/domain/user_role.dart` não retorna
   nada — staff não contamina `UserRole`.
6. `flutter analyze` limpo, `flutter test` verde, `npm run test:rules` verde.

# COMO RESPONDER
Ordem: identidade → políticas + testes de política → escopo de tenant → rules →
roteamento → dados/mock → telas mínimas de staff (seletor de cliente e "minha
carga de trabalho"). As telas ricas ficam para o prompt 13.

Ao final, apresente: (a) o diff resumido de `firestore.rules`, (b) a matriz
`StaffRole` × ação implementada, (c) a saída de `flutter test` mostrando que a
suíte anterior continua verde.
````
