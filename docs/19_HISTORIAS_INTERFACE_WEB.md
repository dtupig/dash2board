# Histórias de usuário — Épico E-W · Interface Web

**Feature:** Interface Web (todos os casos de uso do app)
**Persona:** todas (`operational`, `strategic`, `board`, `staff`, `pending`)
**Critério de aceitação do épico:** executar um **novo ciclo de auditoria**
(`./scripts/audit.sh` estendido com o bloco Web) terminando com **zero
`[FALHA]`**, com o mesmo rigor das 12 regras inegociáveis do `CLAUDE.md`.

**Autoria:** PO & Tech Lead · **Data:** 03/09/2026 · **Estado:** strawman para
refino em planning.

---

## 1. Premissas assumidas (confirmar ou derrubar em planning)

Estão marcadas porque **mudam o tamanho do épico**, não por serem detalhe.

| # | Premissa assumida | Se for derrubada |
|---|---|---|
| **P-1** | Web é o **mesmo código Flutter**, alvo `web`, não um front separado em React/Next | vira um projeto novo, ~4× o esforço, e duplica a camada de política |
| **P-2** | Objetivo é **paridade de caso de uso**, não paridade de pixel: a web pode ter layout de 3 colunas onde o app tem 1 | se exigirem espelho visual, mata o ganho de tela larga |
| **P-3** | Renderer **CanvasKit** (fidelidade de gráfico) com `--wasm` avaliado, não HTML renderer | HTML renderer degrada `ChartFrame` e reprova a banda de luminosidade |
| **P-4** | Hospedagem em **Firebase Hosting** no `elytron-d2b-dev` (Hosting cabe no plano Spark, D-12 não muda) | outra CDN traz seu próprio ciclo de CSP e deploy |
| **P-5** | Web v1 **sem push notification** e sem uso offline: notificação segue in-app | entra Service Worker + FCM Web, +1 sprint |
| **P-6** | Autenticação continua **FirebaseAuth com custom claims**; sessão de navegador expira em 12 h de inatividade | SSO/SAML corporativo é épico próprio |
| **P-7** | Personas `staff` e módulos de relatório existem **na web assim que existirem no app** — não antes (prompts 11, 12 e 13 pendentes) | se a web precisar sair antes, HU-W-18/19/20 saem do escopo e viram Fase 2 |
| **P-8** | Breakpoints Material 3: `compact <600`, `medium 600–839`, `expanded 840–1199`, `large ≥1200` | qualquer outra grade obriga a refazer o shell |

**Fato do repositório (não é premissa):** não existe pasta `web/` hoje — o alvo
web nunca foi habilitado. HU-W-01 é literalmente o primeiro commit possível.

## 2. Decisões novas que este épico abre

| # | Decisão | Proposta do PO (default se ninguém decidir) |
|---|---|---|
| D-33 | Domínio de publicação da web | `app.elytronsecurity.com` (dev: `d2b-dev.web.app`) |
| D-34 | A web é para cliente, para staff, ou dois builds (ecoa D-18) | **dois builds**, coerente com D-18 |
| D-35 | Exportação de briefing/relatório na web: PDF no cliente ou no servidor | cliente (`printing`), sem Blaze em dev |
| D-36 | Orçamento de bundle inicial | ≤ 3,5 MB comprimido no primeiro carregamento útil |

---

## 3. Mapa do épico

| Sprint | Foco | Histórias | Pontos |
|---|---|---|---|
| W1 | Fundação web | HU-W-01 a 05 | 26 |
| W2 | Jornada de entrada | HU-W-06 a 08 | 13 |
| W3 | Painéis das 3 personas | HU-W-09 a 14 | 34 |
| W4 | Serviços e RFS | HU-W-15 a 17 | 21 |
| W5 | Especialista e relatórios *(condicional a P-7)* | HU-W-18 a 20 | 26 |
| W6 | Transversais e auditoria | HU-W-21 a 24 | 21 |

Escala Fibonacci. Total **141 pontos**; sem o sprint W5, **115**.

---

## 4. Histórias

### Sprint W1 — Fundação

#### HU-W-01 · Habilitar o alvo web sem quebrar o mobile
> Como **time de desenvolvimento**, quero o alvo web habilitado no mesmo
> repositório, para publicar a interface web sem manter dois códigos.

- **Dado** o repositório atual sem pasta `web/`, **quando** rodar
  `flutter build web --release --dart-define=MOCK=true`, **então** o build
  conclui e `flutter analyze` segue em "No issues found!".
- **Dado** o app mobile, **quando** o alvo web for adicionado, **então**
  `flutter test` continua verde e nenhum arquivo de `presentation/` importa
  `dart:io`.
- **Dado** `index.html` gerado, **quando** for versionado, **então** contém
  título, `manifest`, favicon e cor de tema da marca — não o boilerplate.
- **Pontos:** 5 · **Dependências:** — · **Risco:** plugins mobile-only sem
  suporte web (`printing`, `share_plus`) exigem `kIsWeb` no ponto de uso.

#### HU-W-02 · Shell adaptativo por breakpoint
> Como **qualquer persona**, quero a navegação se adaptar ao tamanho da janela,
> para usar a mesma conta no celular e no monitor sem reaprender o produto.

- **Dado** largura `<600`, **quando** a tela abrir, **então** navegação inferior,
  idêntica ao app.
- **Dado** largura `600–1199`, **então** `NavigationRail` recolhido; **dado**
  `≥1200`, **então** rail expandido com rótulos e conteúdo em até 3 colunas,
  limitado a `maxWidth` de leitura confortável.
- **Dado** qualquer largura, **quando** a janela for redimensionada, **então**
  nenhum overflow e nenhum estado de tela é perdido.
- **Pontos:** 8 · **Dependências:** HU-W-01 · **Nota:** o shell vive em
  `lib/features/shell`, uma classe de layout testável — nunca `if (largura)`
  espalhado em widget de tela.

#### HU-W-03 · Roteamento por URL e link profundo
> Como **qualquer persona**, quero que cada tela tenha URL própria, para salvar
> nos favoritos, usar voltar/avançar e mandar link a um colega do mesmo tenant.

- **Dado** o painel do CISO, **quando** eu abrir `/estrategia`, **então** carrego
  direto ali; o mesmo para `/operacao`, `/board`, `/servicos`, `/relatorios`.
- **Dado** um link para tela sem permissão para meu papel, **quando** eu abrir,
  **então** vejo negativa explícita e volto ao meu painel — **nunca** conteúdo
  parcial nem tela em branco.
- **Dado** o botão voltar do navegador, **quando** eu navegar entre drill-downs,
  **então** o histórico respeita a ordem de navegação.
- **Pontos:** 5 · **Dependências:** HU-W-02.

#### HU-W-04 · Sessão persistente e saída segura no navegador
> Como **qualquer persona**, quero continuar logado ao reabrir a aba e sair de
> forma limpa, para não relogar o tempo todo nem deixar sessão aberta.

- **Dado** login feito, **quando** eu fechar e reabrir a aba em até 12 h,
  **então** continuo autenticado com o mesmo papel vindo de **custom claims**.
- **Dado** 12 h de inatividade, **quando** eu voltar, **então** sou levado ao
  login com aviso de expiração.
- **Dado** "sair", **quando** eu confirmar, **então** nenhum dado de tenant
  permanece em `localStorage`, `sessionStorage` ou IndexedDB.
- **Pontos:** 5 · **Dependências:** HU-W-01 · **Segurança:** papel desconhecido
  vira `pending` (fail-closed), igual ao mobile.

#### HU-W-05 · Entrega web endurecida
> Como **CISO responsável pelo produto**, quero que a própria web resista a uma
> avaliação de segurança, porque vendemos cibersegurança.

- **Dado** o site publicado, **quando** eu inspecionar as respostas, **então**
  há CSP sem `unsafe-eval` além do exigido pelo CanvasKit, `X-Frame-Options`/
  `frame-ancestors 'none'`, HSTS e `Referrer-Policy`.
- **Dado** o bundle publicado, **quando** eu procurar, **então** não há chave de
  serviço, endpoint interno nem `console.log` de dado de tenant.
- **Dado** `firebase.json`, **quando** o deploy rodar, **então** os cabeçalhos
  vêm do repositório, não do console.
- **Pontos:** 3 · **Dependências:** HU-W-01 · **Commit:** prefixo `sec(...)`.

### Sprint W2 — Jornada de entrada

#### HU-W-06 · Boas-vindas e login no navegador
> Como **usuário convidado**, quero entrar pela web com a mesma credencial do
> app, para não ter duas contas.

- **Dado** `/`, **quando** eu abrir, **então** vejo boas-vindas com o fundo
  aurora em 60 fps na `large` e sou roteado por persona após autenticar.
- **Dado** credencial inválida, **quando** eu errar, **então** a mensagem é
  **sempre a mesma**, sem permitir enumeração de usuário.
- **Dado** um gerenciador de senhas, **quando** eu usar, **então** os campos têm
  `autofill` correto e o formulário submete com Enter.
- **Pontos:** 5 · **Dependências:** HU-W-03, HU-W-04.

#### HU-W-07 · Acesso pendente na web
> Como **usuário sem papel atribuído**, quero uma tela honesta, para saber que
> falta liberação em vez de olhar um painel vazio.

- **Dado** conta sem claim, **quando** eu entrar, **então** vejo a tela de acesso
  pendente com "verificar liberação agora" e "sair".
- **Dado** liberação concedida, **quando** eu verificar, **então** sou roteado ao
  painel correto sem novo login.
- **Pontos:** 3 · **Dependências:** HU-W-06.

#### HU-W-08 · Onboarding de primeiro uso adaptado à tela larga
> Como **persona nova**, quero o onboarding aproveitar a tela grande, para
> entender o produto em menos passos.

- **Dado** primeiro acesso na `large`, **quando** o onboarding abrir, **então**
  mostra passo e ilustração lado a lado, com o mesmo conteúdo do mobile.
- **Dado** onboarding concluído em qualquer plataforma, **quando** eu entrar na
  outra, **então** ele **não** repete (mesma flag por usuário).
- **Pontos:** 5 · **Dependências:** HU-W-02.

### Sprint W3 — Painéis das três personas

#### HU-W-09 · Painel operacional na web
> Como **analista de SOC**, quero a fila em tela larga, para triar mais rápido
> que no celular.

- **Dado** `≥1200`, **quando** abrir `/operacao`, **então** vejo lista e detalhe
  do incidente lado a lado (master–detail), sem perder a posição da lista.
- **Dado** um incidente, **quando** eu triar (status, responsável, severidade,
  nota), **então** grava e a fila atualiza em tempo real — e nada além dessas
  ações é possível.
- **Dado** vulnerabilidades, **quando** eu ordenar por exploração ativa,
  **então** a ordem é a mesma regra de priorização do app.
- **Pontos:** 8 · **Dependências:** HU-W-02, HU-W-03.

#### HU-W-10 · Painel estratégico na web
> Como **CISO**, quero postura, tendência de 12 meses e risco por domínio em uma
> tela só, para abrir no telão da reunião.

- **Dado** `≥1200`, **quando** abrir `/estrategia`, **então** índice de postura,
  série de 12 meses e risco por domínio aparecem sem rolagem.
- **Dado** qualquer gráfico, **quando** renderizar, **então** sai de `ChartFrame`
  com cor só de `ChartTokens`, nunca dois eixos Y, no máximo 3 séries.
- **Dado** o ponteiro do mouse, **quando** eu passar sobre a série, **então** há
  *tooltip* com valor e data — comportamento novo, exclusivo da web.
- **Pontos:** 8 · **Dependências:** HU-W-02.

#### HU-W-11 · Compliance com drill-down e evidência
> Como **CISO**, quero abrir framework → controle → evidência sem perder o
> contexto, para responder auditoria com a tela aberta.

- **Dado** um framework, **quando** eu abrir um controle, **então** o drill-down
  usa painel lateral na `large` e tela cheia na `compact`, com URL própria.
- **Dado** uma evidência anexada, **quando** eu abrir, **então** ela é exibida ou
  baixada respeitando a classificação da seção.
- **Pontos:** 5 · **Dependências:** HU-W-10.

#### HU-W-12 · Insights, detalhe e pesquisa
> Como **CISO**, quero ler insights e responder pesquisa pelo navegador, para
> fazer isso entre reuniões, no computador.

- **Dado** a lista de insights, **quando** eu abrir um, **então** o texto respeita
  medida de leitura confortável (~72 caracteres), não a largura da janela.
- **Dado** uma pesquisa, **quando** eu responder e enviar, **então** grava uma vez
  só, mesmo com duplo clique, e o estado enviado persiste ao recarregar.
- **Pontos:** 5 · **Dependências:** HU-W-03.

#### HU-W-13 · Briefing executivo exportável no navegador
> Como **CISO**, quero gerar o briefing pela web, para levar o PDF à reunião de
> board sem passar pelo celular.

- **Dado** o briefing, **quando** eu clicar em exportar, **então** o PDF sai no
  navegador (D-35) com o mesmo conteúdo e marca do app.
- **Dado** `Ctrl/Cmd+P`, **quando** eu imprimir, **então** existe folha de estilo
  de impressão: sem navegação, gráficos legíveis em preto e branco.
- **Pontos:** 5 · **Dependências:** HU-W-10 · **Risco:** `printing` na web exige
  caminho separado por `kIsWeb`.

#### HU-W-14 · Painel do board e aceite de risco
> Como **membro do board**, quero exposição financeira e decisões pendentes em
> linguagem sem sigla, para decidir em cinco minutos.

- **Dado** `/board`, **quando** eu abrir, **então** vejo ALE em moeda e como
  percentual da receita, impacto por unidade de negócio com dono nomeado e as
  decisões pendentes.
- **Dado** um aceite de risco, **quando** eu registrar (`acceptance`,
  `boardNote`), **então** grava com trilha de auditoria — a única escrita
  executiva do produto.
- **Dado** a persona `board`, **quando** qualquer conteúdo carregar, **então**
  seções `exploitProof`, `personalData` e `chainOfCustody` **nunca** aparecem,
  nem em elemento oculto no DOM.
- **Pontos:** 8 · **Dependências:** HU-W-02 · **Commit:** `sec(...)`.

### Sprint W4 — Serviços e RFS

#### HU-W-15 · Catálogo dos 44 serviços em tela larga
> Como **cliente (operational/strategic)**, quero navegar o catálogo com filtro e
> busca, para achar o serviço sem rolar 44 cartões.

- **Dado** `≥1200`, **quando** abrir `/servicos`, **então** grade de 3 colunas com
  filtro por categoria persistido na URL.
- **Dado** a busca, **quando** eu digitar, **então** filtra por nome e sinônimo,
  com estado vazio explicando o que não achou.
- **Pontos:** 5 · **Dependências:** HU-W-02.

#### HU-W-16 · Wizard de RFS em 5 passos
> Como **cliente**, quero abrir uma solicitação pela web, para anexar arquivo do
> computador e escrever com teclado de verdade.

- **Dado** o wizard, **quando** eu avançar, **então** os 5 passos aparecem como
  trilha lateral na `large`, com validação por passo e rascunho preservado ao
  recarregar a página.
- **Dado** um anexo, **quando** eu arrastar para a janela, **então** aceita, com
  limite de tipo e tamanho explícito.
- **Dado** o envio, **quando** eu concluir, **então** o SLA aplicado é o de D-30
  (crise 2 h · urgente 1 dia · planejado 5 dias) e o status inicial respeita a
  alçada da `RequestPolicy`.
- **Pontos:** 8 · **Dependências:** HU-W-15.

#### HU-W-17 · Caixa de aprovação com alçada
> Como **CISO**, quero aprovar ou recusar solicitações pela web, para despachar a
> fila em lote no computador.

- **Dado** a caixa, **quando** eu abrir, **então** vejo o que **eu** posso
  aprovar segundo a alçada técnico→CISO→board, e nada além.
- **Dado** uma aprovação, **quando** eu confirmar, **então** só `status`,
  `approval` e campos permitidos mudam, e a decisão vai para `audit_logs`.
- **Pontos:** 8 · **Dependências:** HU-W-16 · **Commit:** `sec(...)`.

### Sprint W5 — Especialista e relatórios *(condicional a P-7)*

#### HU-W-18 · Visualizador de relatório em três profundidades
> Como **cliente**, quero ler o relatório na web em resumo, gerencial ou técnico,
> para escolher o nível conforme quem está na sala.

- **Dado** um relatório publicado, **quando** eu alternar profundidade, **então**
  o conteúdo troca sem recarregar e a URL registra a profundidade.
- **Dado** rascunho, **quando** eu tentar acessar, **então** é negado — cliente
  nunca lê rascunho.
- **Dado** proteção de conteúdo, **quando** eu visualizar, **então** valem as
  mesmas restrições do app (sem cópia livre de seção protegida).
- **Pontos:** 8 · **Dependências:** prompt 11 concluído.

#### HU-W-19 · Console do especialista Elytron
> Como **especialista Elytron (`staff`)**, quero trabalhar na web, porque meu
> trabalho de fato acontece no computador.

- **Dado** um especialista, **quando** eu entrar, **então** vejo apenas os tenants
  aos quais **fui atribuído**, com o tenant em foco sempre visível na tela.
- **Dado** troca de tenant, **quando** eu trocar, **então** todo estado do tenant
  anterior é descartado — nenhuma visualização agrega dois clientes.
- **Pontos:** 8 · **Dependências:** prompt 12 (bloqueado por D-21) ·
  **Commit:** `sec(...)`.

#### HU-W-20 · Autoria e publicação de relatório
> Como **especialista**, quero redigir, revisar e publicar pela web, para
> abandonar o ciclo de Word e e-mail.

- **Dado** uma seção em redação, **quando** eu salvar, **então** grava com
  `custody_records` em modo append-only e ilegível pelo app.
- **Dado** a publicação, **quando** eu publicar, **então** passa pela verificação
  de redação e só então o cliente enxerga.
- **Pontos:** 13 · **Dependências:** HU-W-19, prompt 13.

### Sprint W6 — Transversais e auditoria

#### HU-W-21 · Acessibilidade e uso por teclado
> Como **qualquer persona**, quero operar a web pelo teclado e com leitor de
> tela, para que o produto sirva a todo mundo do time e passe em RFP pública.

- **Dado** a tecla Tab, **quando** eu percorrer a tela, **então** a ordem de foco
  é lógica, o foco é visível e não há armadilha em diálogo.
- **Dado** um leitor de tela, **quando** ele ler, **então** cada gráfico expõe
  resumo textual e cada botão tem rótulo semântico em pt-BR.
- **Dado** a paleta, **quando** medida, **então** contraste ≥ 4,5:1 para texto e
  ≥ 3:1 para elemento gráfico, em tema claro e escuro.
- **Pontos:** 8 · **Dependências:** sprints W3 e W4.

#### HU-W-22 · Gráfico que respira em tela larga
> Como **CISO**, quero o gráfico usar a tela grande sem virar outra linguagem
> visual, para a demo não parecer dois produtos.

- **Dado** `ChartFrame` em `≥1200`, **quando** renderizar, **então** aumenta
  densidade de eixo e rótulo, mantendo tokens, ordem fixa de série e cor de
  severidade reservada.
- **Dado** o mouse, **quando** eu passar ou clicar, **então** há realce e
  drill-down; sem mouse (toque), o comportamento do app é preservado.
- **Pontos:** 5 · **Dependências:** HU-W-10.

#### HU-W-23 · Isolamento de tenant também na web
> Como **responsável pelo produto**, quero prova de que a web não vaza dado entre
> clientes, porque isso é falha crítica.

- **Dado** teste dedicado, **quando** rodar, **então** cobre troca de tenant,
  link profundo para tenant alheio e recarga de página com claim de outro
  tenant — todos negados.
- **Dado** qualquer requisição da web, **quando** observada, **então** carrega
  `tenantId` explícito; não existe consulta "de todos os tenants" no cliente.
- **Pontos:** 5 · **Dependências:** HU-W-03, HU-W-04 · **Commit:** `sec(...)`.

#### HU-W-24 · Novo ciclo de auditoria com o bloco Web *(critério de aceitação do épico)*
> Como **Tech Lead**, quero um ciclo de auditoria que enxergue a web, para que
> "pronto" continue significando a mesma coisa em duas plataformas.

- **Dado** `./scripts/audit.sh`, **quando** eu rodar, **então** existe um bloco
  **"10. WEB"** que verifica: build web release conclui; orçamento de bundle de
  D-36 respeitado; `flutter test --platform chrome` verde; nenhum import de
  `dart:io` em `presentation/`; cabeçalhos de segurança presentes em
  `firebase.json`; nenhum segredo no bundle.
- **Dado** as 12 regras do `CLAUDE.md`, **quando** o bloco de regras rodar,
  **então** os arquivos novos da web são varridos junto — zero violação.
- **Dado** o CI, **quando** o PR abrir, **então** roda um 4º job "Build e
  auditoria web", obrigatório para o merge em `main`.
- **Dado** o ciclo completo, **quando** terminar, **então** `audit-report.txt`
  fecha com **zero `[FALHA]`** e vira o anexo de evidência do épico.
- **Pontos:** 3 · **Dependências:** todas as demais.

---

## 5. Definição de pronto do épico

1. `flutter analyze` em "No issues found!" e `flutter test` verde.
2. `flutter build web --release` conclui dentro do orçamento de D-36.
3. Todo caso de uso das seções 4.W2 a 4.W4 acessível por URL própria na web.
4. Nenhuma regra do `CLAUDE.md` violada nos arquivos novos (máx. 250 linhas,
   `withValues`, sem `MaterialState*`, domínio em Dart puro, `presentation/` sem
   Firebase).
5. Testes de isolamento entre tenants passando também no alvo web.
6. **`./scripts/audit.sh` com o bloco Web executado, zero `[FALHA]`**, e
   `audit-report.txt` anexado ao PR de fechamento.
7. `docs/17_PONTO_DE_RETOMADA.md` atualizado com o estado pós-web.

## 6. Fora de escopo (Fase 2, declarado)

Push notification e uso offline (P-5); SSO/SAML corporativo (P-6); editor de
dashboard pelo cliente; administração de tenant pela web; internacionalização
além de pt-BR; app de desktop empacotado.
