# Prompt 4 — Painel do CISO v1: postura, tendência e risco por domínio

**Entrega:** a tela que substitui os `PlaceholderPanel` de
`strategic_dashboard_screen.dart`. É o coração da demo.

---

````text
# CONTEXTO FIXO
Projeto: Elytron Dash2Board (`elytron_dash2board`), Flutter + Material 3.
LEIA antes: docs/02_PERSONAS.md (persona `strategic`), docs/00_ARQUITETURA.md,
lib/features/strategic/ (modelos e providers do prompt 2) e
lib/core/widgets/charts/ (kit do prompt 3). REUSE — não recrie nada.

# REGRAS DE CÓDIGO (obrigatórias)
- `flutter analyze` em "No issues found!"; `deprecated_member_use` é ERRO.
- Opacidade só com `Color.withValues(alpha: ...)`.
- Proibido `ColorScheme.background`/`onBackground`/`surfaceVariant`,
  `CardTheme`/`DialogTheme`/`TabBarTheme` em `ThemeData`,
  `pageTransitionsTheme`, `MaterialState*`.
- Riverpod só com APIs estáveis. Sem code generation.
- Nenhum gráfico fora de `ChartFrame`. Nenhuma cor de gráfico fora de
  `ChartTokens`.
- pt-BR na interface e comentários; identificadores em inglês.
- Arquivos completos com imports. Nunca escreva "...".

# QUEM VAI OLHAR ESTA TELA
Um CISO, quase sempre no celular, dez minutos antes de uma reunião de comitê.
Ele precisa sair da tela conseguindo dizer três frases em voz alta:
  1. "Nossa postura está em X, subiu/caiu Y no ano."
  2. "O problema está concentrado em <domínio>."
  3. "Comparado ao setor, estamos acima/abaixo."
Se a tela não entrega isso em 10 segundos de rolagem, ela falhou.

# TAREFA
Reescreva `lib/features/dashboard/presentation/strategic_dashboard_screen.dart`
mantendo o `PersonaScaffold`. Estrutura, de cima para baixo:

## 1. Cabeçalho de resultado (sem gráfico)
`KpiTile` grande com o índice de postura atual, `DeltaBadge` de variação em 12
meses e `Sparkline` da série. Ao lado, em texto secundário, a mediana do setor
com a diferença explicitada em palavras ("6 pontos acima da mediana do setor").
Isto é uma "hero number" — não transforme em gráfico.

## 2. Tendência de 12 meses
`TrendLineChart` dentro de `ChartFrame`:
- título "Evolução da postura", subtítulo "últimos 12 meses";
- **duas séries**: "Nossa organização" (slot 1) e "Mediana do setor" (slot 2);
- terceira série "Meta" (slot 3) só quando houver meta definida;
- eixo Y único de 0 a 100, grade horizontal a cada 25;
- rótulo direto apenas no último ponto;
- toque exibe crosshair com mês e os valores;
- `onShowTable` preenchido.

## 3. Risco por domínio
`DomainBarChart` dentro de `ChartFrame`:
- título "Onde está o risco", subtítulo "índice por domínio de controle";
- seis domínios ordenados do pior para o melhor — o pior aparece primeiro,
  porque é sobre ele que a conversa vai acontecer;
- matiz única da rampa sequencial; marcador vertical na mediana do setor;
- tocar em uma barra abre um `ModalBottomSheet` com: nome do domínio,
  índice, variação em 30 dias, mediana do setor e uma lista dos controles em
  `gap` daquele domínio (vindos de `complianceProvider`), com um botão
  "ver compliance" que leva à tela do prompt 5 já filtrada.

## 4. Top riscos de negócio
Lista de até 5 `RiskItem` de `topRisksProvider`, cada um em `SurfaceCard`:
título em linguagem de negócio, unidade de negócio, `SeverityChip` derivado do
`residualScore`, e ALE formatado em Real brasileiro
(`NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')` do pacote `intl`),
abreviando milhões ("R$ 4,2 mi"). Ordenado por ALE decrescente.

## 5. Rodapé de contexto
Data e hora da última atualização dos dados, formatada com `intl` em pt-BR, e
a origem ("dados de demonstração" quando `AppConfig.mockMode`).

# ESTADOS
Cada bloco consome seu `AsyncValue` e resolve os três casos com os widgets do
prompt 3: `ChartLoading`, `ChartEmpty`, `ChartError`. A tela NUNCA mostra um
`CircularProgressIndicator` solto no meio do conteúdo, e nunca mostra um
gráfico vazio sem explicação.

Erro: mensagem do `AppFailure` mais botão "tentar de novo" que faz
`ref.invalidate` do provider correspondente. Nada de mensagem técnica.

# ESTRUTURA DE ARQUIVOS
Quebre em widgets privados, um por bloco, em
`lib/features/strategic/presentation/widgets/`:
`posture_headline.dart`, `posture_trend_section.dart`,
`domain_risk_section.dart`, `domain_detail_sheet.dart`,
`top_risks_section.dart`, `data_freshness_footer.dart`.
A tela principal só compõe. Nenhum arquivo acima de 250 linhas.

# ACESSIBILIDADE E RESPONSIVIDADE
- Todo gráfico tem `Semantics` com o resumo em texto e `onShowTable`.
- Alvos de toque ≥ 48dp.
- Texto a 1.4x não pode quebrar o layout (o app já limita a escala).
- Conteúdo dentro de `SafeArea` e rolável; em largura ≥ 600 use duas colunas
  para os blocos 3 e 4.

# TESTES
`test/strategic/strategic_dashboard_test.dart`, usando `ProviderScope` com
`overrideWith` do `strategicRepositoryProvider` apontando para o mock:
- renderiza o índice 72 e a variação de +8;
- renderiza as seis barras de domínio;
- a primeira barra é `thirdParty` (o pior);
- estado de erro exibe o botão "tentar de novo".
Use `pump(Duration)`, nunca `pumpAndSettle`.

# CRITÉRIOS DE ACEITE
1. `flutter run --dart-define=MOCK=true`, login `ciso@demo.elytron`, e a tela
   abre completa em menos de 2 segundos.
2. As três frases da seção "quem vai olhar" são respondíveis olhando a tela.
3. Nenhum eixo Y duplo em lugar nenhum.
4. Nenhuma cor de severidade usada como cor de série.
5. `flutter analyze` limpo, `flutter test` verde.

# COMO RESPONDER
Escreva os widgets de bloco antes da tela. Ao final rode `flutter analyze` e
`flutter test`, corrija até zerar, e descreva em texto o que aparece na tela de
cima para baixo, para eu conferir sem abrir o simulador.
````
