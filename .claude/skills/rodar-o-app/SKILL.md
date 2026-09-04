---
name: rodar-o-app
description: Levantar o Dash2Board no simulador iOS a partir de um clone limpo. Use quando pedirem para rodar, iniciar, abrir ou tirar screenshot do app, ou para confirmar visualmente uma mudança no app real. Cobre o bloqueio do GoogleService-Info.plist que faz o primeiro build falhar.
---

# Rodar o Dash2Board no simulador

Verificado em 03/09/2026 · Flutter 3.47.1 · CocoaPods 1.17.0 · iOS 26.5.

## O bloqueio: clone limpo NÃO compila

`.gitignore` ignora `ios/Runner/GoogleService-Info.plist`, mas o
`ios/Runner.xcodeproj/project.pbxproj` — que **é** versionado — exige esse
arquivo como input da fase de Resources. O primeiro build morre assim, depois
de ~11 minutos:

```
Error (Xcode): Build input file cannot be found:
'…/ios/Runner/GoogleService-Info.plist'
Command Ld failed with a nonzero exit code
```

`--dart-define=MOCK=true` **não** contorna: a exigência é do Xcode em tempo de
build, não do Dart em runtime. A CI não pega porque nenhum dos 3 jobs roda
`flutter build`.

## Sequência

```bash
cd /caminho/para/dash2board

# 1. flutterfire_cli — não vem com o Flutter
dart pub global activate flutterfire_cli
export PATH="$PATH:$HOME/.pub-cache/bin"

# 2. gerar a config nativa (exige `firebase login` válido)
flutterfire configure --project=elytron-d2b-dev --platforms=ios,android --yes

# 3. simulador: use um já iniciado, ou boote um
xcrun simctl list devices available | grep iPhone
xcrun simctl boot <UDID>          # pule se já estiver "(Booted)"
open -a Simulator

# 4. rodar
flutter pub get
flutter run -d <UDID> --dart-define=ENV=dev --dart-define=MOCK=true
```

Confirme o sucesso pela linha `Flutter run key commands.` seguida de
`A Dart VM Service on iPhone … is available at:`.

## Tempos esperados

| Etapa | Primeira vez | Depois |
|---|---|---|
| `pod install` | ~50 s | pulado |
| Build Xcode | ~11 min | ~45 s |

Se o build Xcode passar de 15 min, quase sempre é **disco cheio** — veja
Problemas conhecidos.

## Contas de demonstração (MOCK=true)

`operacao@demo.elytron` · `ciso@demo.elytron` · `board@demo.elytron` —
senha com 12+ caracteres. A tela de boas-vindas roteia por persona.

## Screenshot

```bash
xcrun simctl io booted screenshot /tmp/tela.png
```

## O que a sequência suja no git

Nada disso é trabalho perdido, mas **confira antes de commitar**:

| Arquivo | Origem |
|---|---|
| `ios/Runner/GoogleService-Info.plist`, `android/app/google-services.json` | gerados, mas **podem** ser commitados (decisão do PO em 03/09/2026 — chave de cliente Firebase, não segredo) |
| `ios/Podfile`, `ios/Podfile.lock` | gerados e versionados normalmente — confira se o `pod install` não regrediu a versão de algum pod da família Firebase (ver Dívida item 2, abaixo) |
| `firebase.json` | reescrito pelo `flutterfire configure` |
| `lib/firebase_options.dart` | reescrito (costuma ser só espaçamento) |
| `ios/Flutter/{Debug,Release}.xcconfig`, `project.pbxproj`, `contents.xcworkspacedata` | reescritos pelo `pod install` |
| `ios/**/xcshareddata/swiftpm/Package.resolved` | **deletados** — o `pod install` migra de SwiftPM para CocoaPods |

Rode `git status` e descarte o que não quiser antes de abrir PR.

## Problemas conhecidos

**Disco cheio quebra o build de formas confusas.** O runtime do simulador vive
num volume próprio e o Xcode escreve GBs em `DerivedData`. Para recuperar
espaço rápido (nesta ordem, tudo regenerável):

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/*    # costuma ser o maior
rm -rf ~/Library/Caches/Homebrew/*
xcrun simctl shutdown all && xcrun simctl erase all   # apaga dados dos apps
rm -rf build/
```

**Nunca** apague `/Library/Developer/CoreSimulator/Volumes/iOS_*` — é o runtime
do simulador em uso, não cache.

**Toque programático no simulador não funciona sem permissão.** `osascript`
com `System Events` falha com erro `-25204` se o processo que roda o Claude
Code não tiver Acessibilidade concedida em Ajustes do Sistema → Privacidade e
Segurança → Acessibilidade. Sem isso, dá para buildar, lançar e tirar
screenshot, mas não navegar — peça ao usuário para tocar, ou peça a permissão.

## Dívida que este skill contornava — resolvida em 04/09/2026

O contorno do bloqueio do `GoogleService-Info.plist` ainda existe (é uma
exigência do Xcode em tempo de build), mas as três correções de raiz que
esta seção listava como pendentes já foram feitas:

1. ~~Decidir a política da config nativa~~ — resolvido em 03/09/2026:
   `GoogleService-Info.plist` e `google-services.json` passaram a ser
   versionados, mesma postura de `lib/firebase_options.dart` (chave de
   cliente Firebase, não segredo).
2. ~~Adicionar à CI um job `flutter build ios --simulator --no-codesign`~~ —
   resolvido em 04/09/2026 (`build-ios` em `.github/workflows/ci.yaml`,
   junto com `build-android`). Ao implementar, esse job pegou um bug real:
   a família de pacotes Firebase (`firebase_core`/`firebase_auth`/
   `cloud_firestore`/`cloud_functions`) estava com versões defasadas e
   mutuamente incompatíveis - `ios/Podfile.lock` travado numa versão de
   `Firebase/CoreOnly` que o `firebase_core` resolvido não aceitava mais.
   Detalhe em `docs/20_RETOMADA_SESSAO.md`, seção Ambiente. **Lição para a
   próxima vez que isso quebrar:** `flutter pub get` não avança versão
   sozinho mesmo com constraint `^` permissiva — só `flutter pub upgrade`
   faz isso, e os quatro pacotes Firebase precisam subir **juntos** (são
   lançados como família; um sozinho na versão nova causa conflito de
   símbolo Swift/ObjC no build iOS).
3. ~~Versionar `ios/Podfile`~~ — resolvido em 03/09/2026, junto com o item 1.

## Dívida que este skill ainda contorna

O contorno do `GoogleService-Info.plist` (seção "O bloqueio", acima)
continua necessário numa máquina nova — é o Xcode exigindo o arquivo em
tempo de build, `--dart-define` não ajuda. Não é algo que dê para resolver
sem mudar a exigência do `project.pbxproj`, e não há indício de que valha a
pena mudar isso.
