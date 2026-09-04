# Roteiro de execução — prompts em sequência

**Objetivo deste bloco:** chegar a uma **demo vendável do painel do CISO**
(persona `strategic`), com dados mockados de qualidade e gráficos reais, antes
de investir na ingestão de dado verdadeiro.

## Como usar

1. Abra o terminal do VSCode na raiz do projeto e rode `claude`.
2. Abra o arquivo do prompt, copie **todo o conteúdo entre as cercas ```text**
   e cole na sessão.
3. Ao terminar, rode `flutter analyze` e `flutter test`. Só avance com ambos
   limpos.
4. Faça commit antes do próximo prompt — assim dá para voltar atrás.

```bash
git add -A && git commit -m "prompt 0X: <resumo>"
```

## Sequência

| # | Arquivo | Entrega | Dep. |
|---|---|---|---|
| 1 | [`../03_PROMPT_TELA_BOAS_VINDAS.md`](../03_PROMPT_TELA_BOAS_VINDAS.md) | Splash, boas-vindas, login, roteamento por persona | — |
| 2 | [`02_CAMADA_DADOS_MOCK.md`](02_CAMADA_DADOS_MOCK.md) | Modelos de domínio + repositórios com fonte alternável **mock ↔ Firestore**, e modo `MOCK=true` que roda **sem Firebase configurado** | 1 |
| 3 | [`03_KIT_VISUALIZACAO.md`](03_KIT_VISUALIZACAO.md) | Tokens de gráfico validados + widgets (KPI, tendência, barras, severidade, delta) | 2 |
| 4 | [`04_PAINEL_CISO_POSTURA.md`](04_PAINEL_CISO_POSTURA.md) | Painel do CISO v1: índice de postura, tendência 12m, risco por domínio | 3 |
| 5 | [`05_PAINEL_CISO_COMPLIANCE.md`](05_PAINEL_CISO_COMPLIANCE.md) | Compliance por framework + drill-down de controle + evidência | 4 |
| 6 | [`06_INSIGHTS_E_BRIEFING.md`](06_INSIGHTS_E_BRIEFING.md) | Insights/pesquisas e o briefing executivo compartilhável | 4 |
| 7 | [`07_FIRESTORE_REAL.md`](07_FIRESTORE_REAL.md) | Seed, emuladores, repositórios reais, testes das security rules | 5, 6 |
| 8 | [`08_POLIMENTO_DEMO.md`](08_POLIMENTO_DEMO.md) | Estados de carregamento/vazio/erro, acessibilidade, performance, roteiro de apresentação | 7 |
| 9 | [`09_DERIVAR_BOARD.md`](09_DERIVAR_BOARD.md) | *(opcional)* Painel do Board derivado do do CISO | 8 |
| 10 | [`10_CATALOGO_E_WIZARD.md`](10_CATALOGO_E_WIZARD.md) | Catálogo dos 44 serviços, bifurcação relatórios/demanda, wizard de RFS e alçada de aprovação | 2, 3 |
| 11 | [`11_RELATORIOS_ESPECIALISTAS.md`](11_RELATORIOS_ESPECIALISTAS.md) | 8 modelos de relatório, visualizador em três profundidades, proteção de conteúdo e fato relevante | 10 |
| 12 | [`12_PERSONA_ESPECIALISTA_RETROFIT.md`](12_PERSONA_ESPECIALISTA_RETROFIT.md) | **Retrofit** da 4ª persona (Especialista Elytron): identidade de staff, escopo por tenant, políticas, rules e roteamento | 10, 11 |
| 13 | [`13_MODULO_AUTORIA_RELATORIOS.md`](13_MODULO_AUTORIA_RELATORIOS.md) | Autoria e entrega: cadeia de custódia offline, revisão, verificação de redação e publicação | 12 |
| 14 | [`14_ESTRUTURA_DADOS_FIREBASE.md`](14_ESTRUTURA_DADOS_FIREBASE.md) | **Estrutura física**: schema, conversores, regras das 4 personas, índices, TTL, agregados, seed determinístico e presença em RTDB | 12, 13 |
| 15 | [`15_INTERFACE_WEB.md`](15_INTERFACE_WEB.md) | **Interface Web** — histórias em `../19_HISTORIAS_INTERFACE_WEB.md` (épico E-W, 24 HUs, 141 pontos) | 14 |

Os prompts 10 e 11 dependem da fundação (2 e 3), mas **não** dependem dos
painéis 4 a 9: dá para intercalá-los assim que o kit de visualização existir.
A taxonomia dos 44 serviços vive em [`../08_CATALOGO_SERVICOS.md`](../08_CATALOGO_SERVICOS.md)
e é fonte única de verdade para os dois.

**Nota sobre numeração:** o prompt #1 é o `docs/03_PROMPT_TELA_BOAS_VINDAS.md`
(o "03" ali é a posição dele na lista de documentos, não a ordem de execução).
Daqui em diante o número do arquivo **é** a ordem de execução.

## Por que esta ordem

O prompt 2 vem antes de qualquer tela porque hoje você não consegue nem abrir o
app sem um projeto Firebase válido. Com a fonte de dados alternável e o modo
`MOCK`, você desbloqueia o desenvolvimento visual inteiro sem depender de
console, faturamento ou seed — e o prompt 7 troca a fonte sem tocar em nenhuma
tela.

O prompt 3 vem antes dos painéis porque, se cada tela inventar seu próprio
gráfico, a demo fica visualmente incoerente e a correção depois custa caro.

## Checklist de saída do bloco

- [ ] `flutter run --dart-define=MOCK=true` abre direto no painel do CISO
- [ ] Índice de postura, tendência de 12 meses e risco por domínio renderizam
- [ ] Compliance por framework com drill-down funcionando
- [ ] Briefing executivo exportável
- [ ] Mesmo app com `--dart-define=DATA_SOURCE=firestore` lê do emulador
- [ ] `flutter analyze` limpo e `flutter test` verde
- [ ] Roteiro de demo de 5 minutos escrito
