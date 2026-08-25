# Prompt 13 — Módulo de autoria e entrega de relatórios (Elytron)

**Entrega:** o ciclo de vida completo do relatório do lado da Elytron —
captura em campo, redação assistida, revisão, aprovação, verificação de redação
e publicação ao cliente.

**Leia antes:** [`../09_PERSONA_ESPECIALISTA.md`](../09_PERSONA_ESPECIALISTA.md)
e o prompt 12 (retrofit) precisam estar aplicados.

> **Escopo deliberadamente limitado, e vale entender o porquê.** Ninguém redige
> um relatório de pentest de 40 páginas no celular, e fingir que sim produz um
> editor ruim que ninguém usa. Este módulo cobre o que é **nativo de celular**
> (captura de evidência com cadeia de custódia, achado em campo), o que
> **destrava a entrega** (revisão, aprovação, publicação) e o que **protege o
> cliente** (verificação de redação). A redação longa acontece fora e entra por
> importação.

---

````text
# CONTEXTO FIXO
Projeto: Elytron Dash2Board (`elytron_dash2board`), Flutter + Material 3 + Firebase.
LEIA ANTES, como fonte de verdade:
  docs/09_PERSONA_ESPECIALISTA.md   <- a persona e suas proteções
  docs/08_CATALOGO_SERVICOS.md      <- 8 categorias, 44 serviços, classificações
  lib/features/reports/             <- modelos e ReportAccessPolicy (prompt 11)
  lib/features/staff/               <- StaffPolicy e TenantScope (prompt 12)
  lib/core/widgets/                 <- design system existente
Reuse os 8 modelos de relatório do prompt 11. NÃO crie um nono modelo.

# REGRAS DE CÓDIGO (obrigatórias)
- `flutter analyze` em "No issues found!"; `deprecated_member_use` é ERRO.
- Opacidade só com `Color.withValues(alpha: ...)`.
- Proibido `ColorScheme.background`/`onBackground`/`surfaceVariant`,
  `CardTheme`/`DialogTheme`/`TabBarTheme` em `ThemeData`,
  `pageTransitionsTheme`, `MaterialState*`.
- Riverpod só com APIs estáveis. Sem code generation.
- Domínio em Dart puro; `presentation/` não importa Firebase.
- Todo repositório recebe `tenantId` explícito. Não existe consulta sem tenant.
- pt-BR na interface e comentários; identificadores em inglês.
- Arquivos completos com imports. Nunca escreva "...". Máximo 250 linhas.

# TAREFA

## A) Ciclo de vida — `lib/features/authoring/domain/report_lifecycle.dart`

`ReportStatus`: `draft`, `inReview`, `changesRequested`, `approved`,
`published`, `amended`, `retracted`.

Transições válidas declaradas em mapa, com `canTransitionTo`; inválida lança.

```
draft ─► inReview ─► approved ─► published ─► amended ─► inReview
            │                        │
            ▼                        ▼
     changesRequested ─► draft   retracted
```

Regras não negociáveis:
- Só `published` e `amended` são visíveis ao cliente. `draft`, `inReview`,
  `changesRequested` e `approved` **nunca**.
- `retracted` continua visível ao cliente **com o aviso de retratação**.
  Sumir com um relatório já entregue é pior que admitir o erro: o cliente pode
  ter tomado decisão com base nele.
- `amended` cria uma nova versão preservando a anterior. Relatório de segurança
  é evidência; sobrescrever é destruir histórico.
- Toda transição grava autor, timestamp e motivo em `audit_logs`.

## B) Captura em campo — `lib/features/authoring/presentation/field_capture/`

### B1. Cadeia de custódia (`custody_capture_screen.dart`)
Formulário guiado para os serviços `forensics_*`, **offline-first**:
1. Identificação: tipo de dispositivo, marca, modelo, serial, IMEI quando
   aplicável.
2. Contexto legal: **base legal e finalidade são obrigatórias antes de
   qualquer captura** — o formulário não avança sem elas. Coleta forense
   frequentemente toca dado pessoal, e o app não pode ser o elo que ignora a
   LGPD.
3. Fotos: equipamento, lacre, etiqueta. Cada foto recebe hash SHA-256 no
   momento da captura.
4. Custodiante: nome, documento, assinatura desenhada na tela.
5. Aquisição: método, ferramenta, hash da imagem, data-hora, geolocalização
   **opcional e consentida** (explique por que é útil e permita recusar).
6. Revisão e selagem: gera um `CustodyRecord` imutável com hash do conjunto.

Implementação:
- Persistência local criptografada; sincroniza quando houver rede.
- Depois de sincronizado com sucesso, apague o local.
- O registro selado é **append-only**: correção vira um novo registro
  referenciando o anterior, nunca edição.
- Indicador claro de "pendente de sincronização" com contagem.

### B2. Achado em campo (`quick_finding_screen.dart`)
Captura rápida: título, severidade preliminar, ativo, evidência (foto ou
texto), serviço e cliente. Três toques até salvar. Vira rascunho de achado no
relatório correspondente.

## C) Redação assistida — `lib/features/authoring/presentation/editor/`

Editor **estruturado por seções**, não um editor de texto livre:
- As seções vêm do modelo da categoria (prompt 11); cada seção declara sua
  `sensitivity`.
- Campos curtos com contador e orientação editorial embutida (o que uma boa
  consequência de negócio contém, por exemplo).
- Lista de achados com edição individual.
- Importação por seção: colar Markdown ou anexar arquivo para popular uma
  seção longa.
- **Importação estruturada (todo o relatório):** o `consultor`/`analyst`
  pode anexar um único arquivo JSON, validado contra o schema do modelo da
  categoria (prompt 11 — `ServiceReport` + subtipo), populando o relatório
  inteiro de uma vez. Campos derivados do servidor (`tenantId`,
  `elytronLeadName`, `id`) nunca vêm do JSON enviado — sempre do contexto da
  sessão de staff. JSON que não valida contra o schema é rejeitado com o
  campo e o motivo, nunca aceito parcialmente. O relatório importado entra
  como `draft`, sujeito ao mesmo ciclo de revisão/aprovação da seção D — a
  importação não pula `reviewer`/`StaffPolicy.canApprove`.
- Salvamento automático a cada 5 segundos, com indicador de estado.
- **Ao classificar uma seção**, o editor mostra em tempo real quais personas do
  cliente vão enxergá-la. Consequência visível na hora da escolha, não depois.

## D) Revisão — `review_screen.dart`
- `reviewer` navega seção a seção, comenta e marca cada uma como "ok" ou
  "ajustar". Comentário obrigatório para "ajustar".
- Barra de progresso da revisão.
- Aprovar exige todas as seções em "ok".
- `StaffPolicy.canApprove` bloqueia autoaprovação; a exceção registrada é
  possível, mas exige justificativa escrita e aparece no relatório publicado.

## E) Verificação de redação e publicação — `publish_screen.dart`

**O recurso mais importante do módulo.** Antes de publicar:

1. **Prévia por persona:** três abas mostrando exatamente o que
   `operational`, `strategic` e `board` vão ver, renderizadas pelo mesmo
   `ReportAccessPolicy` que o app do cliente usa. Não uma simulação — o
   componente real.
2. **Varredura automática:** procura, na visão `board`, termos da lista
   proibida (CVE, CVSS, payload, exploit, hash, IOC, nomes de ferramenta,
   endereço IP, credencial). Cada ocorrência aparece com a seção de origem e um
   atalho para corrigir.
3. **Checklist de publicação**, com bloqueio real: classificação definida,
   sumário executivo preenchido, todo achado com remediação, fatos relevantes
   avaliados, revisão aprovada.
4. **Avaliação de fato relevante:** roda o `MaterialFactEvaluator` do prompt 11
   e mostra o que será escalado ao board, com a consequência em linguagem de
   negócio. O `deliveryLead` pode acrescentar um fato manualmente, nunca
   remover um detectado — pode apenas justificar por escrito.
5. **Reautenticação** antes de confirmar.
6. Publicação notifica as personas conforme a classificação e os fatos
   relevantes.

## F) Errata e retratação — `amend_screen.dart`
Nova versão com o **motivo obrigatório** e um comparativo do que mudou.
O cliente vê o aviso de versão nova e consegue abrir a anterior.

## G) Dados
`lib/features/authoring/data/` com interface + mock + firestore.
Coleções: `/tenants/{tid}/reports/{rid}` (com `status`, `version`,
`authorUid`, `reviewerUid`, `publishedAt`), subcoleção `sections`,
`/tenants/{tid}/custody_records/{cid}` (append-only),
`/tenants/{tid}/report_comments/{cid}`.

`firestore.rules`: rascunho só para staff atribuído; `custody_records` sem
update e sem delete para ninguém; publicação só por `deliveryLead`.

O mock precisa de: um relatório em `draft`, um em `inReview` com comentários,
um `approved` pronto para publicar (com **uma violação plantada** na visão do
board, para a varredura ter o que encontrar) e um `published` com errata.

# TESTES
`test/authoring/`:
- `report_lifecycle_test.dart` — toda transição válida passa, toda inválida
  lança; cliente não enxerga nenhum status pré-publicação.
- `redaction_scanner_test.dart` — detecta cada categoria de termo proibido;
  não gera falso positivo em texto de negócio legítimo.
- `custody_record_test.dart` — registro selado é imutável; correção cria novo
  registro encadeado; captura sem base legal é recusada.
- `publish_gate_test.dart` — checklist incompleto bloqueia; autoaprovação sem
  exceção registrada bloqueia; fato relevante detectado não pode ser removido.
- `offline_sync_test.dart` — captura offline persiste, sincroniza e some do
  armazenamento local.
Use `pump(Duration)`, nunca `pumpAndSettle`.

# CRITÉRIOS DE ACEITE
1. Publicar o relatório com a violação plantada é **impossível** sem corrigir.
2. Coleta forense completa funciona em modo avião e sincroniza depois.
3. Nenhuma persona de cliente enxerga rascunho — provado por teste de rules.
4. Retratação mantém o relatório visível com aviso.
5. A prévia por persona usa o MESMO componente do app do cliente, não uma
   cópia.
6. `flutter analyze` limpo, `flutter test` verde, `npm run test:rules` verde.

# COMO RESPONDER
Ordem: ciclo de vida + testes → captura de custódia → editor → revisão →
verificação e publicação → errata. A verificação de redação vem depois do
editor de propósito: ela precisa do modelo de seções pronto.

Ao final, apresente: (a) a máquina de estados como ficou, (b) a saída da
varredura de redação no relatório com a violação plantada, (c) o texto da visão
`board` desse relatório antes e depois da correção.
````
