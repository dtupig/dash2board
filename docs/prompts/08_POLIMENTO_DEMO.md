# Prompt 8 — Polimento e roteiro de demonstração

**Entrega:** o app pronto para ser mostrado a um cliente sem pedir desculpas.

---

````text
# CONTEXTO FIXO
Projeto: Elytron Dash2Board (`elytron_dash2board`), Flutter + Material 3 + Firebase.
LEIA antes: README.md, docs/00_ARQUITETURA.md, docs/02_PERSONAS.md e todo o
lib/features/strategic/.

# REGRAS DE CÓDIGO (obrigatórias)
- `flutter analyze` em "No issues found!"; `deprecated_member_use` é ERRO.
- Opacidade só com `Color.withValues(alpha: ...)`; sem `MaterialState*`;
  sem `pageTransitionsTheme`; sem `CardTheme`/`DialogTheme`/`TabBarTheme`.
- Riverpod só com APIs estáveis. Sem code generation.
- pt-BR na interface e comentários; identificadores em inglês.
- Arquivos completos com imports. Nunca escreva "...".

# TAREFA

## A) Varredura de estados
Percorra TODAS as telas e garanta os quatro estados em cada bloco de conteúdo:
carregando (skeleton, não spinner solto), vazio (com o que fazer a seguir),
erro (mensagem segura + "tentar de novo"), e sucesso. Liste em tabela o que
encontrou faltando e corrija.

Skeleton: use o mesmo componente em todo lugar, com shimmer sutil, e desligue-o
quando `MediaQuery.disableAnimationsOf(context)` for verdadeiro.

## B) Auditoria de acessibilidade
Rode e corrija:
1. Contraste AA em ambos os temas, incluindo texto sobre gráfico.
2. Todo alvo de toque ≥ 48dp.
3. Ordem de foco do leitor de tela coerente em cada tela.
4. Todo gráfico com resumo em `Semantics` e alternativa em tabela.
5. Nada comunicado só por cor.
6. Texto a 1.4x sem overflow em iPhone SE (tela pequena é o pior caso).
7. `flutter test --update-goldens` não é necessário, mas rode o app com
   "Reduzir movimento" ligado e confirme que nenhuma animação contínua roda.

Escreva o resultado em `docs/06_ACESSIBILIDADE.md`, com o que passou, o que foi
corrigido e o que ficou como dívida consciente.

## C) Performance
- Nenhum `build` fazendo trabalho pesado: mova cálculo para o provider.
- `const` onde possível.
- `ListView.builder` em toda lista de tamanho variável.
- `CustomPainter.shouldRepaint` correto em todos os painters.
- Rode `flutter run --profile` e confirme que a rolagem do painel do CISO fica
  acima de 55 fps num iPhone real ou simulador. Relate os números.

## D) Primeira execução
Adicione um onboarding de 3 telas exibido apenas no primeiro login de cada
persona (persistido em `shared_preferences`), explicando o que aquele painel
entrega. Pulável, nunca obrigatório, e nunca reaparece.

## E) Conteúdo de demonstração revisado
Releia todos os textos de mock com olhos de cliente: nomes de unidade de
negócio plausíveis, títulos de risco em português de negócio, nenhum
"Lorem ipsum", nenhum "TODO" visível, nenhuma data no futuro.

## F) Roteiro de demonstração
Escreva `docs/07_ROTEIRO_DEMO.md` com um roteiro de **5 minutos**:
- o que dizer na tela de boas-vindas (30s);
- login como CISO e as três frases que a tela responde (90s);
- drill-down em terceiros → compliance → evidência (90s);
- briefing executivo e o PDF (60s);
- troca para a persona Board para mostrar a mesma verdade em outra linguagem
  (30s).
Inclua, para cada trecho, a pergunta que o cliente provavelmente vai fazer e a
resposta curta.

## G) Captura
Gere capturas de tela das telas principais nos dois temas, em
`docs/screenshots/`, usando o simulador. Nomeie por tela e tema.

# CRITÉRIOS DE ACEITE
1. Nenhuma tela com spinner solto ou estado vazio mudo.
2. `docs/06_ACESSIBILIDADE.md` e `docs/07_ROTEIRO_DEMO.md` existem e são
   específicos, não genéricos.
3. Rolagem acima de 55 fps em profile.
4. `flutter analyze` limpo, `flutter test` verde.

# COMO RESPONDER
Comece pela varredura de estados (é onde estão os buracos), depois
acessibilidade, depois o resto. Ao final, cole a tabela de estados e os números
de performance.
````
