# Prompt 3 — Kit de visualização de dados

**Entrega:** tokens de gráfico validados + os widgets de visualização que os
três painéis vão reusar.

**Por que antes dos painéis:** se cada tela inventar o próprio gráfico, a demo
fica visualmente incoerente e a correção depois é cara.

> **As cores abaixo não são gosto pessoal.** Foram geradas em OKLCH e validadas
> com um verificador que mede banda de luminosidade, piso de croma, separação
> sob daltonismo (protanopia/deuteranopia, ΔE OKLab) e contraste contra a
> superfície. Rodei nas duas superfícies do app: escura `#16202E` e clara
> `#FFFFFF`. **Todos os checks passam nos dois modos.**
>
> Achado importante: os acentos da marca (`#00E08A`, `#21C7E8`, `#A98BFF`)
> **reprovam** a banda de luminosidade como preenchimento de gráfico no tema
> escuro — são claros demais e vibram sobre o fundo. Continuam corretos para
> CTA, ícone e borda fina; não para área/barra/linha.

---

````text
# CONTEXTO FIXO
Projeto: Elytron Dash2Board (`elytron_dash2board`), Flutter + Material 3.
LEIA antes: README.md, docs/00_ARQUITETURA.md e lib/core/theme/ (app_colors,
app_typography, app_spacing, app_theme). Reuse os tokens existentes.

# REGRAS DE CÓDIGO (obrigatórias)
- `flutter analyze` deve terminar em "No issues found!"; `deprecated_member_use`
  é ERRO.
- Opacidade só com `Color.withValues(alpha: ...)`.
- Proibido `ColorScheme.background`/`onBackground`/`surfaceVariant`,
  `CardTheme`/`DialogTheme`/`TabBarTheme` em `ThemeData`,
  `pageTransitionsTheme`, `MaterialState*`.
- Riverpod apenas com APIs estáveis (`Provider`, `StreamProvider`,
  `Notifier`, `AsyncNotifier`). Sem code generation.
- pt-BR na interface e nos comentários; identificadores em inglês.
- Arquivos completos, com imports. Nunca escreva "...".

# DEPENDÊNCIA DE GRÁFICO
NÃO adicione biblioteca de gráficos. Desenhe com `CustomPainter`. Motivos:
controle total de acessibilidade e de tema, zero risco de deprecation vinda de
terceiros, e os gráficos aqui são simples (linha, barra, barra empilhada,
sparkline). Se em algum momento precisar de algo além disso, pare e pergunte.

# TAREFA

## A) Tokens de gráfico — `lib/core/theme/chart_tokens.dart`
Crie `abstract final class ChartTokens` com EXATAMENTE estes valores:

Categórica (identidade de série) — ordem FIXA, no máximo 3 séries:
  slot1 `Color(0xFF0E9C8F)`   // teal   — "nossa organização"
  slot2 `Color(0xFF7C79EE)`   // indigo — "mediana do setor"
  slot3 `Color(0xFFC07A18)`   // âmbar  — "meta"

Sequencial (magnitude, matiz única) — tema ESCURO, do menor para o maior:
  `[0xFF0E7F75, 0xFF0E9C8F, 0xFF2FBBAD, 0xFF6ED6C9, 0xFFAEEDE4]`
Sequencial — tema CLARO, do menor para o maior:
  `[0xFF5CC1B3, 0xFF2FAB9D, 0xFF0C8F83, 0xFF0A6E64, 0xFF064B44]`

Divergente (variação: piorou ↔ melhorou):
  polo negativo `Color(0xFFC07A18)`, ponto neutro `Color(0xFF7C8CA1)` (cinza,
  nunca um matiz), polo positivo `Color(0xFF0E9C8F)`.

Status/severidade — REUSE `AppColors.severityCritical/High/Medium/Low`.
Estas são reservadas: **nunca** podem ser usadas como cor de série.

Documente no cabeçalho do arquivo que os valores são validados e que alterá-los
exige revalidar.

## B) Regras que o código deve respeitar (escreva-as como comentário no arquivo
## de tokens e obedeça em todos os widgets)
1. Cor por função: identidade → categórica; magnitude → sequencial de matiz
   única; polaridade → divergente com cinza no meio; estado → status.
2. Ordem categórica é fixa e nunca ciclada. Uma 4ª série não existe: vire
   "Outros", ou separe em gráficos pequenos.
3. **Nunca dois eixos Y.** Duas medidas de escalas diferentes viram dois
   gráficos ou são indexadas a uma base comum.
4. A cor segue a entidade, não a posição. Filtrar séries não pode repintar as
   que sobraram.
5. A partir de 2 séries a legenda é obrigatória, e a identidade nunca é só cor:
   rótulo direto ou marcador com forma.
6. Texto usa os tokens de texto (`onSurface`/`onSurfaceVariant`), nunca a cor
   da série.
7. Grade e eixos são recessivos: `outlineVariant` com alpha ≤ 0.5, 1px.
8. Marcas finas: linha de 2px, ponto ≥ 8px, topo de barra arredondado em 4px
   ancorado na linha de base, 2px de folga entre segmentos empilhados.
9. Rótulo direto é seletivo — nunca um número em cada ponto.
10. Tema claro tem passos próprios, escolhidos, não um espelho invertido do
    escuro.

## C) Widgets — `lib/core/widgets/charts/`
Todos `StatelessWidget` (ou `StatefulWidget` só onde houver toque), com
`Semantics` descrevendo o dado em texto, e todos respeitando
`MediaQuery.disableAnimationsOf(context)`.

1. `kpi_tile.dart` — `KpiTile`: rótulo, valor grande, unidade, `DeltaBadge`
   opcional e `Sparkline` opcional. É a forma correta para "um número que
   importa" — não force um gráfico onde um número basta.
2. `delta_badge.dart` — `DeltaBadge`: variação com seta e sinal, usando a
   escala divergente. Zero usa o cinza neutro. Inclui `Semantics` do tipo
   "subiu 8 pontos em 30 dias".
3. `sparkline.dart` — `Sparkline`: série única, sem eixos, sem rótulos, 2px.
4. `trend_line_chart.dart` — `TrendLineChart`: **até 3 séries**, eixo X de
   tempo, eixo Y único, grade horizontal recessiva, legenda obrigatória a
   partir de 2 séries, rótulo direto apenas no último ponto de cada série.
   Toque em um ponto abre um tooltip com data e valores de todas as séries
   naquele X (crosshair). Área sob a linha só na série 1, com alpha 0.12.
5. `domain_bar_chart.dart` — `DomainBarChart`: barras horizontais, **matiz
   única da rampa sequencial** (a identidade vem do rótulo do eixo, não da
   cor), valor rotulado no fim da barra, marcador vertical opcional para a
   mediana do setor. Ordenação por valor, decrescente.
6. `stacked_status_bar.dart` — `StackedStatusBar`: barra 100% empilhada para
   compliance (`compliant`/`partial`/`gap`), com 2px de folga entre segmentos,
   legenda com ícone + rótulo, nunca só cor.
7. `severity_chip.dart` — `SeverityChip`: chip com ícone + texto + cor de
   status.
8. `chart_frame.dart` — `ChartFrame`: moldura comum (título, subtítulo,
   ação opcional no canto, altura fixa, `SurfaceCard` por baixo) mais os três
   estados: `ChartLoading` (skeleton com shimmer sutil), `ChartEmpty`
   (mensagem + o que fazer) e `ChartError` (mensagem segura + "tentar de
   novo"). Nenhum painel pode desenhar gráfico fora de um `ChartFrame`.
9. `chart_legend.dart` — `ChartLegend`: marcador + rótulo, quebra em duas
   linhas quando não couber.

## D) Alternativa textual (acessibilidade)
Cada gráfico aceita `onShowTable`. Quando fornecido, `ChartFrame` exibe um
botão "ver dados" que abre um `showModalBottomSheet` com a tabela do mesmo
conteúdo. Um leitor de tela precisa conseguir chegar ao número.

# TESTES
`test/charts/`:
- `chart_tokens_test.dart`: a lista categórica tem exatamente 3 cores; nenhuma
  cor de severidade aparece na lista categórica; as rampas sequenciais têm 5
  passos.
- `delta_badge_test.dart`: sinal e semântica corretos para positivo, negativo
  e zero.
- `trend_line_chart_test.dart`: renderiza com 1, 2 e 3 séries; com 4 séries
  lança `AssertionError` (a regra é dura, não uma sugestão).
- `chart_frame_test.dart`: os três estados renderizam.
Use `pump(Duration)` — nunca `pumpAndSettle`.

# CRITÉRIOS DE ACEITE
1. Nenhum widget de gráfico importa pacote de terceiros.
2. `grep -rn "AppColors.brandGreen\|brandCyan\|brandViolet" lib/core/widgets/charts/`
   não retorna nada (acento de marca não preenche gráfico).
3. Os gráficos renderizam legíveis nos dois temas.
4. `flutter analyze` limpo e `flutter test` verde.

# COMO RESPONDER
Escreva os tokens primeiro, depois os widgets do mais simples ao mais complexo.
Ao final rode `flutter analyze` e `flutter test`. Depois monte uma tela
temporária de galeria em `lib/features/dev/chart_gallery_screen.dart` (rota
`/dev/graficos`, disponível apenas quando `AppConfig.mockMode`) mostrando todos
os widgets com dados de exemplo, para inspeção visual.
````
