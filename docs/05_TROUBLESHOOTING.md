# Troubleshooting — setup local

## 0. Tela em branco no simulador

**Causa.** `main()` chama `Firebase.initializeApp` antes de `runApp`. Se
`lib/firebase_options.dart` ainda for o placeholder (ou seja, `flutterfire
configure` não completou), a inicialização lança `UnsupportedError`, o
`runApp` nunca roda e você vê uma tela vazia — sem erro visível na interface.

**Diagnóstico em um comando:**

```bash
grep -q PLACEHOLDER lib/firebase_options.dart && echo "ainda é placeholder"
ls ios/Runner/GoogleService-Info.plist android/app/google-services.json
```

**Correção imediata — rode em modo de demonstração:**

```bash
flutter run --dart-define=MOCK=true
```

Nesse modo o Firebase **não** é inicializado. O app sobe offline, a tela de
login mostra um cartão com as três contas de demonstração
(`operacao@`, `ciso@`, `board@demo.elytron`) e qualquer senha com 12 ou mais
caracteres entra. Serve para desenvolver e demonstrar a interface inteira sem
console, faturamento ou seed.

No VSCode existe a configuração **"Dash2Board · mock (sem Firebase)"** no menu
de execução.

**Correção definitiva:** veja a seção 1 abaixo e rode o `flutterfire
configure` até o fim.

## 1. `Project 'projects/elytron-dash2board-dev' not found or deleted`

**Causa.** `elytron-dash2board-dev` é um **exemplo** que veio em
`.firebaserc.example`. O projeto não existe no seu console Firebase. O
`firebase deploy` só funciona depois de o projeto existir de verdade.

**Correção.** Crie o projeto (o ID é global, então talvez precise de sufixo):

```bash
firebase login
firebase projects:list                       # veja o que você já tem

# se não tiver nenhum, crie:
firebase projects:create elytron-d2b-dev --display-name "Elytron Dash2Board Dev"
```

Depois aponte o repositório para o ID **real**:

```bash
firebase use --add            # escolha o projeto e dê o alias "default"
cat .firebaserc               # confirme que o ID está correto
```

Crie o banco Firestore antes do primeiro deploy de regras (uma vez por
projeto). Escolha a região e **não mude depois**:

```bash
firebase firestore:databases:create "(default)" --location=southamerica-east1
```

E rode o FlutterFire com o mesmo ID:

```bash
flutterfire configure \
  --project=elytron-d2b-dev \
  --platforms=ios,android \
  --ios-bundle-id=com.elytronsecurity.dash2board \
  --android-package-name=com.elytronsecurity.dash2board
```

### Atenção ao plano de faturamento

| Recurso | Plano Spark (grátis) |
|---|---|
| Firestore + rules + indexes | ✅ funciona |
| Authentication | ✅ funciona |
| **Cloud Storage** | ❌ exige Blaze |
| **Cloud Functions** | ❌ exige Blaze |

Enquanto estiver no Spark, **deploye só o Firestore**:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

As Cloud Functions (`gateSignUp`, `syncMemberClaims`, `assignRole`,
`claimInvite`) rodam localmente nos emuladores sem custo:

```bash
firebase emulators:start
```

Para deployar Storage e Functions de verdade, ative o Blaze no console
(tem cota gratuita generosa; o custo real deste projeto em dev é próximo de
zero) e então:

```bash
firebase deploy --only firestore,storage,functions
```

## 2. `npm error EEXIST` / `EACCES: permission denied` em `~/.npm/_cacache`

**Causa.** O cache do npm em `/Users/<você>/.npm` tem arquivos pertencentes ao
`root` — quase sempre resultado de um `sudo npm install` no passado. O npm
rodando como seu usuário não consegue reescrever esses arquivos.

**Correção** (devolve a pasta para o seu usuário e limpa o cache):

```bash
sudo chown -R "$(whoami)":staff ~/.npm
npm cache clean --force
cd functions && npm install && cd ..
```

Nunca use `sudo npm install` neste projeto — é o que recria o problema.

## 3. `No supported devices connected`

**Causa.** O projeto foi criado só para `ios` e `android`. O Flutter encontrou
apenas macOS e Chrome, que não são plataformas-alvo. É comportamento correto,
não erro: falta abrir um simulador.

**iOS (caminho mais rápido no seu Mac com Apple Silicon):**

```bash
open -a Simulator
flutter devices                       # o iPhone deve aparecer
flutter run --dart-define=ENV=dev
```

Se o Simulator não abrir, instale o runtime do iOS pelo Xcode:
`Xcode → Settings → Components → iOS Simulator`.

**Android:**

```bash
flutter emulators                              # lista os AVDs
flutter emulators --launch <id_do_avd>
flutter run --dart-define=ENV=dev
```

Se não houver AVD, crie um em `Android Studio → Device Manager`.

**Não rode `flutter create .` para adicionar macOS/web.** A sugestão que o
Flutter imprime no terminal é genérica: este é um produto mobile, e adicionar
web quebraria as premissas de segurança (o `firebase_options.dart` lança
`UnsupportedError` para web de propósito).

## Ordem correta do setup, do zero

```bash
# 1. código
./scripts/bootstrap.sh
flutter analyze                     # precisa dar "No issues found!"
flutter test

# 2. npm saudável (se der EACCES)
sudo chown -R "$(whoami)":staff ~/.npm && npm cache clean --force

# 3. Firebase
firebase login
firebase projects:create <SEU_ID> --display-name "Elytron Dash2Board Dev"
firebase use --add
firebase firestore:databases:create "(default)" --location=southamerica-east1
flutterfire configure --project=<SEU_ID> --platforms=ios,android \
  --ios-bundle-id=com.elytronsecurity.dash2board \
  --android-package-name=com.elytronsecurity.dash2board
firebase deploy --only firestore:rules,firestore:indexes

# 4. Auth: habilite E-mail/senha no console

# 5. rodar
open -a Simulator
flutter run --dart-define=ENV=dev
```

Nesse ponto o app sobe na `SplashScreen`, resolve que não há sessão e para na
`WelcomeScreen`. O login só funciona depois de existir um usuário no
Authentication com um documento de membro / custom claim — veja o passo 5 de
`04_SETUP_MACOS_VSCODE.md`.
