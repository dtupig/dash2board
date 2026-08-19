# Personas — Elytron Dash2Board

Três públicos, três níveis de abstração, **um mesmo dado de base**. A diferença
entre os painéis não é cosmética: é o grão da informação e a pergunta que ela
responde.

| | Persona 1 | Persona 2 | Persona 3 |
|---|---|---|---|
| **Claim** | `operational` | `strategic` | `board` |
| **Quem** | SOC, resposta a incidentes, gestão de vulnerabilidades | CISO, segurança estratégica, GRC | C-Level das unidades de negócio |
| **Pergunta** | "O que eu faço agora?" | "Estamos melhorando? Onde está o risco?" | "Isso custa quanto ao negócio?" |
| **Horizonte** | minutos a horas | trimestre a ano | ano a plano estratégico |
| **Grão** | evento e ativo | domínio de controle | unidade de negócio |
| **Métrica típica** | MTTA, MTTR, fila por severidade | índice de postura, cobertura de controle, tendência 12m | ALE, risco residual, decisões pendentes |
| **Tolerância a jargão** | alta | média | zero |
| **Frequência de uso** | várias vezes ao dia | semanal | mensal / reunião de board |
| **Acento visual** | ciano `#21C7E8` | verde `#00E08A` | violeta `#A98BFF` |
| **Rota** | `/operacao` | `/estrategia` | `/board` |

## Persona 1 — Time técnico operacional e tático

**Contexto.** Está no meio do turno, frequentemente no celular a caminho de
algum lugar, e usa o app como extensão do console. Não quer resumo: quer a fila.

**Entregas do painel**
- Incidentes abertos com severidade, dono e tempo em aberto, em tempo real.
- Vulnerabilidades priorizadas por exploração ativa (EPSS/KEV) cruzada com
  criticidade e exposição do ativo.
- Fila do turno atribuída ao analista logado, com prazo e origem.

**Ações permitidas no app:** triar incidente (status, responsável, severidade,
nota) e atualizar remediação de vulnerabilidade. Nada além disso.

## Persona 2 — Segurança estratégica e CISO

**Contexto.** É o **público primário**. Precisa defender orçamento, responder a
comitê e auditoria, e enxergar tendência — não fotografia. Usa o app antes de
reuniões.

**Entregas do painel**
- Índice de postura consolidado, série de 12 meses, por domínio de controle,
  com comparação contra a mediana do setor.
- Compliance por framework (ISO 27001, NIST CSF, LGPD, PCI DSS) com lacunas e
  evidência anexada por controle.
- Insights, tendências e pesquisas curadas pela Elytron, incluindo benchmark
  com pares do mesmo segmento.

**Ações permitidas:** responder pesquisas; visualizar o time do tenant.

## Persona 3 — Board e C-Level das unidades de negócio

**Contexto.** Dá ao assunto poucos minutos por mês. Qualquer sigla não
explicada é ruído. Quer saber o tamanho da exposição e o que precisa decidir.

**Entregas do painel**
- Exposição financeira estimada (perda anual esperada), em moeda e como
  percentual da receita.
- Impacto por unidade de negócio, com dono executivo nomeado.
- Decisões pendentes do board: investimentos, aceites de risco e exceções, com
  prazo e consequência.

**Ações permitidas:** registrar aceite de risco (`acceptance`, `boardNote`) —
que é, deliberadamente, a única escrita executiva do produto e fica registrada
na trilha de auditoria.

## Estado extra: `pending`

Conta autenticada sem papel atribuído. É um estado esperado em B2B: o usuário
existe no FirebaseAuth antes do administrador do cliente definir a persona.
Ele vê uma tela dedicada com "verificar liberação agora" e "sair" — **nunca**
um dashboard vazio.

## Persona 4 — Especialista Elytron (`staff`)

A quarta persona **não pertence ao cliente: pertence à Elytron.** É quem executa
o serviço e produz a entrega — pentester, perito forense, consultor de GRC,
analista de CTI, líder de conta.

Ela é modelada em uma dimensão separada (`PrincipalKind.staff` + `StaffRole`),
e **não** como um valor de `UserRole`, porque opera **entre tenants**: alcança
apenas os clientes aos quais foi explicitamente atribuída, nunca "todos".

Especificação completa, modelo de autorização e proteções:
[`09_PERSONA_ESPECIALISTA.md`](09_PERSONA_ESPECIALISTA.md).

Regra que atravessa o produto: **nenhuma visualização jamais agrega dados de
clientes distintos**, e vazamento entre tenants é tratado como falha crítica com
teste automatizado dedicado.

## Como isso aparece na tela de boas-vindas

A tela mostra as três personas como **prova de escopo**, para o executivo
reconhecer o próprio lugar no produto. Não é seletor de permissão: o papel real
chega nos custom claims depois do login e o roteamento é feito pelo go_router.
