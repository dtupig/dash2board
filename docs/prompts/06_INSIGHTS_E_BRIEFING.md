# Prompt 6 — Insights, pesquisas e briefing executivo

**Entrega:** o feed de inteligência da Elytron e o artefato que o CISO leva
para a reunião. É o que transforma o app de "painel" em "produto".

---

````text
# CONTEXTO FIXO
Projeto: Elytron Dash2Board (`elytron_dash2board`), Flutter + Material 3.
LEIA antes: docs/02_PERSONAS.md, docs/01_MODELO_DADOS_FIRESTORE.md
(`insights`, `surveys`, `reports`), lib/features/strategic/ e
lib/core/widgets/charts/.

# REGRAS DE CÓDIGO (obrigatórias)
- `flutter analyze` em "No issues found!"; `deprecated_member_use` é ERRO.
- Opacidade só com `Color.withValues(alpha: ...)`.
- Proibido `ColorScheme.background`/`onBackground`/`surfaceVariant`,
  `CardTheme`/`DialogTheme`/`TabBarTheme` em `ThemeData`,
  `pageTransitionsTheme`, `MaterialState*`.
- Riverpod só com APIs estáveis. Sem code generation.
- pt-BR na interface e comentários; identificadores em inglês.
- Arquivos completos com imports. Nunca escreva "...".

# TAREFA

## A) Feed de insights — `/estrategia/insights`
`lib/features/strategic/presentation/insights_screen.dart`.

Lista de `InsightItem` de `insightsProvider`, agrupada por mês, com:
- cartão com tópico, título, resumo de 2 linhas, fonte e data em pt-BR;
- selo visual distinto para os itens de **benchmark de setor** (`isBenchmark`),
  porque é isso que o CISO usa para se comparar;
- filtro por tópico em chips no topo;
- tocar abre o detalhe em tela cheia com o texto completo e um botão
  "abrir fonte".

Regra editorial: nada de "leia mais" genérico. O resumo tem que dizer o fato,
não prometer o fato.

## B) Pesquisa / survey
Se houver `survey` ativa para o tenant, exiba no topo do feed um cartão
convidando a responder, com o número de CISOs que já responderam. Ao tocar,
abra `SurveyScreen` com as perguntas, uma por vez, barra de progresso, e
gravação da resposta em `/tenants/{tenantId}/surveys/{id}/responses/{uid}`
(no modo mock, apenas em memória).

Ao concluir, mostre o resultado agregado — a recompensa por responder é ver
onde você está em relação aos pares. Sem isso ninguém responde uma segunda vez.

## C) Briefing executivo — o artefato que sai do app
`lib/features/strategic/presentation/executive_briefing_screen.dart`, rota
`/estrategia/briefing`, acessível por um botão fixo no painel do CISO.

Monta, a partir dos dados já carregados, um documento de UMA página com:
1. índice de postura, variação de 12 meses e comparação com o setor;
2. os dois domínios mais fracos, com uma frase de consequência de negócio cada;
3. as três maiores exposições financeiras (ALE), em Real;
4. situação de compliance por framework, em percentual;
5. as decisões que dependem do comitê;
6. rodapé com a data de geração e a origem dos dados.

Tudo em linguagem de negócio — se uma frase precisa de sigla, ela precisa vir
explicada na mesma linha.

**Geração do arquivo:** produza um PDF. Use `pdf` + `printing` (adicione via
`flutter pub add pdf printing`, sem fixar versão manualmente). O `printing`
resolve o compartilhamento nativo em iOS e Android — e substitui o `TODO` que
o prompt 5 deixou no CSV de compliance: faça o CSV usar o mesmo caminho de
compartilhamento.

O PDF deve seguir a identidade: fundo claro (é impresso e projetado), acento
teal `#0E9C8F`, tipografia sóbria, logo desenhado. Não tente reaproveitar os
`CustomPainter` da tela — desenhe os gráficos do PDF com a API do pacote `pdf`.

## D) Pré-visualização antes de compartilhar
A tela mostra o briefing renderizado em Flutter primeiro; o botão
"compartilhar" gera o PDF. Ninguém envia para o board um arquivo que não viu.

# ESTADOS
Carregando, vazio e erro em todos os blocos. O briefing precisa de um estado
específico: quando faltar dado essencial (sem histórico de postura, por
exemplo), explique o que falta em vez de gerar um PDF com buracos.

# ACESSIBILIDADE
- O briefing em tela é lido por leitor de tela na ordem correta.
- Selo de benchmark tem texto, não só cor/ícone.
- Alvos ≥ 48dp; texto a 1.4x sem quebra.

# TESTES
`test/strategic/`:
- `insights_screen_test.dart`: agrupa por mês, filtra por tópico, selo de
  benchmark aparece nos 3 itens marcados;
- `executive_briefing_test.dart`: com os dados do mock, o briefing exibe índice
  72, variação +8 e os dois domínios mais fracos (`thirdParty`, `appsec`);
  com histórico vazio, exibe o estado de dado insuficiente.
Use `pump(Duration)`.

# CRITÉRIOS DE ACEITE
1. Do painel do CISO em dois toques chego a um PDF compartilhável.
2. O PDF abre no Preview do macOS e no compartilhamento do iOS sem erro.
3. Nenhuma sigla sem explicação no briefing.
4. `flutter analyze` limpo, `flutter test` verde.

# COMO RESPONDER
Feed primeiro, survey depois, briefing por último. Ao final rode
`flutter analyze` e `flutter test`, corrija até zerar, e cole no chat o texto
integral que o briefing gera com os dados do mock, para eu revisar a redação.
````
