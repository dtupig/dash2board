# Tracker — simulador Android local, passo a passo

Guia para levar esta máquina do estado atual (`flutter doctor` reprova o
Android toolchain) até rodar o Dash2Board num emulador Android, no mesmo
nível de validação que `.claude/skills/rodar-o-app/SKILL.md` já confirma
para o simulador iOS. É trabalho de **máquina de desenvolvedor**, não de
CI — o job `build-android` da CI só compila (`flutter build apk --debug`),
não precisa de emulador nenhum.

Estado verificado em 04/09/2026 (Apple Silicon, macOS 26.6.2):

```
[✗] Android toolchain - develop for Android devices
    ✗ ANDROID_HOME = /Users/danieltupinamba/Library/Android/sdk
      but Android SDK not found at this location.
```

Nenhum Android Studio instalado, nenhum SDK em disco. `openjdk@17` **já**
está disponível via Homebrew (`brew --prefix openjdk@17`) — satisfaz o
`JavaVersion.VERSION_17` que `android/app/build.gradle.kts` exige, então
não é preciso instalar Java separadamente.

## Decisão: cmdline-tools em vez de Android Studio completo

Duas opções via Homebrew: `android-studio` (IDE completa, GB de download,
inclui SDK Manager gráfico) ou `android-commandlinetools` (só as
ferramentas de linha de comando — `sdkmanager`, `avdmanager`). Como o fluxo
aqui é só "ter um emulador rodando para o Flutter", `android-commandlinetools`
é o caminho mais rápido e o que mantém paridade com o estilo do resto do
projeto (scriptável, sem depender de clicar em GUI) — mesmo espírito do
fluxo iOS via `xcrun simctl`, que também não abre o Xcode para nada além do
build.

Se no futuro alguém preferir depurar com breakpoints nativos Kotlin/Java, a
IDE completa passa a valer a pena; não é o caso hoje.

## Passo a passo

```bash
# 1. Ferramentas de linha de comando do SDK
brew install --cask android-commandlinetools

# 2. Descobrir onde o Homebrew instalou (varia por versão do cask)
brew --prefix android-commandlinetools
# normalmente /opt/homebrew/share/android-commandlinetools em Apple Silicon

# 3. Apontar as variáveis de ambiente (substitua no ~/.zshrc para persistir -
# o ANDROID_HOME atual, ~/Library/Android/sdk, está setado mas vazio/errado)
export ANDROID_HOME="$(brew --prefix android-commandlinetools)"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"

# 4. Aceitar as licenças do SDK (prompt interativo por licença - responda "y")
sdkmanager --licenses

# 5. Instalar os pacotes necessários. android-34 é a platform mais recente
# testada pelo projeto (compileSdk/targetSdk vêm de flutter.*Version, que
# hoje resolve para essa faixa) - confira com `flutter doctor -v` se a
# versão exigida mudou. arm64 porque é Apple Silicon.
sdkmanager "platform-tools" \
           "platforms;android-34" \
           "build-tools;34.0.0" \
           "emulator" \
           "system-images;android-34;google_apis;arm64"

# 6. Criar o AVD (Android Virtual Device) - só uma vez
avdmanager create avd \
  -n pixel_8_api_34 \
  -k "system-images;android-34;google_apis;arm64" \
  -d pixel_8

# 7. Bootar o emulador (deixe rodando numa aba separada)
emulator -avd pixel_8_api_34
```

## Confirmar

```bash
flutter doctor          # Android toolchain deve virar [✓]
flutter devices         # deve listar o emulador como "android"
```

Rodar o app, mesmo padrão do skill do iOS:

```bash
flutter pub get
flutter run -d emulator-5554 --dart-define=ENV=dev --dart-define=MOCK=true
```

Confirme o sucesso pela mesma linha usada no iOS: `Flutter run key
commands.` seguida de `A Dart VM Service on ... is available at:`.

## Tempos esperados

| Etapa | Tempo aproximado |
|---|---|
| `brew install --cask android-commandlinetools` | ~1 min |
| `sdkmanager` (platform-tools + platform + build-tools + emulator + system-image) | 10–20 min, depende da conexão (system-image sozinha tem ~1 GB) |
| Boot do emulador (primeira vez) | 1–3 min |
| Boot do emulador (depois) | ~30 s |
| `flutter run` (primeiro build Gradle) | alguns minutos (baixa dependências Gradle) |

## Problemas conhecidos (a confirmar quando alguém rodar de fato)

Esta seção parte do que se sabe do ecossistema Android/Homebrew em geral -
**ainda não foi validado rodando neste projeto**, diferente do skill do
iOS, que documenta problemas já enfrentados de verdade. Atualize com o que
acontecer na primeira execução real.

- **Emulador lento ou não usando aceleração de hardware**: em Apple
  Silicon, confirme que a system-image escolhida é `arm64` (não `x86_64`) -
  emulação x86 num Mac ARM roda via tradução e é sensivelmente mais lenta.
- **`sdkmanager --licenses` não aceita `y` automaticamente em script não
  interativo**: se for automatizar (ex.: script de setup), use `yes |
  sdkmanager --licenses` em vez de aceitar manualmente.
- **`ANDROID_HOME` antigo (`~/Library/Android/sdk`) conflitando**: se
  alguma ferramenta ainda ler essa variável de um `.zshrc`/`.zprofile`
  antigo, o `flutter doctor` volta a reprovar. Confirme com `echo
  $ANDROID_HOME` depois de abrir um terminal novo.
