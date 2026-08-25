# Validação D-27 — modelos de relatório vs. templates reais de cliente

Documento de apoio à decisão **D-27** (`docs/13_DECISOES_PENDENTES.md`). Na
reunião de 21/08/2026, as disciplinas (pentest, forense, GRC, AppSec,
SOC/Threat Intel) não chancelaram os 8 modelos de relatório especificados no
prompt 11 em abstrato: entregaram os templates reais em uso e pediram
validação prática antes de fechar.

Este documento é essa validação prática: os 6 relatórios reais em
`docs/Client_reports/` (fora do git, dado confidencial de terceiro — ver
`.gitignore`) foram lidos e comparados campo a campo contra os 8 modelos de
`docs/prompts/11_RELATORIOS_ESPECIALISTAS.md`. **Este documento cita nome de
cliente e estrutura de relatório livremente** (autorizado nesta sessão), mas
não reproduz literalmente segredo (credencial, chave, PoC completo) nem dado
pessoal identificável de titular — descreve existência e natureza, não
conteúdo.

**Status: análise técnica concluída. D-27 continua aberta** — falta a
chancela de fato das disciplinas sobre as mudanças de modelo propostas
abaixo, e falta uma amostra real de relatório de **coleta** forense (ver
seção 4).

---

## 1. Mapeamento por cliente

| Cliente | Documento | Categoria do catálogo | Modelo do prompt 11 | Nota |
|---|---|---|---|---|
| Cocamar | Vulnerabilities Report EST-11224 | `pentest` / `web_api` | `PentestReport` | Título diz "vulnerabilidades", conteúdo é pentest com exploração ativa (RCE root) |
| HUB Brasil | Vulnerabilities Report 1 | `pentest` / `web_api` | `PentestReport` | Mesma armadilha de título; achados PCI DSS, sem CVSS crítico nesta entrega |
| XP Investimentos | Vulnerabilities Report HLP-519 | `pentest` / `mobile` | `PentestReport` | App Android; achado com exposição de PII em massa (BOLA) |
| JHSF | Extraordinary Report 1 | `pentest` (entrega fora de ciclo) | `PentestReport` | Não é categoria nova — é 1 achado crítico entregue antes do relatório final |
| Diletta | Forense Report 1 | `response` / `digital_investigation` | `IncidentResponseReport` | É o relatório de **investigação**, não de **coleta** — ver seção 4 |
| CEEC | Threat Intelligence Report 1 | `defense` / `threat_intelligence` | Ambíguo entre `DefenseReport`, `AttackSurfaceReport` e `IncidentResponseReport` | TI disparada por incidente real cruza os três — decisão de produto pendente |

**Confirmação importante:** em nenhum dos 4 relatórios de "vulnerabilidades"
o título do documento correspondia ao modelo certo — todos eram pentests
pontuais com exploração ativa, não gestão contínua (`VulnManagementReport`
não se aplicou a nenhum dos 6). Isso valida a decisão já tomada de amarrar o
modelo ao `serviceKey`/categoria contratada do catálogo, nunca ao título
livre do documento.

---

## 2. Gaps recorrentes (aparecem em 2+ relatórios) — proposta de ajuste

| # | Gap | Onde apareceu | Ajuste proposto |
|---|---|---|---|
| 1 | `owaspCategory` ausente | Cocamar, HUB Brasil, XP, JHSF | Adicionar a `PentestFinding` |
| 2 | `cveId` (distinto de `cweId`) ausente | Cocamar, HUB Brasil, XP, JHSF | Adicionar a `PentestFinding`, nullable |
| 3 | `technicalImpact` sem campo próprio (hoje só `businessConsequence`) | Cocamar, HUB Brasil, XP, JHSF | Adicionar `technicalImpact` a `PentestFinding`, separado de `businessConsequence` |
| 4 | `references` (links por achado) ausente | Cocamar, HUB Brasil, XP, JHSF | Adicionar `List<String> references` a `PentestFinding` |
| 5 | `cvssVector` nunca é publicado na prática (só o score) | Cocamar, HUB Brasil, XP, JHSF | Tornar `cvssVector` nullable/opcional em todos os modelos que o usam |
| 6 | Seção de impedimentos de execução do teste, sem campo | Cocamar, HUB Brasil, XP | Adicionar `testingImpediments` (String?) a `PentestReport` |
| 7 | Nome do contato do cliente ("A/C") sem campo | Todos os 6 | Adicionar `clientContactName` a `ServiceReport` (comum) |
| 8 | `evidenceRefs`/PoC pode conter dado pessoal real, sem tag | JHSF (CPF, cartão, senha em hash), XP (PII em massa via BOLA) | Adicionar tag `[personalData]` opcional a `evidenceRefs`/`reproductionSteps` de `PentestFinding` — hoje só `incident_response`/`defense` têm essa tag |
| 9 | Ambiente do achado (produção/homologação) sem campo | XP | Adicionar `environment` (enum) a `PentestFinding` ou `PentestReport` — muda a severidade percebida |
| 10 | Sensibilidade por seção não cobre imagem com conteúdo misto | Cocamar (screenshot com header de proxy vazando), XP (um trecho de login não redigido), Diletta (campo redigido e outro aberto na mesma imagem), CEEC (captura com PII e fato agregado juntos) | Documentar no prompt 11/13: evidência em imagem é unidade atômica de sensibilidade — redigir a imagem antes de anexar, a política não redige parte de uma imagem em runtime |
| 11 | Entrega fora de ciclo ("extraordinário", achado único antecipado) sem marcador | JHSF | Adicionar `deliveryKind` (`scheduled`/`interim`) ou `isPartial: bool` a `ServiceReport` |
| 12 | Normas/guias citados (ISO 27037, NIST 800-86, RFC 3227...) sem campo | Diletta | Adicionar `forensicStandardsApplied` (lista curta) a `IncidentResponseReport` |
| 13 | `deviceIdentifiers` é vocabulário de dispositivo físico (fabricante/modelo/serial/IMEI) | Diletta (evidência era só recurso de nuvem: projeto GCP, VM, snapshot) | Para `forensics_cloud`: aceitar identificador de recurso de nuvem (projeto/instância/zona/snapshot) em vez de/além de campo físico |

---

## 3. Achados que não são gap de campo — são decisão de produto pendente

1. **CEEC (Threat Intelligence pós-incidente) cruza 3 modelos.** Um
   entregável de `threat_intelligence` disparado por um incidente real
   produziu, no mesmo documento: reconhecimento de superfície
   (`AttackSurfaceReport`-shaped), hipótese de vetor de incidente
   (`IncidentResponseReport`-shaped) e vazamento de credencial
   (`DefenseReport`-shaped). Decisão pendente: `DefenseReport` ganha um bloco
   opcional de achados de superfície, ou "TI ad hoc pós-incidente" vira
   sub-variante de `IncidentResponseReport`?
2. **`MaterialFactEvaluator.confirmedCompromise` — critério ambíguo em caso
   real.** Tanto CEEC quanto JHSF descrevem "indício forte de
   comprometimento/abuso por terceiro, não presenciado/confirmado
   diretamente" (não é uma confirmação formal, mas também não é uma hipótese
   fraca). A regra determinística de `confirmedCompromise` precisa dizer
   explicitamente se esse nível de evidência já dispara o gatilho, antes do
   avaliador ser codificado.
3. **JHSF valida o próprio mecanismo de `MaterialFact`.** O achado real
   (crítico + PII real exposta + indício de abuso por terceiro) é
   exatamente o tipo de cenário que a PARTE 6 do prompt 11 já pede para o
   mock — usar este caso (anonimizado) como um dos cenários de demonstração.

---

## 4. Pendência que ainda falta para fechar D-27 por completo

**Nenhum dos 6 relatórios da amostra é um relatório de coleta forense**
(`forensics_mobile`, `forensics_endpoint`, `forensics_cloud`,
`forensics_remote`). O núcleo mais sensível das decisões D-05/06/07 —
`deviceIdentifiers`, `acquisitionHash`, `custodianName`, `acquisitionMethod`
— continua **não validado contra documento real**, porque o relatório da
Diletta é de investigação, não de coleta.

**Ação recomendada:** pedir à disciplina de forense um exemplar real
(mesmo que anonimizado) de recibo/laudo de coleta antes de considerar D-27
totalmente fechada.

A validação da premissa "app guarda só o registro de custódia + ponteiro
para o cofre" (D-05) foi possível de forma indireta pelo relatório de
investigação: compatível, com uma nuance registrada — o relatório real
carrega excertos ilustrativos de evidência (trecho de log, captura de
console) como conteúdo do próprio documento, distintos da evidência bruta
que fica fora do app. Recomenda-se deixar essa distinção explícita no
prompt 13.

---

## 5. Próximo passo

1. Levar a tabela da seção 2 e os 3 pontos da seção 3 às disciplinas para
   chancela objetiva (aceitar/ajustar cada proposta).
2. Pedir o exemplar de coleta forense (seção 4).
3. Só depois de (1) e (2): aplicar os ajustes aprovados em
   `docs/prompts/11_RELATORIOS_ESPECIALISTAS.md` e então abrir o prompt 11.
