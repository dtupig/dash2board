# Templates genéricos

Dados sintéticos, nunca reais, usados como placeholder enquanto não há
amostra real ou importação via D-32 (`docs/13_DECISOES_PENDENTES.md`).
Todo arquivo aqui tem `"isGeneric": true` e um campo `provenance` — nenhum
código deve tratar esse dado como se fosse de cliente real.

| Arquivo | Para quê | Substituído por |
|---|---|---|
| `custody_record_generic_device.json` | Coleta forense de dispositivo físico (`forensics_endpoint`/`forensics_mobile`/`forensics_remote`) — campos de `docs/prompts/13_MODULO_AUTORIA_RELATORIOS.md` seção B1 | Amostra real da disciplina de forense, ou upload real via D-32 |
| `custody_record_generic_cloud.json` | Coleta forense de recurso de nuvem (`forensics_cloud`) — resolve o gap #13 de `docs/18_VALIDACAO_D27_TEMPLATES_REAIS.md` | Idem |

Contexto completo em `docs/18_VALIDACAO_D27_TEMPLATES_REAIS.md`, seção 6.
