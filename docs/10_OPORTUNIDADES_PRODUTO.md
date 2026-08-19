# Oportunidades de produto — personas, casos de uso e requisitos de mercado

Documento de exploração, não de compromisso. Serve para decidir o que **não**
fazer agora com clareza sobre o que se está deixando na mesa.

---

## 1. Personas ainda não modeladas

Ordenadas por razão entre valor de negócio e esforço.

### 1.1 DPO / Jurídico *(alto valor, esforço médio)*
Hoje ninguém no app responde à pergunta que mais aperta depois de um incidente:
**"somos obrigados a notificar, para quem, e em quanto tempo?"**

O DPO é comprador real em empresa regulada e não tem lugar no produto. Ele
precisa de: incidentes com dado pessoal envolvido, contador de prazo
regulatório, rascunho de comunicação a titulares e à autoridade, e o registro
de que a decisão de notificar (ou não) foi tomada, por quem e com base em quê.

Esse registro é o artefato que protege a empresa numa fiscalização — e é
exatamente o que hoje vive em e-mail e WhatsApp.

### 1.2 Auditor externo / regulador *(alto valor, esforço baixo)*
Acesso **temporário, escopado e somente leitura**, com validade automática. O
auditor entra, vê os controles e as evidências do escopo dele, e o acesso morre
sozinho na data. Isso substitui a pasta compartilhada com dado sensível que
sobrevive anos depois da auditoria.

Esforço baixo porque o modelo de classificação e a trilha de auditoria já
existem. É quase só uma variação de claim com expiração.

### 1.3 Fornecedor avaliado *(valor alto, muda o modelo de negócio)*
Hoje "Gestão de Terceiros" é um serviço. Com uma persona de fornecedor — que
responde questionário, anexa evidência e acompanha o próprio plano de ação — o
serviço vira **plataforma**, e o custo marginal de atender mais fornecedores
despenca.

Efeito de rede real: um fornecedor avaliado por três clientes Elytron responde
uma vez. Isso é defensável competitivamente.

### 1.4 Parceiro / MSP *(valor alto, esforço alto)*
Revenda que atende vários clientes finais. Exige white-label, hierarquia de
tenant e modelo de comissionamento. Vale quando a estratégia de canal estiver
definida — não antes.

### 1.5 Corretora de seguro cyber *(valor especulativo, esforço baixo)*
Exportar a postura num formato que a seguradora aceite pode virar desconto de
prêmio para o cliente. Se a Elytron conseguir uma parceria com uma seguradora,
isso deixa de ser recurso e vira argumento de venda: *o app se paga no prêmio*.

---

## 2. Casos de uso que valem mais que a média

### 2.1 Contador de obrigação regulatória
Um cronômetro que começa quando o incidente é classificado e mostra o prazo de
cada regime aplicável ao cliente (LGPD/ANPD, DORA para o setor financeiro
europeu, SEC para emissoras nos EUA, regulação setorial local).

> **Validar antes de implementar.** Os prazos mudam e variam por setor e
> jurisdição. Trate a tabela de prazos como configuração revisada pelo
> jurídico, nunca como constante no código. Errar um prazo aqui é pior que não
> ter o recurso.

Por que vale: é o único recurso da lista que alguém abre às 3h da manhã.

### 2.2 Sala de evidências para auditoria
Empacotar, num período e escopo, todos os relatórios, evidências e registros de
decisão, com hash e índice. Um clique substitui duas semanas de trabalho de um
analista de GRC antes de cada auditoria.

### 2.3 Reteste a partir do achado
Botão "pedir reteste" dentro do achado, que abre uma RFS pré-preenchida ligada
ao relatório de origem. Conecta os prompts 10 e 11 e transforma leitura em
receita — sem parecer venda, porque é exatamente o que o cliente já queria.

### 2.4 Benchmark setorial anônimo
A base agregada de clientes Elytron é o ativo que **nenhum concorrente copia**.
"Você está no terceiro quartil do seu setor em segurança de aplicação" é uma
frase que muda orçamento.

Requer rigor: k-anonimato mínimo, sem revelar nada de cliente individual, e
consentimento contratual explícito. Feito errado, é vazamento; feito certo, é
o fosso competitivo do produto.

### 2.5 Trilha de decisão do board como evidência de governança
O board já aceita risco no app (prompt 9). Empacotar essas decisões num
relatório de governança serve à discussão de responsabilidade de
administradores — assunto que virou pauta de conselho.

### 2.6 Integrações que evitam retrabalho
Achado → Jira/ServiceNow. Fato relevante → Teams/Slack/e-mail. Incidente →
SIEM. Sem isso, o app vira mais uma tela que alguém precisa lembrar de abrir.

---

## 3. Requisitos de negócio ainda ausentes

| Requisito | Por que importa | Urgência |
|---|---|---|
| **Saldo de retainer** | "Quanto do meu DFIR sobrou?" é a pergunta nº 1 de quem compra retainer, e hoje o app não responde | Alta |
| **Contrato e SLA visíveis** | Cliente sem visibilidade de escopo abre demanda fora do contrato e gera atrito comercial | Alta |
| **Retenção e expurgo de evidência** | Guardar forense além do necessário é passivo jurídico, não zelo | Alta |
| **Idioma inglês** | Cliente com matriz fora do Brasil precisa mostrar o painel lá dentro | Média |
| **Residência de dados** | Setor financeiro e público podem exigir dado no Brasil | Média |
| **Métrica de uso por conta** | Sem saber quem abre o app, não dá para provar valor na renovação | Média |
| **Modelo de cobrança do app** | Incluso no contrato, módulo pago ou gancho de upsell — decide o roadmap | Estratégica |

---

## 4. Riscos que crescem com o produto

**O app concentra a postura de segurança de N clientes.** Isso o torna um alvo
de valor desproporcional ao seu tamanho. A ironia de a plataforma de uma empresa
de segurança ser o vetor de vazamento não é hipotética — já aconteceu no
mercado.

Consequências práticas:

1. **Threat model próprio do Dash2Board**, revisado a cada trimestre.
2. **Pentest do próprio app por equipe independente** — não pela equipe que o
   construiu. Se a Elytron não faz isso no próprio produto, perde autoridade
   para exigir dos clientes.
3. **Vazamento entre tenants é evento de extinção.** Merece teste automatizado
   em CI que falha o build, não revisão manual.
4. **Captura de tela**: marca d'água atribui, não impede. Não prometa ao
   cliente o que a plataforma não entrega.
5. **Conta de staff comprometida** alcança vários clientes. MFA obrigatório e
   sessão curta são o mínimo; detecção de anomalia de acesso é o próximo passo.

---

## 5. Sequência sugerida

| Onda | O quê | Por quê agora |
|---|---|---|
| **1** | Persona especialista + autoria (prompts 12 e 13) | Sem ela o conteúdo do app não nasce |
| **2** | Saldo de retainer e contrato visível | Menor esforço com maior impacto na percepção de valor |
| **3** | Reteste a partir do achado | Liga leitura a receita com o que já existe |
| **4** | Persona DPO + contador regulatório | Abre um comprador novo dentro do mesmo cliente |
| **5** | Auditor externo temporário | Esforço baixo sobre a base já construída |
| **6** | Benchmark setorial | Depende de massa de dados; é o fosso de longo prazo |
| **7** | Fornecedor avaliado | Muda o modelo de negócio; exige decisão estratégica |
