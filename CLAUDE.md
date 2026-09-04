# Elytron Dash2Board — regras do projeto

Aplicativo mobile (iOS + Android) de relatórios, tendências e insights de
cibersegurança para CISOs e tomadores de decisão. Flutter + Material 3 sobre
Firebase, multi-tenant, com quatro personas.

**Leia antes de mudar arquitetura:** `docs/00_ARQUITETURA.md`,
`docs/02_PERSONAS.md`, `docs/11_MODELO_FISICO_DADOS.md`,
`docs/13_DECISOES_PENDENTES.md`.

**`RETOMAR D2B`** — quando esta palavra-chave aparecer na conversa, leia
`docs/20_RETOMADA_SESSAO.md` (estado atual, decisões do PO e plano vigente)
antes de responder qualquer coisa.

## Regras de código — inegociáveis

1. `flutter analyze` precisa terminar em **"No issues found!"**.
   `deprecated_member_use` é tratado como **erro**, não aviso.
2. Opacidade **sempre** com `Color.withValues(alpha: ...)`.
   `Color.withOpacity(...)` é **proibido**.
3. Proibido em `ThemeData`: `CardTheme`, `DialogTheme`, `TabBarTheme`
   (use os equivalentes `...ThemeData`) e `pageTransitionsTheme` — os builders
   de transição mudam de nome entre versões do Flutter e quebram o build.
4. Proibido `ColorScheme.background`, `onBackground` e `surfaceVariant`.
   Use `surface`, `onSurface`, `onSurfaceVariant` e a família
   `surfaceContainer*`.
5. `WidgetState*` no lugar de `MaterialState*`.
6. Riverpod: apenas APIs estáveis entre 2.x e 3.x — `Provider`,
   `StreamProvider`, `FutureProvider`, `Notifier`/`NotifierProvider`,
   `AsyncNotifier`/`AsyncNotifierProvider`. **Nunca** `AutoDispose*Notifier`,
   `StateNotifier` ou code generation.
7. Em teste de widget, **nunca** `pumpAndSettle` — o app tem animações
   contínuas (fundo aurora, skeleton). Use `pump(Duration)`.
8. Interface e comentários em **pt-BR**; identificadores em inglês.
9. Arquivos completos, com todos os imports. Nunca escreva "...".
10. Máximo de 250 linhas por arquivo.

## Fronteiras de arquitetura

- `domain/` é **Dart puro**: sem import de Flutter e sem import de Firebase.
- `presentation/` **nunca** importa `cloud_firestore` nem `firebase_auth`.
- Todo repositório tem implementação mock e Firestore, escolhidas em **um**
  provider. Nenhuma tela sabe qual está ativa.
- Todo acesso a dado de cliente recebe `tenantId` **explícito**. Não existe
  consulta "de todos os tenants" no cliente.
- Regra de autorização vive em classe de política testável
  (`RequestPolicy`, `ReportAccessPolicy`, `StaffPolicy`), nunca dentro de
  widget.

## Visualização de dados

- Gráfico só dentro de `ChartFrame`; cor só de `ChartTokens`.
- Os acentos da marca (`brandGreen`, `brandCyan`, `brandViolet`) **não** podem
  preencher gráfico — reprovam a banda de luminosidade. São para CTA e borda.
- Nunca dois eixos Y. Máximo 3 séries categóricas, em ordem fixa.
- Cor de severidade é reservada: nunca vira cor de série.

## Segurança — invariantes do produto

- Vazamento entre tenants é falha crítica, com teste dedicado.
- Papel do usuário vem de **custom claims**, nunca do cliente. Valor
  desconhecido vira `pending` (fail-closed).
- A persona `board` nunca vê seção `exploitProof`, `personalData` ou
  `chainOfCustody`.
- Cliente nunca lê relatório em rascunho.
- `audit_logs` e `custody_records` são append-only e ilegíveis pelo app.
- Mensagem de credencial inválida é sempre a mesma, para não permitir
  enumeração de usuários.

## Executar

```bash
flutter run --dart-define=MOCK=true        # sem Firebase, contas de demonstração
flutter analyze && flutter test
firebase emulators:start
./scripts/audit.sh                         # laudo de qualidade
```

## Fluxo de trabalho

Um branch por prompt, automatizado em `scripts/prompt`:

```bash
./scripts/prompt start 10                  # branch + abre o prompt
./scripts/prompt check                     # format, analyze, test, audit
./scripts/prompt ship "feat(escopo): …"    # commit, push, PR, CI, merge
```

`main` é protegido: nada entra sem PR com os checks verdes.

## Antes de dar por pronto

`flutter analyze` limpo, `flutter test` verde, e nenhuma regra acima violada.
