# Prompt — Primeira tela de boas-vindas (Elytron Dash2Board)

Este documento tem duas partes:

- **Parte A — o prompt** pronto para colar no Claude Code / Copilot dentro do
  VSCode. É autocontido: quem receber esse texto consegue produzir a tela sem
  ler mais nada.
- **Parte B — critérios de aceite** para você conferir o resultado.

> Se você usar este repositório como está, a tela já vem implementada em
> `lib/features/auth/presentation/welcome_screen.dart`. O prompt abaixo serve
> para (1) regerar a tela do zero, (2) pedir variações e (3) padronizar como as
> próximas telas do app serão pedidas.

---

## Parte A — Prompt (copie a partir daqui)

````text
# PAPEL
Atue como Arquiteto sênior especialista em Flutter e Firebase (Cloud Firestore +
FirebaseAuth), com experiência real em produtos de cibersegurança para nível
executivo. Você escreve código de produção: completo, compilável, sem trechos
omitidos, sem "// resto do código aqui".

# PRODUTO
Nome do pacote/app: **Elytron Dash2Board** (`elytron_dash2board`).
Aplicativo mobile (iOS + Android) de relatórios, tendências, insights e
pesquisas de cibersegurança, privacidade e risco, para CISOs e tomadores de
decisão. É um produto B2B multi-tenant: cada organização cliente é um tenant.

# AMBIENTE
- macOS (última versão), VSCode.
- Flutter 3.13+ com Material Design 3 (`useMaterial3: true`).
- Cloud Firestore + FirebaseAuth.
- Gerência de estado: flutter_riverpod. Navegação: go_router.

# REGRAS NÃO NEGOCIÁVEIS DE CÓDIGO
1. `flutter analyze` deve terminar em "No issues found!" — zero avisos, zero
   deprecations. Trate `deprecated_member_use` como erro.
2. Opacidade/cor: use **exclusivamente** `Color.withValues(alpha: ...)`.
   `Color.withOpacity(...)` está proibido no projeto.
3. Não use `ColorScheme.background`, `onBackground` nem `surfaceVariant`
   (deprecados). Use `surface`, `onSurface`, `onSurfaceVariant` e a família
   `surfaceContainer*`.
4. Não passe `CardTheme`, `DialogTheme` ou `TabBarTheme` para `ThemeData`
   (deprecados em favor de `...ThemeData`). Se precisar de cartão, crie um
   widget próprio.
5. Use `WidgetStateProperty` / `WidgetState` (e não `MaterialStateProperty` /
   `MaterialState`).
6. Escreva imports completos em todo arquivo. Nenhum método, classe ou import
   pode ficar implícito.
7. Português do Brasil em toda a interface e nos comentários. Identificadores
   de código em inglês.
8. Sem chamadas de rede na construção de widgets; sem `print` (use `logger`
   se necessário).
9. Não configure `pageTransitionsTheme` no `ThemeData`. Os builders
   (`CupertinoPageTransitionsBuilder`, `FadeUpwardsPageTransitionsBuilder`)
   mudam de nome e de biblioteca entre versões do Flutter e quebram a
   compilação. O padrão do Material 3 já entrega a transição correta por
   plataforma.

# AS TRÊS PERSONAS (obrigatório contemplar as três)
1. **operational** — Time técnico operacional e tático de segurança
   (SOC, resposta a incidentes, gestão de vulnerabilidades).
   Quer granularidade, tempo real e ação imediata.
2. **strategic** — Time de segurança estratégica e o CISO.
   Quer postura consolidada, tendência, risco por domínio, compliance e
   evidência para comitê. **É o público primário do produto.**
3. **board** — Board / C-Level das unidades de negócio.
   Quer impacto no negócio, exposição financeira, poucos números, zero jargão.

# MODELO DE AUTORIZAÇÃO (não invente outro)
- O papel do usuário vem de **custom claims** do FirebaseAuth: `role`
  (`operational` | `strategic` | `board` | `pending`), `tenantId` e
  `tenantAdmin`.
- Os claims são espelhados em `/tenants/{tenantId}/members/{uid}`, usado apenas
  para dados de exibição (nome, cargo, unidade de negócio, foto).
- O aplicativo **nunca** escreve o próprio papel. Claim ausente ou desconhecido
  ⇒ `pending` (fail-closed), que leva a uma tela de "acesso pendente" e nunca a
  um dashboard.

# TAREFA
Implemente a **jornada de entrada** do aplicativo, composta por:

A) `SplashScreen` — exibida enquanto a sessão e os custom claims são resolvidos.
   Não decide nada; apenas informa que as credenciais estão sendo verificadas.

B) `WelcomeScreen` — a primeira tela que o executivo de segurança vê.
   Objetivo: em menos de 10 segundos ele entende (1) que produto é este,
   (2) que ele foi feito para o nível de decisão dele, (3) o que fazer agora.

   Conteúdo, nesta ordem:
   1. Marca: símbolo do Elytron desenhado em `CustomPainter` (escudo hexagonal
      com um vetor ascendente interno; gradiente verde → ciano). Sem depender de
      arquivo de imagem. Abaixo, o wordmark "ELYTRON / Dash2Board".
   2. Headline em duas linhas: **"A decisão de segurança / em uma única tela."**
   3. Subheadline: relatórios, tendências, insights e pesquisas de
      cibersegurança, privacidade e risco — traduzidos para o nível de quem
      decide.
   4. Vitrine das três personas: uma fileira de três abas selecionáveis
      (Operação / CISO / Board) e, abaixo, um cartão que muda conforme a aba,
      mostrando o rótulo da persona, uma etiqueta de público
      (ex.: "CISO · GRC · SEC STRATEGY"), a proposta de valor e três entregas
      concretas daquele painel. A aba **CISO vem selecionada por padrão**.
      IMPORTANTE: esta vitrine é PROVA DE ESCOPO, não seletor de permissão —
      deixe isso explícito em comentário no código.
   5. **Um único CTA primário**: `FilledButton.icon` "Entrar com e-mail
      corporativo" → rota de login. Um CTA secundário de SSO corporativo
      aparece somente se a flag de compilação `ENABLE_SSO` estiver ativa.
   6. Linha de confiança: "Acesso restrito a contas corporativas autorizadas".
   7. Rodapé: aviso de LGPD e a linha "Elytron Security · <AMBIENTE>".
   8. Botão de alternância de tema no canto superior direito.

C) `SignInScreen` — e-mail corporativo + senha, com:
   - validação de e-mail e de presença de senha;
   - mostrar/ocultar senha;
   - `AutofillGroup` com `AutofillHints.username/email/password`;
   - banner de erro acessível (`Semantics(liveRegion: true)`) alimentado por um
     `AppFailure` com mensagem segura em pt-BR;
   - "Esqueci minha senha" com diálogo de e-mail e resposta **uniforme**
     ("se este e-mail estiver cadastrado, você receberá as instruções"), para
     não permitir enumeração de usuários;
   - botão em estado de carregamento durante a autenticação.
   Em caso de sucesso **não navegue manualmente**: quem redireciona é o
   `redirect` do go_router, observando o estado do usuário.

D) `PendingAccessScreen` — autenticado, porém sem papel provisionado. Oferece
   "Verificar liberação agora" (força refresh do ID token) e "Sair".

E) Roteamento por persona com `go_router`, guarda única no `redirect`:
   - estado do usuário carregando ⇒ permanece no splash;
   - sem sessão ⇒ apenas `/boas-vindas` e `/entrar` são acessíveis;
   - autenticado sem papel/tenant ⇒ `/aguardando-acesso`;
   - autenticado e liberado ⇒ `/operacao`, `/estrategia` ou `/board` conforme o
     papel, e é **impedido** de abrir o dashboard de outra persona.

# DESIGN
- **Dark-first**: `ThemeMode.dark` é o padrão (padrão de ferramentas de SOC),
  com tema claro equivalente disponível por toggle.
- `ColorScheme` declarado explicitamente (sem `fromSeed`), porque as cores de
  severidade precisam ser estáveis: crítico `#FF4D5E`, alto `#FF8A3D`,
  médio `#FFC53D`, baixo `#21C7E8`.
- Acentos: verde Elytron `#00E08A` (marca e persona CISO), ciano `#21C7E8`
  (persona operacional), violeta `#A98BFF` (persona board).
- Superfícies escuras: fundo `#070B12`, superfície `#0E1622`,
  elevada `#16202E`, contorno `#24303F`.
- Escala de espaçamento base 4 e raios de canto centralizados em tokens
  (`AppSpacing`, `AppRadius`, `AppDuration`).
- Fundo institucional da jornada de entrada: duas ou três manchas de luz em
  movimento muito lento sobre a superfície escura, mais uma malha técnica
  discreta. Sutil, não pode competir com o conteúdo.

# ACESSIBILIDADE E RESPONSIVIDADE (obrigatório)
- Respeite `MediaQuery.disableAnimationsOf(context)`: com movimento reduzido,
  renderize versões estáticas — sem exceção.
- Escala de texto limitada com `MediaQuery.withClampedTextScaling`
  (mín. 0.9, máx. 1.4).
- Alvos de toque com no mínimo 48dp; `Semantics` com `header`, `button`,
  `selected` e `label` onde fizer sentido; `Tooltip` nos ícones.
- Conteúdo limitado a 520dp de largura e sempre dentro de `SingleChildScrollView`
  + `SafeArea`, para não quebrar em telas pequenas nem esticar em tablet.
- `AnnotatedRegion<SystemUiOverlayStyle>` para barra de status/navegação
  coerente com o tema.

# ESTRUTURA DE ARQUIVOS ESPERADA
lib/
  main.dart
  firebase_options.dart
  app/{app.dart, router.dart, providers.dart}
  core/config/{app_config.dart, firestore_paths.dart}
  core/theme/{app_colors.dart, app_typography.dart, app_spacing.dart, app_theme.dart}
  core/errors/{app_failure.dart, auth_error_mapper.dart}
  core/utils/validators.dart
  core/widgets/{elytron_logo.dart, surface_card.dart, aurora_backdrop.dart, app_text_field.dart}
  features/auth/domain/{user_role.dart, app_user.dart}
  features/auth/data/auth_repository.dart
  features/auth/presentation/{splash_screen.dart, welcome_screen.dart, sign_in_screen.dart, pending_access_screen.dart, persona_visuals.dart, sign_in_controller.dart}
  features/shell/persona_scaffold.dart
  features/dashboard/presentation/{operational,strategic,board}_dashboard_screen.dart

Mantenha `user_role.dart` livre de qualquer import do Flutter (domínio puro);
todo mapeamento visual da persona (cor, ícone, etiqueta) vive em
`persona_visuals.dart` como `extension`.

# ENTREGÁVEIS
1. Todos os arquivos acima, completos.
2. Testes em `test/`: `user_role_test.dart` (fail-closed do papel),
   `app_user_test.dart` (claims têm precedência sobre o documento),
   `validators_test.dart` e um teste de widget da `WelcomeScreen`.
   No teste de widget use `pump(Duration)` — **nunca** `pumpAndSettle`, porque o
   fundo tem animação contínua.
3. Ao final, liste em uma tabela: arquivo → responsabilidade, e os comandos
   para rodar (`flutter analyze`, `flutter test`, `flutter run`).

# COMO RESPONDER
Escreva os arquivos direto no projeto, um por vez, do mais interno (tokens e
domínio) para o mais externo (telas). Não peça confirmação entre arquivos. Ao
terminar, rode `flutter analyze` e corrija tudo até "No issues found!".
````

## Parte B — Critérios de aceite

| # | Critério | Como verificar |
|---|----------|----------------|
| 1 | `flutter analyze` sem nenhum apontamento | `flutter analyze` |
| 2 | Nenhuma ocorrência de `withOpacity` | `grep -rn "withOpacity" lib/` deve retornar vazio |
| 3 | Nenhuma API deprecada de `ColorScheme`/`ThemeData` | `grep -rn "surfaceVariant\|onBackground\|MaterialStateProperty" lib/` vazio |
| 4 | Testes verdes | `flutter test` |
| 5 | As três personas aparecem na tela de boas-vindas | teste de widget + inspeção visual |
| 6 | Um único CTA primário | inspeção visual |
| 7 | Papel desconhecido não abre dashboard | `user_role_test.dart` |
| 8 | Claim tem precedência sobre documento | `app_user_test.dart` |
| 9 | Movimento reduzido respeitado | Simulador → Acessibilidade → Reduzir movimento |
| 10 | Texto a 1.4x não quebra o layout | Simulador → tamanho de texto máximo |
| 11 | Contraste AA no tema escuro e no claro | conferir `#E8EEF5` sobre `#070B12` e `#0B1421` sobre `#F5F7FA` |
| 12 | Login não revela existência de conta | tentar e-mail inexistente e senha errada: mesma mensagem |

## Variações que você pode pedir depois

- "Troque a headline por 3 opções alternativas mais focadas em risco financeiro."
- "Adicione um passo de onboarding com consentimento LGPD antes do login."
- "Inclua SSO SAML via `OAuthProvider` e mantenha o e-mail/senha como fallback."
- "Crie a versão tablet da tela de boas-vindas em duas colunas."
