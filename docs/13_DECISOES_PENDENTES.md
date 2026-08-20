# Registro de decisões — Elytron Dash2Board

Cada item tem uma recomendação. Confirmar é uma palavra; discordar exige
substituir a recomendação por outra e anotar o porquê.

Legenda: **[BLOQUEIA]** trava um prompt do roteiro · **[PRAZO]** tem data
externa · **[PODE ESPERAR]** não impede a próxima onda.

> Os itens jurídicos abaixo são análise técnica de produto, **não parecer
> jurídico**. Valide com o jurídico antes de virar cláusula contratual.

---

## Decidido

| # | Decisão | Valor |
|---|---|---|
| D-01 | Região do Firestore | `southamerica-east1` (São Paulo) — permanente. Banco de dev recriado nesta região em 19/08/2026 (estava em `eur3`) |
| D-02 | Motor do núcleo | Cloud Firestore; RTDB só presença e efêmeros |
| D-03 | Alçada de RFS | Técnico abre · CISO aprova · Board informado por fato relevante |
| D-04 | Modelo da 4ª persona | Dimensão separada (`PrincipalKind` + `StaffRole` + tenants atribuídos) |

## Confirmado em 19/08/2026

Decisões tomadas em sessão de arquitetura para destravar os prompts 10, 13 e
14, e as pré-condições dos prompts 11 e 12 (a implementação técnica de cada
prompt ainda segue seu próprio portão em `docs/16_PLANO_DE_RETOMADA.md`).

| # | Decisão | Valor confirmado |
|---|---|---|
| D-30 | SLA de resposta a RFS | Crise 2h · urgente 1 dia útil · planejado 5 dias úteis |
| D-29 | Limite de fato relevante | 25% da receita do cliente, por tenant, sem teto adicional |
| D-18 | Um build ou dois flavors | Dois flavors: `client` (lojas públicas) e `staff` (distribuição interna) |
| D-05 | App guarda evidência ou só o registro de custódia | Só o registro de custódia + ponteiro para o cofre forense |
| D-06 | Prazos de retenção da custódia | `CustodyRecord` 10 anos · evidência no cofre 12 meses pós-contrato |
| D-07 | Como aplicar o prazo de custódia | `retentionUntil` + `legalHold` por registro — nunca TTL global |
| D-12 | Plano de faturamento | **Spark** em dev/staging (Functions via emulador, sem deploy ao vivo) · **Blaze** em produção, com alerta de orçamento (modelo: R$50, gatilhos 50%/90%) |
| D-13 | Retenção de `audit_logs` | 5 anos |
| D-27 | Validar os 8 modelos de relatório com as disciplinas | **Escopo definido, validação ainda pendente de agendar:** reunião de 1h com pentest, forense, GRC, AppSec lead e SOC/Threat Intel lead |


---

## A. Cadeia de custódia — 7 decisões

### D-05 **[BLOQUEIA prompt 13]** O app guarda a evidência ou só o registro?

**Recomendação: só o registro de custódia — metadado, hashes, fotos do
processo — mais um ponteiro para o cofre forense.**

A Elytron já vende `forensics_hosting_hash`. Guardar imagem forense dentro do
Firebase duplica um cofre que já existe, explode custo de Storage (imagem de
endpoint tem dezenas de GB), e transforma o app num repositório de prova
judicial — status que atrai obrigação de preservação e ordem judicial.

Consequência prática: o `CustodyRecord` prova **que** a coleta aconteceu, com
que hash e sob que custódia. O conteúdo mora no cofre.

### D-06 **[BLOQUEIA prompt 14]** Retenção: registro e evidência têm prazos diferentes?

**Recomendação: sim, e separados.**

| Objeto | Prazo sugerido | Racional |
|---|---|---|
| `CustodyRecord` (metadado + hash) | 10 anos | É a prova de integridade do processo; é pequeno e barato |
| Evidência (cofre) | prazo contratual, padrão 12 meses após encerramento | Minimização da LGPD |

Manter o registro depois de destruir a evidência é o melhor dos dois mundos:
você continua conseguindo provar o que foi coletado e que estava íntegro, sem
guardar o dado pessoal além da finalidade.

### D-07 **[BLOQUEIA prompt 14]** Como o prazo é aplicado?

**Recomendação: `retentionUntil` + `legalHold` por registro. Nunca TTL global.**

`legalHold = true` suspende qualquer expurgo, independentemente da data. Uma
coleta que virou processo judicial e é apagada por uma política automática é
destruição de prova — exposição muito pior que custo de armazenamento.

### D-08 Quem autoriza o expurgo, e com quantas aprovações?

**Recomendação: duplo controle.** `staffAdmin` propõe, `deliveryLead` da conta
confirma, e o evento vai para a auditoria dos dois lados. Nunca por interface
comum, nunca por uma pessoa só.

### D-09 **[PRAZO]** Base legal padrão e pedido de titular

Coleta de celular corporativo de um funcionário toca dado pessoal dele.
Precisa estar definido: qual a base legal padrão (interesse legítimo? obrigação
legal? execução de contrato?), e o que acontece quando o titular exerce direito
de acesso ou eliminação no meio de uma investigação.

**Recomendação:** base legal escolhida **por coleta**, não global — o app já
exige o campo. E um fluxo de "pedido de titular" registrado, com a resposta
documentada. Isso é conversa com o jurídico, não com o time de produto.

### D-10 A assinatura desenhada na tela tem validade?

**Não sei, e não vou fingir que sei.** Assinatura em tela é boa prática de
processo, mas não equivale a assinatura com validade jurídica plena no Brasil
sem ICP-Brasil ou aceitação expressa das partes.

**Recomendação:** tratar a assinatura em tela como registro operacional, e
manter em paralelo o termo físico ou assinatura digital qualificada quando a
coleta puder virar processo. Confirmar com o jurídico antes de prometer ao
cliente.

### D-11 Geolocalização na coleta

**Recomendação: opcional e com consentimento explícito**, como está
especificado. Útil para contestar alegação de que a coleta ocorreu em outro
lugar; invasivo se ligado por padrão.

---

## B. Dados e infraestrutura

| # | Decisão | Recomendação | Status |
|---|---|---|---|
| D-12 | Plano de faturamento | **Spark** em dev/staging · **Blaze** só em produção, com alerta de orçamento | **[BLOQUEIA]** Functions, Storage e exportação **em produção** (dev/staging seguem via emulador, sem custo) |
| D-13 | Retenção de `audit_logs` | 5 anos | **[BLOQUEIA prompt 14]** |
| D-14 | Janela de PITR | 7 dias + exportação diária retida 14 dias | Confirmar |
| D-15 | Residência de dados | Já resolvida por D-01; virar cláusula contratual | [PODE ESPERAR] |
| D-16 | App Check | Monitorar 2 semanas, depois bloquear | [PRAZO] antes do 1º cliente real |
| D-17 | Teste de restauração | Trimestral, em projeto descartável | [PODE ESPERAR] |

---

## C. Produto e distribuição

| # | Decisão | Recomendação | Status |
|---|---|---|---|
| D-18 | Um build ou dois flavors (cliente/staff) | **Dois flavors.** O binário do cliente não deveria conter as telas de staff | **[BLOQUEIA prompt 12]** |
| D-19 | Monetização do app | Incluso no contrato na v1; módulo pago quando houver DPO e benchmark | [PODE ESPERAR] |
| D-20 | Idioma inglês | Depois da primeira demo aprovada | [PODE ESPERAR] |
| D-21 | Quem cria tenant e primeiro admin | Cloud Function operada por `staffAdmin`, nunca autoatendimento | **[BLOQUEIA prompt 12]** |

---

## D. Segurança

| # | Decisão | Recomendação | Status |
|---|---|---|---|
| D-22 | MFA para clientes | Obrigatório para `strategic` e `board`; opcional para `operational` na v1 | Confirmar |
| D-23 | Duração de sessão do cliente | 30 dias com reautenticação para relatório `secret` | Confirmar |
| D-24 | Captura de tela | Marca d'água **atribui**, não impede. Não prometer bloqueio no iOS | Confirmar postura comercial |
| D-25 | Pentest do próprio app | Equipe independente da que construiu, antes do 1º cliente | **[PRAZO]** |
| D-26 | Teste de isolamento entre tenants no CI | Falha o build, não é revisão manual | **[BLOQUEIA prompt 12]** |

---

## E. Conteúdo e negócio

| # | Decisão | Recomendação | Status |
|---|---|---|---|
| D-27 | Validar os 8 modelos de relatório | **Cada disciplina revisa o seu** antes do prompt 11 | **[BLOQUEIA prompt 11]** |
| D-28 | Quem escreve os 44 `shortPitch` | Rascunho pelo agente, revisão comercial obrigatória | [PODE ESPERAR] |
| D-29 | Limite de fato relevante | % da receita do cliente, não valor fixo — por tenant | **[BLOQUEIA prompt 11]** |
| D-30 | SLA de resposta a RFS | Definir por urgência: crise 2h · urgente 1 dia · planejado 5 dias | **[BLOQUEIA prompt 10]** |
| D-31 | Consentimento para benchmark setorial | Cláusula no contrato-padrão, com k-anonimato mínimo | [PODE ESPERAR] |

---

## Ordem sugerida

1. **Hoje:** D-05, D-06, D-07, D-12, D-13, D-18, D-29, D-30 — destravam os
   prompts 10 a 14.
2. **Esta semana:** D-27 com as disciplinas; D-21 e D-26 com engenharia.
3. **Com o jurídico:** D-09, D-10, D-15, D-31.
4. **Antes do primeiro cliente real:** D-16, D-22, D-23, D-24, D-25.
