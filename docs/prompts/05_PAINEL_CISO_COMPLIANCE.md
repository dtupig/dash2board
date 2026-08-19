# Prompt 5 — Compliance por framework e evidência

**Entrega:** a tela de compliance do CISO, acessível a partir do painel e do
drill-down de domínio.

---

````text
# CONTEXTO FIXO
Projeto: Elytron Dash2Board (`elytron_dash2board`), Flutter + Material 3.
LEIA antes: docs/01_MODELO_DADOS_FIRESTORE.md (coleção `compliance`),
docs/02_PERSONAS.md, lib/features/strategic/ e lib/core/widgets/charts/.
REUSE o kit de gráficos e os providers existentes.

# REGRAS DE CÓDIGO (obrigatórias)
- `flutter analyze` em "No issues found!"; `deprecated_member_use` é ERRO.
- Opacidade só com `Color.withValues(alpha: ...)`.
- Proibido `ColorScheme.background`/`onBackground`/`surfaceVariant`,
  `CardTheme`/`DialogTheme`/`TabBarTheme` em `ThemeData`,
  `pageTransitionsTheme`, `MaterialState*`.
- Riverpod só com APIs estáveis. Sem code generation.
- Gráfico só dentro de `ChartFrame`; cor só de `ChartTokens`/`AppColors`.
- pt-BR na interface e comentários; identificadores em inglês.
- Arquivos completos com imports. Nunca escreva "...".

# O PROBLEMA QUE ESTA TELA RESOLVE
O CISO é cobrado por auditoria e comitê com uma pergunta específica: "estamos
em conformidade com X, e você consegue provar?". A tela precisa responder as
duas partes — o número e a evidência. Uma tela de compliance sem caminho até a
evidência é decorativa.

# TAREFA

## A) Rota
Adicione `/estrategia/compliance` em `lib/app/router.dart`, como rota FILHA de
`/estrategia` (mantendo a guarda de persona já existente: apenas `strategic`
entra). Aceite o parâmetro de consulta opcional `?framework=iso27001` e
`?domain=cloud` para o drill-down vindo do painel.

## B) Tela `ComplianceScreen`
`lib/features/strategic/presentation/compliance_screen.dart`.

1. **Resumo por framework.** Para cada um dos quatro frameworks (ISO 27001,
   NIST CSF, LGPD, PCI DSS), um cartão com: nome, percentual de conformidade,
   `StackedStatusBar` 100% (`compliant`/`partial`/`gap`) e a contagem absoluta
   de lacunas. Tocar seleciona o framework e filtra a lista abaixo.
   A barra empilhada usa as cores de status, com 2px de folga entre segmentos e
   legenda com ícone + rótulo — nunca só cor.

2. **Filtros em uma única linha acima da lista:** framework (chips),
   status (chips) e domínio (dropdown). O estado dos filtros vive em um
   `Notifier` (`complianceFilterProvider`), e a URL reflete o filtro, para que
   o drill-down do painel abra já filtrado.

3. **Lista de controles.** Cada item mostra: `controlId`, título, `SeverityChip`
   do status, responsável e data da última revisão em pt-BR. Ordenação padrão:
   `gap` primeiro, depois `partial`, depois `compliant`; dentro de cada grupo
   por data de revisão mais antiga. Use `ListView.builder`.

4. **Detalhe do controle.** Tocar abre `ControlDetailSheet`
   (`showModalBottomSheet`, com `DraggableScrollableSheet`): descrição
   completa, histórico de revisão, responsável, e o bloco de **evidência**.
   Quando houver `evidenceUrl`: botão "abrir evidência". Quando não houver:
   um estado vazio explícito dizendo que o controle não tem evidência anexada —
   isso é informação, não um espaço em branco.

5. **Cabeçalho da tela** com o total de lacunas abertas e quantas venceram o
   prazo de revisão. Este é o número que vai para o comitê.

## C) Exportar a lista
Botão "exportar" no cabeçalho que gera um CSV do resultado filtrado
(`framework;controlId;titulo;status;responsavel;ultima_revisao`) e compartilha.
Não adicione dependência de compartilhamento agora: escreva o arquivo em
diretório temporário e mostre o caminho num `SnackBar`, com um `TODO(prompt 6)`
indicando que o compartilhamento real chega junto com o briefing executivo.

# ESTADOS
Carregando, vazio e erro em todos os blocos, com os widgets do prompt 3. O
estado vazio de "nenhum controle com esse filtro" precisa oferecer "limpar
filtros".

# ACESSIBILIDADE
- Chips de filtro com `Semantics(selected:)`.
- A barra empilhada tem alternativa em tabela via `onShowTable`.
- Status nunca comunicado só por cor: sempre ícone + texto.
- Alvos ≥ 48dp.

# TESTES
`test/strategic/compliance_screen_test.dart`:
- os quatro frameworks aparecem;
- filtrar por `gap` reduz a lista e a contagem bate;
- abrir um controle sem evidência mostra o estado vazio de evidência;
- navegar com `?framework=lgpd` já abre filtrado.
Use `pump(Duration)`.

# CRITÉRIOS DE ACEITE
1. Do painel do CISO, tocar numa barra de domínio e depois "ver compliance"
   abre esta tela já filtrada por aquele domínio.
2. Um usuário `board` ou `operational` que tente `/estrategia/compliance` é
   redirecionado pela guarda existente.
3. `flutter analyze` limpo, `flutter test` verde.

# COMO RESPONDER
Comece pela rota e pelo provider de filtro, depois a tela, depois o sheet de
detalhe. Ao final rode `flutter analyze` e `flutter test` e corrija até zerar.
````
