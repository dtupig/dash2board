# Prompt 7 — Trocar o mock pelo Firestore real

**Entrega:** seed reproduzível, emuladores funcionando, repositórios reais
validados e testes das security rules.

**Pré-requisito:** projeto Firebase criado e `flutterfire configure` rodado
(veja `docs/05_TROUBLESHOOTING.md`).

---

````text
# CONTEXTO FIXO
Projeto: Elytron Dash2Board (`elytron_dash2board`), Flutter + Firebase.
LEIA antes: docs/01_MODELO_DADOS_FIRESTORE.md, firestore.rules,
firestore.indexes.json, functions/src/index.ts,
lib/features/strategic/data/ (mock e firestore) e
lib/core/config/firestore_paths.dart.

# REGRAS DE CÓDIGO (obrigatórias)
- `flutter analyze` em "No issues found!"; `deprecated_member_use` é ERRO.
- Opacidade só com `Color.withValues(alpha: ...)`; sem `MaterialState*`;
  sem `pageTransitionsTheme`; sem `CardTheme`/`DialogTheme`/`TabBarTheme`.
- Riverpod só com APIs estáveis. Sem code generation.
- pt-BR na interface e comentários; identificadores em inglês.
- Arquivos completos com imports. Nunca escreva "...".
- **Nenhuma tela pode mudar neste prompt.** Se você precisar tocar em um
  arquivo de `presentation/`, a abstração do prompt 2 falhou — pare e me diga
  qual é o vazamento em vez de contornar.

# TAREFA

## A) Seed reproduzível
`scripts/seed/` em TypeScript, rodando contra o **emulador** por padrão:
- `package.json` com `npm run seed` e `npm run seed:prod` (o segundo exige a
  variável `CONFIRM_PROD=1`, para não haver acidente);
- `seed.ts` usando `firebase-admin` apontado para
  `FIRESTORE_EMULATOR_HOST=localhost:8080` e `FIREBASE_AUTH_EMULATOR_HOST=localhost:9099`;
- gera **exatamente os mesmos dados** do `MockStrategicRepository` (índice 72,
  mediana 68, os seis domínios, 24 controles, 6 riscos, 8 insights), para que
  mock e real sejam comparáveis lado a lado;
- cria o tenant `tenant-demo`, os três usuários de demonstração no Auth, os
  convites em `/invites/{email}` e os membros com o `role` correto;
- é idempotente: rodar duas vezes não duplica nada.

## B) Custom claims no ambiente local
Documente e automatize: após o seed, os claims são aplicados pela Cloud
Function `syncMemberClaims` rodando no emulador. Se o emulador de Functions não
estiver ativo, o script aplica os claims direto pelo Admin SDK, e avisa no
console que fez isso.

## C) Validar os repositórios Firestore
Confirme que `FirestoreStrategicRepository` lê corretamente o que o seed
gravou. Onde os índices compostos de `firestore.indexes.json` não cobrirem uma
consulta, **corrija o arquivo de índices** — não simplifique a consulta para
fugir do índice.

Converta `Timestamp` → `DateTime` apenas na camada de dados. Se encontrar
`Timestamp` vazando para o domínio ou para a UI, corrija.

## D) Testes das security rules
`test/rules/` com `@firebase/rules-unit-testing` (Node, `npm run test:rules`).
Cubra, no mínimo:
1. usuário do tenant A **não** lê nada do tenant B;
2. `board` **não** lê `incidents` nem `compliance`;
3. `operational` **não** lê `risks` nem `posture_snapshots`;
4. `strategic` lê `compliance` e `posture_snapshots`;
5. ninguém, em nenhum papel, lê `audit_logs`;
6. cliente **não** consegue escrever o próprio `role` em `members/{uid}`;
7. `reports` só é lido quando `audience` == papel do leitor;
8. `board` consegue gravar apenas `acceptance`/`boardNote` em `risks`, e mais
   nada.

Cada teste precisa ter também o caso positivo correspondente — uma regra que
bloqueia tudo passa em teste negativo e é inútil.

## E) Alternar a fonte
Verifique os três modos:
- `flutter run --dart-define=MOCK=true` → mock, sem Firebase;
- `flutter run --dart-define=DATA_SOURCE=firestore` com emuladores → dados do
  seed;
- build normal → projeto real.

Documente os três em `docs/04_SETUP_MACOS_VSCODE.md`.

## F) Resiliência
- Timeout e mensagem segura em toda leitura (reuse `AppFailure`).
- Erro de permissão vira "você não tem acesso a este conteúdo", nunca a
  mensagem crua do Firebase.
- Cache offline já está ligado em `main.dart`: confirme que, em modo avião, a
  última leitura ainda aparece com o rodapé de "dados de <data>".

# CRITÉRIOS DE ACEITE
1. `firebase emulators:start` + `npm run seed` + app com
   `--dart-define=DATA_SOURCE=firestore` mostra a MESMA tela do modo mock.
2. `npm run test:rules` passa, com casos positivos e negativos.
3. `git diff --stat` deste prompt não toca em nenhum arquivo de
   `lib/features/*/presentation/`.
4. `flutter analyze` limpo, `flutter test` verde.

# COMO RESPONDER
Seed primeiro, depois validação dos repositórios, depois testes de rules. Ao
final, cole a saída de `npm run test:rules` e o `git diff --stat`.
````
