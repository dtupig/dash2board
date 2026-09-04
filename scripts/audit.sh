#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Laudo de execução — complementa docs/14_AUDITORIA_QUALIDADE.md
# Roda no macOS, onde vivem Flutter, Xcode e Firebase CLI.
#
#   chmod +x scripts/audit.sh && ./scripts/audit.sh
#
# Não altera nada. Só coleta evidência em audit-report.txt.
# ---------------------------------------------------------------------------
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"
OUT="$ROOT/audit-report.txt"; : > "$OUT"
FAIL=0

log()  { printf '%s\n' "$*" | tee -a "$OUT" >/dev/null; }
head1(){ log ""; log "=============================================================="; log "$*"; log "=============================================================="; }
ok()   { printf '  \033[0;32m[OK]\033[0m   %s\n' "$1"; log "  [OK]   $1"; }
bad()  { printf '  \033[0;31m[FALHA]\033[0m %s\n' "$1"; log "  [FALHA] $1"; FAIL=$((FAIL+1)); }
warn() { printf '  \033[0;33m[ATEN]\033[0m %s\n' "$1"; log "  [ATEN] $1"; }

log "Laudo de execução - Elytron Dash2Board"
log "Data: $(date '+%Y-%m-%d %H:%M:%S %Z')"
log "Host: $(uname -srm)"

# --------------------------------------------------------------------------
head1 "1. CADEIA DE FERRAMENTAS"
for t in flutter dart node npm firebase gcloud git xcodebuild pod; do
  if command -v "$t" >/dev/null 2>&1; then
    v="$("$t" --version 2>/dev/null | head -1)"; ok "$t ${v:-presente}"
  else
    if [ "$t" = "gcloud" ] || [ "$t" = "pod" ]; then warn "$t ausente (necessário para backup/iOS)"
    else bad "$t ausente"; fi
  fi
done

head1 "2. FLUTTER DOCTOR"
flutter doctor -v 2>&1 | tee -a "$OUT" | sed 's/^/  /' | head -40

# --------------------------------------------------------------------------
head1 "3. CONTROLE DE VERSÃO  (achado C-01)"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  ok "repositório git ativo — $(git rev-list --count HEAD 2>/dev/null || echo 0) commit(s)"
  d=$(git status --porcelain | wc -l | tr -d ' '); [ "$d" -eq 0 ] && ok "árvore limpa" || warn "$d arquivo(s) não commitado(s)"
else
  bad "SEM git — achado CRÍTICO C-01 não corrigido. Rode: git init && git add -A && git commit -m 'estado inicial'"
fi

# --------------------------------------------------------------------------
head1 "4. ANÁLISE ESTÁTICA"
if flutter analyze 2>&1 | tee -a "$OUT" | tail -5 | grep -q "No issues found"; then
  ok "flutter analyze — No issues found!"
else
  bad "flutter analyze apontou problemas (veja $OUT)"
fi

head1 "5. TESTES"
if flutter test 2>&1 | tee -a "$OUT" | tail -20 | grep -qE "All tests passed"; then
  ok "flutter test — todos passaram"
else
  bad "flutter test falhou (veja $OUT)"
fi

if [ -d test/rules ]; then
  ok "test/rules existe"
else
  bad "test/rules AUSENTE — achado A-02: security rules sem teste automatizado"
fi

# --------------------------------------------------------------------------
head1 "6. CONFORMIDADE DE CÓDIGO"
check_absent() { # padrão, rótulo
  # `grep -rn` prefixa "arquivo:linha:" antes do conteúdo - por isso o
  # filtro de comentário precisa remover esse prefixo antes de ancorar
  # `^\s*//` no início da linha de código real, senão a âncora nunca bate.
  n=$(grep -rn --include='*.dart' -F "$1" lib test 2>/dev/null \
      | sed -E 's/^[^:]*:[0-9]+://' \
      | grep -vE '^\s*(//|///)' \
      | wc -l | tr -d ' ')
  [ "$n" -eq 0 ] && ok "$2: 0 ocorrência" || bad "$2: $n ocorrência(s)"
}
check_absent "withOpacity"        "Color.withOpacity"
check_absent "MaterialState"      "MaterialState*"
check_absent "surfaceVariant"     "ColorScheme.surfaceVariant"
check_absent "onBackground"       "ColorScheme.onBackground"
check_absent "StateNotifier"      "StateNotifier"
check_absent "AutoDispose"        "AutoDispose*Notifier"
check_absent "CardTheme("         "CardTheme( em ThemeData"
check_absent "DialogTheme("       "DialogTheme( em ThemeData"
check_absent "TabBarTheme("       "TabBarTheme( em ThemeData"
check_absent "pageTransitionsTheme" "pageTransitionsTheme"
n=$(grep -rEn --include='*.dart' "(^|[^\.[:alnum:]_])[Cc]olorScheme\.background\b" lib test 2>/dev/null \
    | sed -E 's/^[^:]*:[0-9]+://' | grep -vE '^\s*(//|///)' | wc -l | tr -d ' ')
[ "$n" -eq 0 ] && ok "ColorScheme.background: 0 ocorrência" || bad "ColorScheme.background: $n ocorrência(s)"
n=$(grep -rn --include='*.dart' "pumpAndSettle(" test 2>/dev/null | wc -l | tr -d ' ')
[ "$n" -eq 0 ] && ok "pumpAndSettle(): 0 chamada" || bad "pumpAndSettle(): $n chamada(s) — animação contínua trava o teste"
n=$(grep -rn "brandGreen\|brandCyan\|brandViolet" lib/core/widgets/charts/ 2>/dev/null | wc -l | tr -d ' ')
[ "$n" -eq 0 ] && ok "acento de marca fora dos gráficos" || bad "$n uso(s) de acento de marca em gráfico"

# Fronteiras de arquitetura (CLAUDE.md): domain/ é Dart puro; presentation/
# nunca fala com o Firebase diretamente.
n=$(grep -rlE "^import 'package:flutter|^import 'package:firebase|^import 'package:cloud_" \
    --include='*.dart' lib 2>/dev/null | grep '/domain/' | wc -l | tr -d ' ')
[ "$n" -eq 0 ] && ok "domain/ sem import de Flutter/Firebase" || bad "domain/ importando Flutter/Firebase em $n arquivo(s)"
n=$(grep -rlE "^import 'package:(cloud_firestore|firebase_auth)" \
    --include='*.dart' lib 2>/dev/null | grep '/presentation/' | wc -l | tr -d ' ')
[ "$n" -eq 0 ] && ok "presentation/ sem cloud_firestore/firebase_auth" || bad "presentation/ importando Firebase em $n arquivo(s)"

# Limite de 250 linhas por arquivo (regra 10).
over="$(find lib -name '*.dart' -exec wc -l {} \; 2>/dev/null | awk '$1>250 {print}' | sort -rn)"
n=$(printf '%s' "$over" | grep -c . || true)
if [ -z "$over" ]; then
  ok "nenhum arquivo .dart acima de 250 linhas"
else
  bad "$n arquivo(s) .dart acima de 250 linhas"
  printf '%s\n' "$over" | sed 's/^/         /' | tee -a "$OUT" >/dev/null
fi

# --------------------------------------------------------------------------
head1 "7. CONFIGURAÇÃO FIREBASE"
if grep -q "PLACEHOLDER" lib/firebase_options.dart 2>/dev/null; then
  bad "firebase_options.dart ainda é placeholder — achado A-03; rode flutterfire configure"
else
  ok "firebase_options.dart gerado"
fi
if [ -f .firebaserc ]; then
  def=$(python3 -c "import json;print(json.load(open('.firebaserc'))['projects'].get('default','')) " 2>/dev/null)
  log "  alias default -> ${def:-<vazio>}"
  if ! command -v firebase >/dev/null 2>&1; then
    warn "firebase CLI ausente: nao deu para verificar '$def'"
  else
    # `firebase projects:list` depende de rede e de sessao valida. Uma falha
    # aqui nao e defeito do repositorio, entao e ATENCAO e nao FALHA.
    plist="$(firebase projects:list 2>/dev/null)"
    if [ -z "$plist" ]; then
      warn "nao consegui listar projetos (rede ou sessao) — verifique com: firebase projects:list"
    elif printf '%s' "$plist" | grep -q "$def"; then
      ok "projeto '$def' acessivel na sua conta"
    else
      bad "projeto '$def' NAO existe na sua conta — achado A-01"
    fi
  fi
else
  bad ".firebaserc ausente"
fi
for f in firestore.rules firestore.indexes.json storage.rules; do
  [ -f "$f" ] && ok "$f presente" || bad "$f ausente"
done
idx=$(python3 -c "import json;print(len(json.load(open('firestore.indexes.json'))['indexes']))" 2>/dev/null || echo 0)
log "  índices compostos declarados: $idx"
[ "$idx" -ge 11 ] && warn "confira se cobrem as consultas novas (achado A-04)"

# --------------------------------------------------------------------------
head1 "8. HIGIENE"
[ -f pubspec.lock ] && ok "pubspec.lock presente" || bad "pubspec.lock ausente"
[ -f CLAUDE.md ] && ok "CLAUDE.md presente" || warn "CLAUDE.md ausente — achado M-02"
[ -d .github/workflows ] && ok "CI configurada" || warn "sem CI — achado M-01"
t=$(grep -rn --include='*.dart' -E "TODO|FIXME" lib 2>/dev/null | wc -l | tr -d ' '); log "  TODO/FIXME em lib/: $t"

# --------------------------------------------------------------------------
head1 "RESULTADO"
if [ "$FAIL" -eq 0 ]; then
  printf '\n\033[0;32m  APROVADO — nenhuma falha bloqueante\033[0m\n'; log "  APROVADO"
else
  printf '\n\033[0;31m  %s FALHA(S) — veja %s\033[0m\n' "$FAIL" "$OUT"; log "  $FAIL FALHA(S)"
fi
printf '  Laudo completo: %s\n\n' "$OUT"
exit 0
