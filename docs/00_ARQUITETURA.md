# Arquitetura — Elytron Dash2Board

## Visão geral

Aplicativo Flutter (iOS + Android) sobre Firebase, multi-tenant, com três
personas de leitura. O produto é de **leitura executiva**: a maior parte do
tráfego é consulta a agregados já calculados, não consulta analítica ao vivo.

```
┌──────────────────────────── Cliente (Flutter) ────────────────────────────┐
│  Presentation  telas + controllers Riverpod + go_router (guarda única)     │
│  Domain        UserRole, AppUser  (Dart puro, sem Flutter)                 │
│  Data          AuthRepository, *Repository (Firestore SDK)                 │
│  Core          tema/tokens, erros, validadores, widgets compartilhados     │
└───────────────────────────────────────────────────────────────────────────┘
                     │ ID token com custom claims (role, tenantId)
                     ▼
┌──────────────────────────── Firebase ─────────────────────────────────────┐
│  FirebaseAuth ── custom claims assinados                                  │
│  Cloud Firestore ── security rules fail-closed, isolamento por tenant      │
│  Cloud Functions ── admissão, provisionamento de papel, auditoria          │
│  Cloud Storage ── PDFs de relatório e evidências de compliance             │
└───────────────────────────────────────────────────────────────────────────┘
```

## Camadas e regra de dependência

`presentation → domain ← data`. O domínio não importa Flutter nem Firebase.
Consequência prática: `UserRole` é testável sem `flutter_test` e o mapeamento
visual das personas vive em `persona_visuals.dart` como `extension`.

## Estado e navegação

- **Riverpod** com as APIs estáveis em 2.x e 3.x: `Provider`, `StreamProvider`,
  `Notifier`/`NotifierProvider`, `AsyncNotifier`/`AsyncNotifierProvider`.
  Evitamos `AutoDispose*Notifier` e `StateNotifier` justamente por variarem
  entre as versões maiores.
- `appUserProvider` é um `StreamProvider<AppUser?>` alimentado por
  `idTokenChanges()`. Ele é a única fonte de verdade de sessão.
- **go_router** com uma guarda única em `redirect`. Nenhuma tela navega
  manualmente após o login: quem decide o destino é o papel do usuário.

## Segurança — decisões e porquês

| Decisão | Porquê |
|---|---|
| Papel em custom claim, não em documento | A regra do Firestore lê o token direto: mais barata (sem `get()`), mais rápida e impossível de forjar pelo cliente |
| Documento de membro só para exibição | Nome e cargo mudam com frequência e não valem uma reemissão de token |
| Papel desconhecido ⇒ `pending` | Falha fechada: uma string nova no backend nunca abre acesso por acidente |
| Mensagem única para credencial inválida | Impede enumeração de usuários, vetor real em produtos B2B |
| Reset de senha com resposta uniforme | Idem |
| `revokeRefreshTokens` ao mudar papel | Rebaixamento de acesso tem efeito imediato, não em até 1 hora |
| Trilha de auditoria ilegível pelo app | Evita que um comprometimento de conta apague rastros |
| Cache offline limitado a 40 MB | Executivo abre no avião, mas o dispositivo não vira repositório de dado sensível |

## Fluxo de entrada

```
abrir app
   └─ SplashScreen ......... resolve sessão + claims
        ├─ sem sessão ────── WelcomeScreen ── SignInScreen
        ├─ role = pending ── PendingAccessScreen
        └─ role provisionado
              ├─ operational → /operacao
              ├─ strategic   → /estrategia
              └─ board       → /board
```

## O que ainda não está implementado (próximas iterações)

1. Repositórios e modelos de `incidents` e `vulnerabilities` (persona
   operacional ainda é um painel de "em breve" - `risks`, `compliance`,
   `insights` e `surveys` já têm modelo, repositório e tela).
2. Push notification por severidade, com preferência por persona.
3. Firebase App Check e MFA obrigatório para `tenantAdmin`.
4. Testes de `firestore.rules` com `@firebase/rules-unit-testing`.
5. Seed reproduzível rodado de fato contra o emulador (o script existe em
   `scripts/seed/`, mas ainda não foi executado ponta a ponta).
