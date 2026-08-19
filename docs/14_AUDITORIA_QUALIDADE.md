# Relatório de auditoria de qualidade — Elytron Dash2Board

| | |
|---|---|
| **Data** | 19/08/2026 |
| **Escopo** | Repositório completo, documentação, configuração de backend, procedimento de ambiente e pré-requisitos |
| **Estado auditado** | 85 arquivos Dart, 18 de teste, 12 documentos, 14 prompts, seed em TypeScript, 5 Cloud Functions |
| **Método** | Inspeção estática do repositório montado, verificação de conformidade contra as regras declaradas, teste de integridade de referências |
| **Veredito** | **Aprovado com ressalvas.** Um achado crítico bloqueia a continuidade segura do trabalho |

---

## 1. Limites desta auditoria

Auditei o repositório a partir de um sandbox Linux com a pasta montada. **Não
executei** `flutter analyze`, `flutter test`, `firebase deploy` nem os
emuladores, porque a cadeia Flutter/Xcode/Firebase vive no seu macOS e não é
alcançável daqui. Também **não há histórico de versão para auditar**, pelo
motivo do achado C-01.

`scripts/audit.sh` cobre exatamente essa lacuna: rode-o no macOS e ele produz o
laudo de execução que falta a este relatório.

---

## 2. Conformidade verificada — o que está certo

Esta seção existe porque auditoria que só lista defeito não mede nada.

| Controle | Resultado |
|---|---|
| `Color.withOpacity` no código | **0 ocorrências reais** (as 2 encontradas são comentários normativos) |
| `MaterialState*`, `surfaceVariant`, `onBackground` | 0 |
| `CardTheme`/`DialogTheme`/`TabBarTheme` em `ThemeData` | 0 |
| `pageTransitionsTheme` | 0 reais (1 comentário explicando a proibição) |
| `pumpAndSettle` em teste | **0 reais** (as 9 são comentários explicando por que não usar) |
| `AutoDispose*Notifier` / `StateNotifier` | 0 — a aposta em APIs estáveis do Riverpod se confirmou com a 3.4.2 |
| `print()` | 0 |
| Acento de marca dentro de gráfico | 0 — a regra do prompt 3 foi respeitada |
| Paleta validada em `chart_tokens.dart` | Aplicada integralmente |
| Firebase importado em `presentation/` | 0 |
| Segredo versionável no repositório | Nenhum |
| Links quebrados na documentação | Nenhum |
| Guarda `CONFIRM_PROD` no seed | Presente, com emulador por padrão |
| Lockfiles | `pubspec.lock`, `functions/package-lock.json`, `scripts/seed/package-lock.json` presentes |

**Avaliação:** a aderência às regras de código é excepcional. Em 85 arquivos,
nenhuma violação real das 12 regras declaradas. Isso indica que o mecanismo de
prompt com bloco de regras fixas está funcionando.

---

## 3. Achados

### C-01 · CRÍTICO · O projeto não está sob controle de versão

**Evidência:** `git rev-parse --is-inside-work-tree` → não é repositório git.
85 arquivos Dart, 18 testes, 507 linhas de seed, 5 Cloud Functions.

**Impacto:** não existe histórico, diff, reversão nem rastreabilidade. Um
prompt que sobrescreve arquivo, um `flutter clean` mal digitado ou um conflito
de ferramenta destrói trabalho de forma irrecuperável. Também impede revisão de
código, CI e qualquer evidência de mudança para auditoria — ironia relevante em
produto de segurança.

**Agravante:** os próximos prompts (10 a 14) fazem *refatoração transversal*.
O prompt 12 reescreve `firestore.rules` e mexe em identidade e roteamento. Sem
git, um retrofit malsucedido não tem volta.

**Correção (antes de qualquer outro trabalho):**
```bash
cd /Volumes/Dev_environment/DEV_CLAUDE/elytron_dash2board
git init && git add -A && git commit -m "estado inicial auditado"
```
O `.gitignore` já está correto e cobre `build`, `.dart_tool`, `node_modules`,
`.DS_Store` e segredos nativos.

---

### A-01 · ALTO · `.firebaserc` aponta o alias `default` para projeto inexistente

**Evidência:**
```json
"default": "elytron-dash2board-dev",   // não existe
"e-dash2board": "elytron-d2b-dev"      // o real
```

**Impacto:** todo `firebase deploy` sem `-P` falha — foi exatamente o erro
`Project not found or deleted` que ocorreu. Pior no futuro: se alguém registrar
esse ID, o deploy acerta um projeto de terceiro.

**Causa raiz:** `.firebaserc.example` trazia IDs que *pareciam* reais em vez de
marcadores. Defeito de origem meu.

**Correção:** deixar `default` apontando para o projeto real e remover os
inexistentes.

---

### A-02 · ALTO · Nenhuma security rule tem teste automatizado

**Evidência:** `test/rules/` não existe. O prompt 7 exigia
`@firebase/rules-unit-testing`.

**Impacto:** `firestore.rules` é o **principal controle de segurança do
produto** — isolamento entre clientes, classificação de relatório, quem lê o
quê — e hoje só é validado por inspeção visual. Sem teste, a reescrita do
prompt 12 não tem rede.

**Correção:** implementar `test/rules` antes do prompt 12, com caso positivo e
negativo para cada regra. Prioridade sobre qualquer tela nova.

---

### A-03 · ALTO · O caminho Firestore nunca foi exercitado

**Evidência:** `lib/firebase_options.dart` ainda contém `PLACEHOLDER`; não há
`google-services.json` nem `GoogleService-Info.plist`.

**Impacto:** todo o produto foi validado apenas em `MOCK=true`. Conversores,
consultas, índices e regras nunca rodaram contra Firestore real ou emulador. A
distância entre "funciona no mock" e "funciona no Firestore" costuma esconder
índice faltante e conversão de `Timestamp`.

**Correção:** `flutterfire configure` no projeto real + rodar com
`--dart-define=DATA_SOURCE=firestore` contra os emuladores e o seed.

---

### A-04 · ALTO · Índices não acompanharam as consultas implementadas

**Evidência:** 11 índices, os mesmos do primeiro dia.
`firestore_strategic_repository.dart` já faz `where('framework')` e
`where('active')`, e as telas de compliance e insights aplicam filtro composto.

**Impacto:** consulta sem índice falha **em runtime**, não em compilação. No
mock não aparece. A falha vai surgir na primeira demo com dado real.

**Correção:** rodar contra o emulador com dado do seed; o Firestore imprime no
console o índice exato que falta. Acrescentar todos antes de publicar.

---

### A-05 · ALTO · Documentação com procedimento que causa falha conhecida

**Evidência:** `docs/04_SETUP_MACOS_VSCODE.md:46` instrui
`firebase deploy --only firestore:rules,firestore:indexes,storage`.
`storage` exige plano Blaze — e essa linha reproduz o erro já enfrentado.
`docs/05` e `docs/12` já trazem a versão correta.

**Impacto:** documento de setup que quebra na primeira execução destrói a
confiança no restante da documentação.

**Correção:** **aplicada durante esta auditoria** — doc 04 alinhado aos demais,
com a nota de Blaze.

---

### M-01 · MÉDIO · Sem integração contínua

Nenhum pipeline roda `flutter analyze`, `flutter test` ou os testes de regras.
Toda a garantia de qualidade depende de o desenvolvedor lembrar. Recomendo
GitHub Actions com três jobs — analyze, test, rules — bloqueando merge.

### M-02 · MÉDIO · `CLAUDE.md` ausente

O Claude Code não carrega as regras do projeto automaticamente. Fora dos
prompts, o agente não sabe que `withOpacity` é proibido. É a lacuna que separa
"o prompt garante" de "o repositório garante".

### M-03 · MÉDIO · `sections` sem regra explícita

`firestore.rules` cobre `reports` mas não a subcoleção `sections`. Hoje o
catch-all nega — comportamento seguro. O risco é o time descobrir que "nada
lê" ao implementar o prompt 11 e afrouxar a regra errada. A regra por seção é
a base de toda a proteção de conteúdo.

### M-04 · MÉDIO · `.firebaserc` está no `.gitignore`

IDs de projeto não são segredo. Ignorá-lo obriga cada desenvolvedor a recriar o
arquivo à mão — que é justamente a origem do A-01. Recomendo versioná-lo e
manter ignorados apenas credenciais e `google-services.json`.

### M-05 · MÉDIO · `bootstrap.sh` deixou de ser seguro para reexecução

O script roda `flutter pub add` sem versão. Agora que o `pubspec.yaml` está
fixado (`firebase_core: ^4.13.0` etc.), reexecutar pode subir versões sem
querer. Precisa detectar projeto já inicializado e sair, ou pedir confirmação.

### B-01 · BAIXO · Dois `TODO` de `url_launcher`

Em `insight_detail_screen.dart` e `control_detail_sheet.dart`. Dívida
consciente e documentada; falta apenas rastreamento formal.

### B-02 · BAIXO · `.DS_Store` presentes na raiz e em `lib/`

Cobertos pelo `.gitignore`; some sozinho ao inicializar o git.

---

## 4. Plano de correção priorizado

| Ordem | Achado | Esforço | Bloqueia |
|---|---|---|---|
| 1 | C-01 git init | 2 min | **tudo** |
| 2 | A-01 `.firebaserc` | 2 min | qualquer deploy |
| 3 | M-02 `CLAUDE.md` | 15 min | qualidade fora dos prompts |
| 4 | A-03 `flutterfire configure` + emulador | 1 h | A-04 |
| 5 | A-04 índices | 1 h | demo com dado real |
| 6 | A-02 `test/rules` | 4 h | prompt 12 |
| 7 | M-01 CI | 2 h | escala do time |
| 8 | M-04, M-05, M-03 | 1 h | — |

**Recomendação de sequência:** itens 1 a 3 hoje; 4 a 6 antes de iniciar o
prompt 10. Não recomendo abrir os prompts 10 a 14 sem git e sem teste de
regras — são justamente os que mexem em autorização.

---

## 5. Verificação de execução — o que só você pode rodar

`scripts/audit.sh` executa no macOS e coleta: versões da cadeia de ferramentas,
`flutter doctor`, `flutter analyze`, `flutter test`, consistência de
`pubspec.lock`, projetos Firebase acessíveis, e uma reconferência dos controles
desta auditoria. A saída vai para `audit-report.txt`.

```bash
chmod +x scripts/audit.sh && ./scripts/audit.sh
```

Sem esse laudo, os itens A-03 e A-04 permanecem **não verificados**, não
"aprovados".
