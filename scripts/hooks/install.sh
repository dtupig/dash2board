#!/usr/bin/env bash
# Instala os hooks locais neste clone. Hooks não são versionados pelo git,
# então cada desenvolvedor roda isto uma vez.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOOKS="$(git -C "$ROOT" rev-parse --git-path hooks)"
cd "$ROOT"

for h in pre-push; do
  cp "scripts/hooks/$h" "$HOOKS/$h"
  chmod +x "$HOOKS/$h"
  echo "  instalado: $h"
done

cat > "$HOOKS/pre-commit" <<'EOF'
#!/usr/bin/env bash
if command -v dart >/dev/null 2>&1; then
  if ! dart format --output=none --set-exit-if-changed lib test >/dev/null 2>&1; then
    echo ""
    echo "Formatação pendente. Rode: dart format lib test"
    echo "Para ignorar: git commit --no-verify"
    exit 1
  fi
fi
EOF
chmod +x "$HOOKS/pre-commit"
echo "  instalado: pre-commit"
echo ""
echo "Hooks ativos em $HOOKS"
echo "Para desinstalar: rm $HOOKS/pre-push $HOOKS/pre-commit"
