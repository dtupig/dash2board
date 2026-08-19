# Catálogo de serviços Elytron — taxonomia canônica

Fonte única de verdade para o catálogo, o wizard de demanda e os modelos de
relatório. **Alterou aqui, alterou no código**: `ServiceCategory`,
`ServiceOffering` e os esquemas de relatório derivam desta tabela.

Regras de nomenclatura: `categoryKey` e `serviceKey` são `snake_case`, estáveis
e **nunca** mudam depois de publicados (eles vão para o Firestore e para os
relatórios já emitidos). O rótulo em pt-BR pode ser reescrito à vontade.

## Categorias

| # | `categoryKey` | Rótulo | Serviços | Modelo de relatório |
|---|---|---|---:|---|
| 1 | `pentest` | Testes de Penetração | 7 | `PentestReport` |
| 2 | `appsec` | Segurança de Aplicação | 7 | `AppSecReport` |
| 3 | `attack_surface` | Superfície de Ataque | 1 | `AttackSurfaceReport` |
| 4 | `response` | Resposta e Crise | 12 | `IncidentResponseReport` |
| 5 | `governance` | Risco e Governança | 5 | `GovernanceReport` |
| 6 | `vulnerability` | Gestão de Vulnerabilidades | 1 | `VulnManagementReport` |
| 7 | `third_party` | Gestão de Terceiros | 1 | `ThirdPartyReport` |
| 8 | `defense` | Defesa e Inteligência | 10 | `DefenseReport` |

**Total: 44 serviços.**

## Serviços

### 1. `pentest` — Testes de Penetração
| `serviceKey` | Serviço | Entrega | Persona primária |
|---|---|---|---|
| `web_api` | WEB Application - API | pontual / recorrente | operational |
| `mobile` | Mobile | pontual | operational |
| `code_review` | Revisão de código (whitebox) | pontual | operational |
| `reverse_engineering` | Testes em executáveis (engenharia reversa) | pontual | operational |
| `infrastructure` | Infraestrutura - interno/externo | pontual / recorrente | operational |
| `apt_simulation` | APT Simulation | pontual | strategic |
| `ai_pentest` | Pentest em IA | pontual | strategic |

### 2. `appsec` — Segurança de Aplicação
| `serviceKey` | Serviço | Entrega | Persona primária |
|---|---|---|---|
| `secure_dev_training` | Treinamento de desenvolvimento seguro | pontual | strategic |
| `secure_dev_support` | Apoio de desenvolvimento seguro | contínuo | operational |
| `dast` | DAST | contínuo | operational |
| `sast` | SAST | contínuo | operational |
| `manual_review` | Manual (Especialista) | pontual | operational |
| `policy_development` | Desenvolvimento de política | pontual | strategic |
| `security_champion` | Security Champion | contínuo | strategic |

### 3. `attack_surface` — Superfície de Ataque
| `serviceKey` | Serviço | Entrega | Persona primária |
|---|---|---|---|
| `asm_monitoring` | Monitoramento de Superfície de Ataque | contínuo | operational |

### 4. `response` — Resposta e Crise
| `serviceKey` | Serviço | Entrega | Persona primária |
|---|---|---|---|
| `dfir_retainer` | RETAINER DFIR: Resposta a Incidente | retainer | strategic |
| `digital_investigation` | Investigações Digitais e Perícia Forense | pontual | strategic |
| `tabletop` | Tabletop Exercise | pontual | strategic |
| `wargame_ctf` | Wargame / GCC / Capture the Flag (CTF) | pontual | operational |
| `crisis_simulation` | Simulação de Crise Cibernética | pontual | board |
| `forensics_mobile` | Forense Digital: Coleta de celular | pontual | operational |
| `forensics_endpoint` | Forense Digital: Coleta de endpoint | pontual | operational |
| `forensics_cloud` | Forense Digital: Coleta em nuvem | pontual | operational |
| `forensics_remote` | Forense Digital: Coleta remota | pontual | operational |
| `forensics_processing` | Forense Digital: Processamento de dados | pontual | operational |
| `forensics_hosting_hash` | Forense Digital: Hosting com HASH | contínuo | operational |
| `forensics_uam` | Forense Digital: UAM (User Activity Monitoring) | contínuo | strategic |

### 5. `governance` — Risco e Governança
| `serviceKey` | Serviço | Entrega | Persona primária |
|---|---|---|---|
| `regulatory_consulting` | Consultoria DORA, NIST, PCI, LGPD, GDPR | pontual | strategic |
| `bcp_assessment` | Assessments de Plano de Continuidade | pontual | strategic |
| `master_plan_policies` | Planos Diretores e Políticas | pontual | strategic |
| `disaster_recovery` | Disaster Recovery | pontual | strategic |
| `maturity_assessment` | Assessments de Maturidade | pontual | board |

### 6. `vulnerability` — Gestão de Vulnerabilidades
| `serviceKey` | Serviço | Entrega | Persona primária |
|---|---|---|---|
| `vulnerability_management` | Gestão de Vulnerabilidades | contínuo | operational |

### 7. `third_party` — Gestão de Terceiros
| `serviceKey` | Serviço | Entrega | Persona primária |
|---|---|---|---|
| `third_party_management` | Gestão de Terceiros | contínuo | strategic |

### 8. `defense` — Defesa e Inteligência
| `serviceKey` | Serviço | Entrega | Persona primária |
|---|---|---|---|
| `cloud_posture` | Cloud Posture (Google, M365, Azure) | contínuo | operational |
| `deep_dark_web` | Monitoramento na Deep e Dark Web | contínuo | strategic |
| `threat_intelligence` | Threat Intelligence e CTI | contínuo | strategic |
| `threat_hunting` | Threat Hunting | contínuo | operational |
| `implementation_tuning` | Implementação / Evolução (fine tuning) | pontual | operational |
| `email_protection` | E-mail Protection | contínuo | operational |
| `edr_xdr_ndr` | EDR / XDR / NDR | contínuo | operational |
| `microsegmentation` | Microsegmentação | pontual | operational |
| `waf_waap` | WAF / WAAP - API Protection | contínuo | operational |
| `phishing_workshop` | Phishing e Workshop | recorrente | strategic |

## Alçada de demanda (decisão do produto)

```
operational  →  ABRE demanda técnica
strategic    →  APROVA (e pode abrir; ainda assim gera registro de aprovação)
board        →  NÃO abre e NÃO aprova; é INFORMADO por gatilho de fato relevante
```

O "fato relevante" não é um aviso de cortesia: é o mecanismo que leva ao board
apenas o que muda decisão. Os gatilhos estão em
`docs/prompts/11_RELATORIOS_ESPECIALISTAS.md`.

## Classificação de confidencialidade do relatório

Todo relatório carrega uma classificação, e ela governa o que cada persona vê:

| Classificação | Quem lê | Exemplos |
|---|---|---|
| `public_internal` | as três personas | resumo de maturidade, workshop |
| `restricted` | operational + strategic | ASM, gestão de vulnerabilidades |
| `confidential` | strategic (+ operational no seu escopo) | pentest com prova de conceito |
| `secret` | strategic apenas, com registro de leitura | perícia forense, investigação, UAM |

Prova de conceito de exploração, credencial, dado pessoal e cadeia de custódia
**nunca** aparecem para a persona `board`, em nenhuma classificação.
