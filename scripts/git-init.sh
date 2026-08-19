#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Inicialização segura do repositório — corrige o achado C-01 da auditoria.
#
#   chmod +x scripts/git-init.sh && ./scripts/git-init.sh
#
# O script é conservador: faz backup, valida ANTES de comitar, e para em
# qualquer inconsistência. Não sobe nada para o GitHub — isso é o passo 6,
# manual e consciente.
# ---------------------------------------------------------------------------
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"

G='\033[0;32m'; R='\033[0;31m'; Y='\033[0;33m'; B='\033[1m'; N='\033[0m'
ok(){ printf "  ${G}✓${N} %s\n" "$1"; }
er(){ printf "  ${R}✗${N} %s\n" "$1"; }
wr(){ printf "  ${Y}!${N} %s\n" "$1"; }
st(){ printf "\n${B}==> %s${N}\n" "$1"; }
die(){ er "$1"; printf "\n${R}Abortado. Nada foi alterado de forma irreversível.${N}\n\n"; exit 1; }

# ---------------------------------------------------------------------------
st "1/7  Pré-requisitos"
command -v git >/dev/null || die "git não encontrado"
ok "git $(git --version | awk '{print $3}')"

if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  wr "já existe um repositório git aqui"
  printf "      commits: %s | pendências: %s\n" \
    "$(git rev-list --count HEAD 2>/dev/null || echo 0)" \
    "$(git status --porcelain | wc -l | tr -d ' ')"
  read -r -p "      Continuar e apenas validar/comitar o que falta? [s/N] " a
  [[ "$a" =~ ^[SsYy]$ ]] || die "cancelado pelo usuário"
  EXISTING=1
else
  EXISTING=0
fi

# ---------------------------------------------------------------------------
st "2/7  Backup antes de tocar em qualquer coisa"
BK="$HOME/Backups/elytron_dash2board-$(date +%Y%m%d-%H%M%S).tar.gz"
mkdir -p "$(dirname "$BK")"
tar --exclude='./build' --exclude='./.dart_tool' --exclude='*/node_modules' \
    --exclude='./ios/Pods' --exclude='./.git' \
    -czf "$BK" . 2>/dev/null || true
if [ -s "$BK" ]; then ok "backup: $BK ($(du -h "$BK" | cut -f1))"
else die "backup falhou — não prossiga sem cópia de segurança"; fi

# ---------------------------------------------------------------------------
st "3/7  Identidade do autor"
NAME="$(git config --get user.name  || true)"
MAIL="$(git config --get user.email || true)"
if [ -z "$NAME" ] || [ -z "$MAIL" ]; then
  wr "identidade global não configurada"
  read -r -p "      Seu nome: " NAME
  read -r -p "      Seu e-mail: " MAIL
  [ -n "$NAME" ] && [ -n "$MAIL" ] || die "nome e e-mail são obrigatórios"
  git config --global user.name  "$NAME"
  git config --global user.email "$MAIL"
fi
ok "autor: $NAME <$MAIL>"
git config --global init.defaultBranch main >/dev/null 2>&1
git config --global pull.rebase true       >/dev/null 2>&1

# ---------------------------------------------------------------------------
st "4/7  Inicializar e preparar"
if [ "$EXISTING" -eq 0 ]; then
  git init -b main >/dev/null || die "git init falhou"
  ok "repositório criado no branch main"
fi
[ -f .gitignore ]     || die ".gitignore ausente — não prossiga"
[ -f .gitattributes ] || wr ".gitattributes ausente"
git add -A >/dev/null || die "git add falhou"
ok "$(git diff --cached --name-only | wc -l | tr -d ' ') arquivo(s) preparado(s)"

# ---------------------------------------------------------------------------
st "5/7  Portões de validação (antes do commit)"
FAIL=0
STAGED="$(git diff --cached --name-only)"

# 5.1 nada de node_modules / build / Pods
for bad in "node_modules/" "^build/" "ios/Pods/" "\.dart_tool/"; do
  n=$(printf '%s\n' "$STAGED" | grep -cE "$bad" || true)
  if [ "$n" -gt 0 ]; then er "$n arquivo(s) de '$bad' preparado(s)"; FAIL=1; else ok "sem $bad"; fi
done

# 5.2 segredos
for f in android/app/google-services.json ios/Runner/GoogleService-Info.plist \
         functions/.env scripts/seed/.env android/key.properties; do
  if printf '%s\n' "$STAGED" | grep -qx "$f"; then er "SEGREDO preparado: $f"; FAIL=1; fi
done
[ "$FAIL" -eq 0 ] && ok "nenhum segredo conhecido preparado"

# 5.3 varredura por conteúdo suspeito
if grep -rIl --exclude-dir=.git -E "BEGIN (RSA |OPENSSH |EC )?PRIVATE KEY|AIza[0-9A-Za-z_-]{35}" \
     $(printf '%s\n' "$STAGED" | tr '\n' ' ') 2>/dev/null | grep -v firebase_options.dart | grep . ; then
  er "possível chave privada ou API key fora de firebase_options.dart"; FAIL=1
else
  ok "varredura de chave privada limpa"
fi

# 5.4 arquivo grande
BIG=$(printf '%s\n' "$STAGED" | while read -r f; do
        [ -f "$f" ] && s=$(wc -c <"$f") && [ "$s" -gt 5000000 ] && echo "$f ($((s/1000000))MB)"
      done)
[ -z "$BIG" ] && ok "nenhum arquivo acima de 5 MB" || { er "arquivos grandes:"; echo "$BIG"; FAIL=1; }

# 5.5 .firebaserc coerente
if [ -f .firebaserc ]; then
  DEF=$(python3 -c "import json;print(json.load(open('.firebaserc'))['projects'].get('default',''))" 2>/dev/null || echo "")
  if command -v firebase >/dev/null 2>&1; then
    if firebase projects:list 2>/dev/null | grep -q "$DEF"; then
      ok ".firebaserc default='$DEF' existe na sua conta"
    else
      wr ".firebaserc default='$DEF' NÃO existe (achado A-01) — corrija com: firebase use --add"
    fi
  else
    wr "firebase CLI ausente: não deu para validar '$DEF'"
  fi
fi

[ "$FAIL" -eq 0 ] || die "portões de validação reprovaram — corrija o .gitignore e rode de novo"

# ---------------------------------------------------------------------------
st "6/7  Commit inicial"
printf "      Resumo do que será comitado:\n"
git diff --cached --stat | tail -3 | sed 's/^/      /'
printf "      Por diretório:\n"
git diff --cached --name-only | awk -F/ '{print ($1=="" ? "." : $1)}' | sort | uniq -c | sort -rn | head -12 | sed 's/^/      /'
read -r -p "      Confirmar commit? [s/N] " a
[[ "$a" =~ ^[SsYy]$ ]] || die "cancelado pelo usuário"

git commit -q -F - <<'MSG'
chore: estado inicial auditado do Elytron Dash2Board

Primeiro commit do projeto, feito após a auditoria de qualidade
(docs/14_AUDITORIA_QUALIDADE.md), corrigindo o achado C-01.

Contém:
- jornada de entrada (splash, boas-vindas, login, roteamento por persona)
- design system dark-first em Material 3 e kit de gráficos validado
- módulo estratégico (postura, compliance, insights, briefing em PDF, survey)
- modo de demonstração sem Firebase (--dart-define=MOCK=true)
- security rules, índices, Cloud Functions e seed determinístico
- documentação, roteiro de prompts e relatório de auditoria

.gitignore corrigido antes do commit para não versionar node_modules
de subprojetos (scripts/seed) nem saídas de build.
MSG
ok "commit $(git rev-parse --short HEAD) criado"
git tag -a v0.1.0-auditado -m "Estado auditado em $(date +%Y-%m-%d)" 2>/dev/null && ok "tag v0.1.0-auditado"

# ---------------------------------------------------------------------------
st "7/7  Próximo passo — GitHub"
cat <<'NEXT'
      O repositório local está pronto. Para publicar:

      1. Crie o repositório PRIVADO em https://github.com/new
         - Nome: elytron-dash2board
         - Visibilidade: Private
         - NÃO marque README, .gitignore nem license (já existem aqui)

      2. Conecte e publique (SSH recomendado):
         git remote add origin git@github.com:dtupig/dash2board.git
         git push -u origin main --follow-tags

      Guia visual das telas do GitHub: docs/15_GIT_E_GITHUB.md
NEXT
printf "\n${G}Concluído.${N} Backup em: %s\n\n" "$BK"
