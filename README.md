# Elytron Dash2Board

Aplicativo mobile (iOS + Android) de relatórios, tendências, insights e
pesquisas de cibersegurança, privacidade e risco — para CISOs e tomadores de
decisão. Flutter + Material 3 sobre Firebase (FirebaseAuth + Cloud Firestore).

Produto multi-tenant com **três personas**:

| Persona | Claim | Painel |
|---|---|---|
| Time técnico operacional e tático | `operational` | `/operacao` |
| Segurança estratégica e CISO | `strategic` | `/estrategia` |
| Board e C-Level de negócio | `board` | `/board` |

## Começar

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

Depois siga [`docs/04_SETUP_MACOS_VSCODE.md`](docs/04_SETUP_MACOS_VSCODE.md)
para configurar o Firebase e criar os usuários de teste.

## Documentação

| Documento | Conteúdo |
|---|---|
| [`docs/00_ARQUITETURA.md`](docs/00_ARQUITETURA.md) | Camadas, estado, navegação e decisões de segurança |
| [`docs/01_MODELO_DADOS_FIRESTORE.md`](docs/01_MODELO_DADOS_FIRESTORE.md) | Coleções, campos e matriz de acesso |
| [`docs/02_PERSONAS.md`](docs/02_PERSONAS.md) | As três personas em detalhe |
| [`docs/03_PROMPT_TELA_BOAS_VINDAS.md`](docs/03_PROMPT_TELA_BOAS_VINDAS.md) | **Prompt pronto para o VSCode** + critérios de aceite |
| [`docs/04_SETUP_MACOS_VSCODE.md`](docs/04_SETUP_MACOS_VSCODE.md) | Setup local em macOS |
| [`docs/05_TROUBLESHOOTING.md`](docs/05_TROUBLESHOOTING.md) | Erros comuns de setup (projeto Firebase, npm, simulador) |
| [`docs/08_CATALOGO_SERVICOS.md`](docs/08_CATALOGO_SERVICOS.md) | Taxonomia canônica: 8 categorias, 44 serviços |
| [`docs/09_PERSONA_ESPECIALISTA.md`](docs/09_PERSONA_ESPECIALISTA.md) | ERS da 4ª persona (Especialista Elytron) e modelo cross-tenant |
| [`docs/10_OPORTUNIDADES_PRODUTO.md`](docs/10_OPORTUNIDADES_PRODUTO.md) | Personas e casos de uso ainda não modelados |
| [`docs/11_MODELO_FISICO_DADOS.md`](docs/11_MODELO_FISICO_DADOS.md) | **Modelo físico**: Firestore vs RTDB, coleções, índices, retenção, custo |
| [`docs/12_OPERACAO_FIREBASE.md`](docs/12_OPERACAO_FIREBASE.md) | Runbook de provisionamento, backup, PITR, App Check e IAM |
| [`docs/13_DECISOES_PENDENTES.md`](docs/13_DECISOES_PENDENTES.md) | **Registro de decisões** — o que está decidido e o que trava cada prompt |
| [`docs/14_AUDITORIA_QUALIDADE.md`](docs/14_AUDITORIA_QUALIDADE.md) | Relatório de auditoria de qualidade com achados classificados |
| [`docs/15_GIT_E_GITHUB.md`](docs/15_GIT_E_GITHUB.md) | Repositório, CI, proteção de branch e fluxo de trabalho |
| [`docs/16_PLANO_DE_RETOMADA.md`](docs/16_PLANO_DE_RETOMADA.md) | **Plano de retomada** — ordem das features e o ritual de cada prompt |
| [`docs/prompts/00_INDICE.md`](docs/prompts/00_INDICE.md) | **Roteiro de execução** — os prompts 2 a 9, em ordem |

## O que já está implementado

- Jornada de entrada completa: splash → boas-vindas → login → roteamento por
  persona, com tela dedicada para acesso ainda não provisionado.
- Design system dark-first em Material 3: tokens de cor, tipografia,
  espaçamento, raio e duração; widgets base (logo em `CustomPainter`, cartão,
  campo de formulário, fundo animado).
- Autenticação com FirebaseAuth, papel via **custom claims**, tratamento de
  erro sem vazar existência de conta.
- Guarda única de navegação no `redirect` do go_router, fail-closed.
- `firestore.rules`, `storage.rules`, índices e Cloud Functions de admissão,
  provisionamento de papel e trilha de auditoria.
- Testes de domínio, validadores e widget da tela de boas-vindas.

## Regras de código do projeto

1. `flutter analyze` precisa terminar em **"No issues found!"** — sem
   deprecations (`deprecated_member_use` é tratado como erro).
2. Opacidade **sempre** com `Color.withValues(alpha: ...)`. `withOpacity` é
   proibido.
3. Nada de `ColorScheme.background` / `onBackground` / `surfaceVariant`, nem
   `CardTheme` / `DialogTheme` / `TabBarTheme` dentro de `ThemeData`.
4. `WidgetState*` no lugar de `MaterialState*`.
5. Não configure `pageTransitionsTheme` — os builders variam entre versões do
   Flutter e o padrão do Material 3 já é o correto por plataforma.
6. Interface e comentários em pt-BR; identificadores em inglês.

## Comandos

```bash
flutter analyze
flutter test
flutter run --dart-define=ENV=dev
firebase emulators:start
```
