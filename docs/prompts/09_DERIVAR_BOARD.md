# Prompt 9 *(opcional)* — Painel do Board derivado do painel do CISO

Rode este prompt quando a demo do CISO estiver aprovada. Ele reaproveita
praticamente tudo — a diferença é de **linguagem e de grão**, não de dado.

---

````text
# CONTEXTO FIXO
Projeto: Elytron Dash2Board (`elytron_dash2board`), Flutter + Material 3.
LEIA antes: docs/02_PERSONAS.md (persona `board`), todo o
lib/features/strategic/ e lib/core/widgets/charts/. REUSE agressivamente.

# REGRAS DE CÓDIGO (obrigatórias)
- `flutter analyze` em "No issues found!"; `deprecated_member_use` é ERRO.
- Opacidade só com `Color.withValues(alpha: ...)`; sem `MaterialState*`;
  sem `pageTransitionsTheme`; sem `CardTheme`/`DialogTheme`/`TabBarTheme`.
- Riverpod só com APIs estáveis. Sem code generation.
- pt-BR na interface e comentários; identificadores em inglês.
- Arquivos completos com imports. Nunca escreva "...".

# A REGRA QUE GOVERNA ESTA TELA
Zero jargão. Se um termo técnico é indispensável, ele aparece explicado na
mesma linha, em linguagem de negócio. Nada de CVSS, EPSS, MITRE, CVE, SIEM,
"postura" ou "controle" sem tradução. O leitor é um diretor de unidade de
negócio que dá dez minutos ao assunto por mês.

Uma verificação prática: se a frase não caberia numa ata de reunião de
conselho, ela não entra na tela.

# TAREFA
Reescreva `lib/features/dashboard/presentation/board_dashboard_screen.dart`
mantendo o `PersonaScaffold`. **Três blocos, nada mais.**

## 1. Exposição financeira (hero number)
`KpiTile` com a perda anual esperada somada, em Real, e como percentual da
receita (adicione `annualRevenue` ao tenant no mock). `DeltaBadge` de variação
trimestral. Abaixo, uma frase única em linguagem simples explicando o que o
número significa e de onde vem.

## 2. Impacto por unidade de negócio
`DomainBarChart` reaproveitado, agrupando `RiskItem` por `businessUnit` em vez
de por domínio técnico. Barras em Real. Ao lado de cada unidade, o nome do
executivo responsável — risco sem dono nomeado não gera decisão.

Tocar abre um sheet com os riscos daquela unidade, cada um com: o que pode
acontecer, quanto custaria, e o que está sendo feito. Três frases por risco, no
máximo.

## 3. Decisões pendentes do board
Lista dos riscos com `acceptance == pending`, cada um com prazo, consequência
de não decidir, e dois botões: **"aceitar o risco"** e **"solicitar plano"**.

O aceite grava `acceptance`, `acceptedByUid`, `acceptedAt` e `boardNote` — os
únicos campos que a `firestore.rules` libera para o papel `board`. Exija uma
nota escrita antes de confirmar: um aceite de risco sem justificativa registrada
não serve para auditoria. Mostre um diálogo de confirmação explicitando o que
está sendo aceito e por quanto tempo.

# O QUE **NÃO** PODE APARECER
Índice de postura, domínios de controle, frameworks de compliance, CVEs,
incidentes, nomes de ferramenta. Se o board quiser detalhe, ele chama o CISO —
essa é a divisão de trabalho que o produto assume.

# ESTADOS
Os quatro estados de sempre. O estado vazio de "nenhuma decisão pendente" é uma
boa notícia: escreva como tal.

# TESTES
`test/board/board_dashboard_test.dart`:
- exibe a soma de ALE dos riscos do mock;
- agrupa por unidade de negócio, ordenado por exposição;
- não renderiza NENHUM texto da lista de jargão proibido (teste isso
  explicitamente, varrendo a árvore de widgets por uma lista de termos);
- confirmar aceite sem nota é bloqueado.

# CRITÉRIOS DE ACEITE
1. Login como `board@demo.elytron` abre esta tela e nenhuma outra.
2. O teste de jargão proibido passa.
3. Um aceite de risco aparece na trilha de auditoria (no modo real).
4. `flutter analyze` limpo, `flutter test` verde.

# COMO RESPONDER
Reuse os widgets existentes; crie widget novo apenas se realmente não houver
equivalente. Ao final, cole todo o texto visível da tela para eu revisar se
está mesmo livre de jargão.
````
