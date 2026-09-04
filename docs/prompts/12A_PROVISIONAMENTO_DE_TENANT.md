# Prompt 12A — Provisionamento de tenant e do primeiro administrador

**Entrega:** a Cloud Function que cria um cliente (tenant) e o seu primeiro
administrador, mais o script one-shot que cria o **primeiro `staffAdmin` da
Elytron** — o problema de bootstrap que nenhum documento respondia.

**Por que este prompt existe.** O `docs/13_DECISOES_PENDENTES.md` registra
**D-21** ("quem cria tenant e o primeiro admin") como decisão pendente que
bloqueia o prompt 12. Uma auditoria dos prompts 11 a 14 mostrou que **nenhum
deles especifica esse artefato**: a seção F do prompt 12 só tem
`assignSpecialist` e a extensão de `gateSignUp`. Ou seja, D-21 não é uma
decisão esperando reunião — é uma especificação faltando. Este documento a
fecha.

> Executar **antes** do prompt 12. Sem ele, o prompt 12 entrega uma persona de
> staff que não tem como existir na primeira vez.

---

## 1. Decisões que você precisa confirmar antes de rodar

O prompt assume os defaults abaixo. Derrubar qualquer um deles muda o escopo.

### D-21.a · Quem cria um tenant?

| Alternativa | Consequência |
|---|---|
| **Cloud Function `callable`, restrita a `staffAdmin`** *(default)* | Toda criação passa por alguém da Elytron, com trilha de auditoria. Exige a função existir antes do primeiro cliente. |
| Autoatendimento (cliente cria a própria conta) | Rápido, mas incompatível com o produto: não há como validar contrato, escopo de serviço nem residência de dado. **Desaconselhado.** |
| Criação manual no console do Firebase | Zero código agora, mas sem auditoria, sem validação e sem repetibilidade. Vira dívida no primeiro cliente. |

### D-21.b · Como nasce o **primeiro** `staffAdmin`?

É o problema de bootstrap: a função exige `staffAdmin` para rodar, e não existe
`staffAdmin` ainda.

| Alternativa | Consequência |
|---|---|
| **Script one-shot versionado, com Admin SDK, que se recusa a rodar se já existir algum `staffAdmin`** *(default)* | Auditável (está no git), idempotente, e a janela de privilégio fecha sozinha depois do primeiro uso. |
| Lista de e-mails autorizados na config da Function | Simples, mas cria privilégio permanente por configuração — quem editar a config escala privilégio. |
| Claim definida à mão pelo console/CLI | Não deixa rastro no repositório; ninguém sabe depois quem concedeu e quando. |

### D-21.c · Como nasce o primeiro administrador **do cliente**?

| Alternativa | Consequência |
|---|---|
| **A criação do tenant já emite um convite; o cliente aceita via `claimInvite`** *(default)* | Reaproveita `claimInvite` e `assignRole`, que já existem em `functions/src/index.ts`. O cliente nunca escreve o próprio papel. |
| A Elytron cria a conta e entrega a senha | Senha compartilhada por canal inseguro. **Desaconselhado** num produto de segurança. |

### D-21.d · O documento de tenant guarda a receita do cliente?

**Sim, e isto não é detalhe.** A decisão **D-29** define fato relevante como
**25% da receita do cliente**, e o PR #18 registrou que o gatilho
`financialExposureThreshold` **não dispara hoje** porque não existe campo de
receita no modelo. É aqui que ele nasce.

Se a receita for informação sensível demais para viver no Firestore, a
alternativa é guardar apenas a **faixa** (`revenueBand`) em vez do valor — o
cálculo de 25% perde precisão mas o gatilho volta a funcionar.

---

## 2. O prompt

````text
# CONTEXTO FIXO
Projeto: Elytron Dash2Board, Flutter + Material 3 + Firebase (Auth + Firestore).
LEIA ANTES, como fonte de verdade:
  docs/prompts/12A_PROVISIONAMENTO_DE_TENANT.md  <- ESPECIFICAÇÃO desta tarefa
  docs/09_PERSONA_ESPECIALISTA.md
  docs/11_MODELO_FISICO_DADOS.md
  docs/13_DECISOES_PENDENTES.md   (D-21, D-29, D-13)
  firestore.rules
  functions/src/index.ts          (writeAudit, assignRole, claimInvite, gateSignUp)

# REGRAS DE CÓDIGO (obrigatórias)
1. TypeScript nas Functions, no estilo já usado em functions/src/index.ts.
2. Máximo de 250 linhas por arquivo. Divida por responsabilidade, não por tamanho.
3. Comentários e mensagens de erro em pt-BR; identificadores em inglês.
4. Nenhuma função nova pode ser chamada por cliente não autenticado.
5. Todo caminho de sucesso E de falha grava em audit_logs via writeAudit.
6. Arquivos completos, com todos os imports. Nunca escreva "...".

# REGRA DE OURO DESTE PROMPT
Escalonamento de privilégio aqui é falha crítica. Toda verificação de papel
vem de custom claims no token, NUNCA de documento do Firestore e NUNCA de
argumento vindo do cliente. Papel desconhecido ou ausente = negado.

# TAREFA

## A) Modelo do tenant — functions/src/tenants/tenant_model.ts
Defina o documento `tenants/{tenantId}`:
  - tenantId (slug), legalName, tradeName, taxId (CNPJ)
  - status: 'provisioning' | 'active' | 'suspended' | 'terminated'
  - contractedServiceKeys: string[]  (validar contra o catálogo de 44 serviços)
  - annualRevenue: number | null  E  revenueCurrency: 'BRL'
      -> base do limite de fato relevante de D-29 (25% da receita)
  - dataResidency: 'southamerica-east1'
  - retentionPolicy: { auditLogsYears: 5, custodyRecordYears: 10,
                       evidenceMonthsAfterContract: 12 }   (D-06, D-07, D-13)
  - createdAt, createdByUid, contractStartsAt, contractEndsAt | null
Nenhum campo é opcional por descuido: se não souber o valor, o tipo é
explicitamente nullable e o motivo vai num comentário.

## B) Criação de tenant — functions/src/tenants/create_tenant.ts
`createTenant`, onCall:
  - exige claim staffAdmin. Qualquer outro papel: permission-denied com a
    MESMA mensagem genérica, para não revelar quais papéis existem.
  - valida tenantId (slug: minúsculas, dígitos e hífen, 3..40, único).
  - valida contractedServiceKeys contra o catálogo; chave desconhecida aborta.
  - transação: cria tenants/{tenantId} com status 'provisioning', cria o
    convite do primeiro admin do cliente, grava audit_logs. Tudo ou nada.
  - idempotente por tenantId: chamar duas vezes NÃO cria dois tenants nem
    dois convites; a segunda chamada retorna o estado atual.
  - retorna { tenantId, inviteId, expiresAt } — nunca um token utilizável
    diretamente pelo chamador.

## C) Convite do primeiro admin do cliente — functions/src/tenants/invite.ts
  - convite com expiração (7 dias), uso único, vinculado a e-mail e tenantId.
  - aceitação REUTILIZA o claimInvite existente; se ele não suportar o papel
    inicial de admin de cliente, ESTENDA-O em vez de duplicar a lógica.
  - convite expirado ou já usado: mensagem única e genérica.
  - ao aceitar, o papel vem de assignRole (custom claims). O cliente nunca
    escreve o próprio papel.

## D) Bootstrap do primeiro staffAdmin — scripts/bootstrap-staff-admin.ts
Script Node com Admin SDK, executado à mão, FORA do app:
  - argumentos obrigatórios e explícitos: --project e --email.
  - RECUSA-SE a rodar se já existir qualquer usuário com claim staffAdmin.
    Essa é a trava que fecha a janela de privilégio depois do primeiro uso.
  - exige confirmação digitada do nome do projeto (evita rodar em produção
    por engano).
  - grava em audit_logs quem rodou, quando e em qual projeto.
  - imprime ao final o que foi concedido e como revogar.

## E) Security rules — firestore.rules
  - tenants/{tenantId}: leitura só para quem pertence ao tenant OU staff
    atribuído; escrita SEMPRE negada pelo client SDK (só Admin SDK escreve).
  - invites/{inviteId}: ilegível e inescrevível pelo client SDK, sem exceção.
  - audit_logs permanece append-only e ilegível pelo app.

## F) Testes
  - test/rules/tenants.spec.ts: caso positivo E negativo por regra —
    membro do tenant A não lê tenants/B; cliente não escreve tenant;
    ninguém lê invites pelo client SDK.
  - functions: teste de createTenant com papel errado (negado), com
    serviceKey inválida (abortado), chamada dupla (idempotente), e
    verificação de que audit_logs recebeu registro nos três casos.
  - teste do bootstrap: recusa quando já existe staffAdmin.

# CRITÉRIOS DE ACEITE
1. `flutter analyze` limpo e `flutter test` verde (nada no app muda, mas a
   regressão precisa ser provada).
2. Nenhuma das funções novas aceita papel vindo de argumento do cliente —
   verificável por grep: não existe `data.role` nem `request.data.role`.
3. createTenant chamado duas vezes com o mesmo tenantId produz exatamente um
   tenant e um convite.
4. O script de bootstrap se recusa a rodar duas vezes.
5. Toda função nova grava em audit_logs no sucesso E na negativa.
6. Nenhum arquivo novo passa de 250 linhas.

# COMO RESPONDER
1. Liste os arquivos que vai criar ou alterar, com uma linha de
   responsabilidade cada.
2. Escreva os arquivos completos, na ordem: modelo, funções, rules, testes.
3. Ao final, apresente a matriz "quem pode chamar o quê" e diga
   explicitamente qual privilégio o script de bootstrap concede e como
   revogá-lo.
4. Registre toda suposição que você tiver feito sem confirmação explícita.
````

---

## 3. O que este prompt fecha

- **D-21** deixa de ser bloqueio do prompt 12.
- **D-29** ganha o campo de receita que faltava — o gatilho de fato relevante
  do prompt 11 (`financialExposureThreshold`) passa a poder disparar.
- **D-06, D-07, D-13** ganham onde morar: a política de retenção passa a ser
  um campo por tenant, não uma constante global.

## 4. O que este prompt deliberadamente NÃO faz

Interface de administração. O provisionamento acontece por chamada de função
e script, sem tela. Tela de staff é escopo do prompt 12, e criar uma antes de
a persona existir seria inverter a ordem.
