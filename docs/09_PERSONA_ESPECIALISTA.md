# ERS — Persona 4: Especialista Elytron

Especificação de requisitos da quarta persona. Diferente das outras três, esta
**não é do cliente: é da Elytron.** Essa distinção não é semântica — ela muda o
modelo de autorização, o modelo de dados e a superfície de ataque do produto.

---

## 1. Por que esta persona quebra a premissa atual

As personas 1 a 3 pertencem a **um** tenant. Todo o `firestore.rules` se apoia
nisso: `inTenant(tenantId)` compara o `tenantId` do token com o caminho do
documento. Um especialista da Elytron atende **vários clientes** e precisa
escrever no tenant de cada um.

Três caminhos foram considerados:

| Caminho | Como funciona | Veredito |
|---|---|---|
| Claim `role: specialist` sem tenant | Regra libera qualquer tenant para staff | **Rejeitado.** Um bug vira vazamento entre clientes |
| Backend intermediário (Functions para tudo) | Cliente nunca fala com Firestore direto | Rejeitado por ora: reescreve o app inteiro e mata o tempo real |
| **Claim de staff + atribuição explícita por tenant** | O especialista só alcança tenants onde existe atribuição | **Adotado** |

### Modelo adotado

Custom claims do especialista:

```json
{
  "staff": true,
  "staffRole": "analyst" | "reviewer" | "deliveryLead" | "staffAdmin",
  "tenants": ["tenant-a", "tenant-c", "tenant-f"],
  "mfa": true
}
```

E, espelhando o que já existe para clientes, um documento de membro em cada
tenant atribuído: `/tenants/{tenantId}/members/{uid}` com `role: "specialist"`.

A regra passa a ser:

```
function isStaff() {
  return isSignedIn() && token().get('staff', false) == true;
}
function staffAssignedTo(tenantId) {
  return isStaff() && tenantId in token().get('tenants', []);
}
```

**Fail-closed por construção:** sem a atribuição no claim, o especialista não
alcança o tenant — mesmo que o documento de membro exista por engano.

**Limite conhecido:** custom claims do Firebase têm teto de 1000 bytes. Isso
comporta na ordem de 40 a 50 tenants por especialista. Acima disso, migrar para
um claim de "célula de atendimento" (`cell: "sul"`) com a lista de tenants
resolvida por documento. Documente o limite no código e falhe alto ao
ultrapassá-lo — nunca truncando a lista em silêncio.

---

## 2. Definição da persona

**Quem é.** Profissional da Elytron que executa o serviço contratado e produz a
entrega: pentester, analista forense, consultor de GRC, analista de CTI,
engenheiro de defesa, líder de conta.

**Onde está.** No cliente, em campo, em coleta forense às 2h da manhã, ou entre
reuniões. É a persona com o pior contexto de uso do produto inteiro: telefone
na mão, uma mão ocupada, rede instável.

**O que o app precisa fazer por ele.** Não redigir o relatório de 40 páginas —
isso não acontece no celular. O app precisa cobrir o que **só** acontece no
celular ou o que trava a entrega: capturar evidência com cadeia de custódia,
revisar e aprovar, publicar, e responder o cliente.

### Subpapéis (`staffRole`)

| Subpapel | Faz | Não faz |
|---|---|---|
| `analyst` | Executa o serviço, registra achados e evidências, redige seções, submete para revisão | Aprovar a própria entrega, publicar |
| `reviewer` | Revisa tecnicamente, pede ajuste, aprova | Publicar, alterar atribuição |
| `deliveryLead` | Publica ao cliente, define classificação, responde o cliente, gerencia SLA da conta | Aprovar tecnicamente sozinho quando também é autor |
| `staffAdmin` | Provisiona especialistas, atribui tenants, gerencia catálogo | Ler conteúdo de relatório fora das suas atribuições |

**Separação de funções é regra, não recomendação:** quem escreve não aprova, e
quem aprova não é quem escreveu. Se a equipe é pequena e a mesma pessoa precisa
fazer os dois, o sistema permite **com registro explícito de exceção**, exatamente
como a auto-aprovação do CISO na RFS. Auditoria não aceita buraco; aceita
exceção justificada.

---

## 3. Casos de uso

### CU-01 — Minha carga de trabalho
Lista das entregas atribuídas ao especialista, entre todos os clientes, com
prazo, status, e o que está bloqueado. Ordenada por risco de estourar SLA.
*Cliente nunca aparece agregado com outro cliente em uma mesma métrica.*

### CU-02 — Triagem de RFS
As solicitações abertas no prompt 10 chegam aqui. O especialista pode: pedir
esclarecimento de escopo, estimar esforço, anexar proposta, recusar com motivo.
Cada ação notifica o CISO do cliente.

### CU-03 — Coleta forense em campo *(nativo de celular)*
O caso de uso que justifica o app existir para esta persona. Registro de cadeia
de custódia: identificação do dispositivo, fotos do equipamento e do lacre,
hash da aquisição, nome e assinatura do custodiante, data-hora, geolocalização
opcional e consentida. **Offline-first**: funciona sem rede e sincroniza depois,
porque data center e sala de servidor não têm sinal.

Requisito legal: a coleta pode envolver dado pessoal. O formulário exige base
legal e finalidade antes de permitir a captura.

### CU-04 — Registro de achado em campo
Durante um pentest, registrar um achado com título, severidade preliminar,
ativo afetado e evidência (foto de tela, texto). Consolidação e redação final
acontecem depois, no ambiente de trabalho.

### CU-05 — Revisão e aprovação
O `reviewer` recebe o relatório em `inReview`, comenta por seção, pede ajuste
ou aprova. Comentário é obrigatório ao pedir ajuste.

### CU-06 — Publicação com verificação de redação
Antes de publicar, o `deliveryLead` vê a **prévia da visão de cada persona** do
cliente. O sistema alerta se conteúdo sensível vazou para a visão do board.
Publicar exige reautenticação.

### CU-07 — Perguntas do cliente
Fila das dúvidas que o cliente registrou sobre relatórios, com prazo de
resposta e histórico.

### CU-08 — Saúde da conta
Por cliente atribuído: entregas no prazo, achados críticos em aberto sem
tratativa, RFS paradas, retainer consumido.

---

## 4. Requisitos não funcionais e proteções

| # | Requisito | Por quê |
|---|---|---|
| RNF-01 | MFA obrigatório para todo `staff` | A conta alcança dados de vários clientes |
| RNF-02 | Sessão de staff expira em 12h; publicar e ler `secret` exigem reautenticação | Celular perdido não pode virar acesso permanente |
| RNF-03 | Toda consulta de staff exige `tenantId` explícito; não existe consulta "de todos os tenants" no cliente | Vazamento entre clientes é o risco existencial do produto |
| RNF-04 | Rascunho nunca é legível pelo cliente, em nenhuma classificação | Achado não confirmado gera pânico e perde confiança |
| RNF-05 | Relatório publicado carrega quem escreveu, quem aprovou e quando | Rastreabilidade e responsabilidade técnica |
| RNF-06 | Toda leitura e escrita de staff vai para `audit_logs` do tenant | Cliente pode auditar o que a Elytron fez nos dados dele |
| RNF-07 | Evidência de campo é criptografada em repouso no dispositivo e apagada após sincronizar | Dispositivo é o elo fraco |
| RNF-08 | O app de staff não é distribuído na loja pública | Reduz superfície e evita instalação por engano |
| RNF-09 | Falha ao resolver atribuição = negar acesso | Fail-closed, sempre |
| RNF-10 | Nenhuma tela de staff é alcançável por rota a partir de sessão de cliente | Defesa em profundidade contra bug de roteamento |

---

## 5. Decisão de distribuição

**Recomendação: mesmo repositório, mesmo backend, dois alvos de build
(flavors).**

- `client` — o que vai para App Store e Play Store.
- `staff` — distribuído por canal interno (TestFlight interno / Managed Play),
  com o módulo de especialista compilado dentro.

Motivo: um único código-base preserva o design system, os modelos de domínio e
o kit de gráficos, que já custaram caro. Mas o *build* do cliente não deve nem
conter as telas de staff — o que não está no binário não vaza por bug de rota.

Contraponto honesto: dois flavors custam disciplina de CI e um pouco de
complexidade de build. Se a equipe hoje não sustenta isso, aceite um único
build com o módulo atrás de um gate rígido de claim, **e registre isso como
dívida consciente com data para revisão**.

---

## 6. Critérios de aceite da persona

1. Um especialista atribuído a A e C **não** consegue ler nada de B — provado
   por teste de `firestore.rules`, não por inspeção de tela.
2. Nenhuma métrica jamais agrega dados de clientes distintos numa mesma
   visualização.
3. Autor não aprova a própria entrega, exceto com exceção registrada.
4. Publicar exige reautenticação e passa pela verificação de redação.
5. Cliente não enxerga rascunho em nenhuma hipótese.
6. Coleta forense funciona 100% offline e sincroniza sem perder cadeia de
   custódia.
7. Cada ação de staff aparece na trilha de auditoria do tenant afetado.
