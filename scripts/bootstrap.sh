#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Elytron Dash2Board - bootstrap do ambiente local (macOS + VSCode)
#
# Este repositório contém a camada de PRODUTO (lib/, docs/, regras do Firebase).
# As pastas nativas (android/, ios/) são geradas aqui pelo próprio Flutter, para
# que fiquem exatamente na versão do SDK instalado na sua máquina.
#
# Uso:
#   chmod +x scripts/bootstrap.sh
#   ./scripts/bootstrap.sh
# ---------------------------------------------------------------------------
set -euo pipefail

PROJECT_NAME="elytron_dash2board"
ORG="com.elytronsecurity"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

say() { printf '\n\033[1;32m==> %s\033[0m\n' "$1"; }
warn() { printf '\n\033[1;33m[!] %s\033[0m\n' "$1"; }

# ---------------------------------------------------------------------------
say "Verificando o Flutter"
if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter não encontrado no PATH. Instale via https://docs.flutter.dev/get-started/install/macos"
  exit 1
fi
flutter --version

# ---------------------------------------------------------------------------
say "Gerando as pastas nativas iOS/Android"
rm -rf _scaffold
flutter create \
  --org "$ORG" \
  --project-name "$PROJECT_NAME" \
  --platforms=ios,android \
  --description "Elytron Dash2Board" \
  _scaffold >/dev/null

for item in android ios .metadata; do
  if [ ! -e "$item" ]; then
    cp -R "_scaffold/$item" "./$item"
    echo "  + $item"
  else
    echo "  = $item já existe (mantido)"
  fi
done
rm -rf _scaffold

# ---------------------------------------------------------------------------
say "Resolvendo e fixando as versões das dependências"
flutter pub add \
  firebase_core \
  firebase_auth \
  cloud_firestore \
  flutter_riverpod \
  go_router \
  intl \
  shared_preferences

flutter pub add --dev flutter_lints

flutter pub get

# ---------------------------------------------------------------------------
say "Análise estática (precisa terminar com 'No issues found!')"
flutter analyze || warn "Corrija os apontamentos acima antes de seguir."

# ---------------------------------------------------------------------------
say "Próximos passos manuais"
cat <<'STEPS'

1) Firebase
   dart pub global activate flutterfire_cli
   flutterfire configure \
     --project=<SEU_PROJETO> \
     --platforms=ios,android \
     --ios-bundle-id=com.elytronsecurity.dash2board \
     --android-package-name=com.elytronsecurity.dash2board

   cp .firebaserc.example .firebaserc   # e ajuste os ids de projeto
   firebase deploy --only firestore:rules,firestore:indexes,storage

2) Requisitos nativos do Firebase
   - Android: minSdk >= 23 em android/app/build.gradle(.kts)
   - iOS:     platform :ios, '13.0' em ios/Podfile
              cd ios && pod install

3) Rodar
   flutter run --dart-define=ENV=dev
   flutter run --dart-define=ENV=dev --dart-define=ENABLE_SSO=true

4) Emuladores (opcional, recomendado)
   firebase emulators:start

STEPS
