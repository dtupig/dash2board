# Setup — macOS + VSCode

## 1. Pré-requisitos

```bash
# Xcode (App Store) e ferramentas de linha de comando
xcode-select --install
sudo xcodebuild -runFirstLaunch

# Homebrew, CocoaPods, Node e Firebase CLI
brew install cocoapods node
npm install -g firebase-tools

# Flutter (via site oficial ou brew)
flutter doctor
```

`flutter doctor` precisa terminar sem erros em **Flutter**, **Xcode** e
**Android toolchain**. Aceite as licenças do Android com
`flutter doctor --android-licenses`.

## 2. Bootstrap do projeto

```bash
cd <pasta-do-projeto>
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

O script gera `android/` e `ios/` com o Flutter instalado na sua máquina,
resolve e fixa as versões das dependências e roda `flutter analyze`.

## 3. Firebase

```bash
firebase login
dart pub global activate flutterfire_cli

flutterfire configure \
  --project=<SEU_PROJETO> \
  --platforms=ios,android \
  --ios-bundle-id=com.elytronsecurity.dash2board \
  --android-package-name=com.elytronsecurity.dash2board

cp .firebaserc.example .firebaserc     # AJUSTE os ids para projetos que existem
firebase use --add                     # confirme o alias default

# No plano Spark (grátis) deploye SOMENTE o Firestore:
firebase deploy --only firestore:rules,firestore:indexes

# Storage e Functions exigem plano Blaze. Só depois de ativá-lo:
cd functions && npm install && npm run build && cd ..
# firebase deploy --only storage,functions
```

No console do Firebase, habilite **Authentication → Sign-in method →
E-mail/senha** e desligue o cadastro aberto (a admissão é controlada pela
Cloud Function `gateSignUp`).

## 4. Requisitos nativos

**Android** — `android/app/build.gradle.kts` (ou `.gradle`):

```kotlin
defaultConfig {
    applicationId = "com.elytronsecurity.dash2board"
    minSdk = 23          // exigido por firebase_auth
    targetSdk = flutter.targetSdkVersion
}
```

**iOS** — `ios/Podfile`:

```ruby
platform :ios, '13.0'
```

```bash
cd ios && pod install && cd ..
```

## 5. Criar o primeiro usuário de cada persona

Com os emuladores ou já no projeto de desenvolvimento:

```bash
# 1) crie o convite (Console do Firestore ou script admin)
#    /invites/ciso@cliente.com
#      tenantId: "tenant-demo"
#      role:     "strategic"
#      tenantAdmin: true

# 2) crie a conta no Authentication com o mesmo e-mail
# 3) chame a callable claimInvite no primeiro login
```

Repita com `role: "operational"` e `role: "board"` para validar o roteamento
das três personas.

## 6. Comandos do dia a dia

```bash
flutter analyze                      # precisa dar "No issues found!"
flutter test                         # testes unitários e de widget
dart format lib test                 # formatação
flutter run --dart-define=ENV=dev
firebase emulators:start             # Auth + Firestore + Functions + UI
```

## 7. Extensões recomendadas no VSCode

Já declaradas em `.vscode/extensions.json`: Dart, Flutter, vsfire (syntax das
security rules), Prettier, Error Lens e Better Comments. O VSCode oferece a
instalação ao abrir a pasta.
