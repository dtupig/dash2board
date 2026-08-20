#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# Fase C2 — flutterfire configure + registro das 9 decisões confirmadas
#
#   ./scripts/fase-c2-flutterfire.sh [project-id]
#
#   Sem argumento, usa elytron-d2b-dev (docs/17_PONTO_DE_RETOMADA.md).
#
# O que faz, nesta ordem, parando no primeiro erro:
#   1. Confere pré-requisitos (git limpo, flutter/dart/firebase/flutterfire/gh)
#   2. Sincroniza main e cria o branch chore/fase-c2-flutterfire-configure
#   3. Insere em docs/13_DECISOES_PENDENTES.md a tabela "Confirmado em
#      19/08/2026" com D-30, D-29, D-18, D-05, D-06, D-07, D-12, D-13, D-27
#      — só escreve se achar a âncora exatamente uma vez; senão, para e não
#      toca no arquivo
#   4. Roda `flutterfire configure --project=<id>` (interativo)
#   5. Confere o portão da Fase C2 (docs/16): firebase_options.dart sem
#      PLACEHOLDER
#   6. Delega para ./scripts/prompt ship — que formata, analisa, testa,
#      audita, comita, publica, abre PR, espera a CI e faz o merge
#
# Nunca comita nem publica sozinho: quem faz isso é o `ship`, e só depois que
# todos os portões passarem.
# ---------------------------------------------------------------------------
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"; cd "$ROOT"

PROJECT_ID="${1:-elytron-d2b-dev}"
BRANCH="chore/fase-c2-flutterfire-configure"
DECISOES="docs/13_DECISOES_PENDENTES.md"
OPTIONS_FILE="lib/firebase_options.dart"
DATA_HOJE="19/08/2026"

G='\033[0;32m'; R='\033[0;31m'; Y='\033[0;33m'; C='\033[0;36m'; B='\033[1m'; N='\033[0m'
ok(){  printf "  ${G}✓${N} %s\n" "$1"; }
er(){  printf "  ${R}✗${N} %s\n" "$1"; }
wr(){  printf "  ${Y}!${N} %s\n" "$1"; }
st(){  printf "\n${B}› %s${N}\n" "$1"; }
run(){ printf "    ${C}\$ %s${N}\n" "$*"; "$@"; }
die(){ printf "\n${R}✗ %s${N}\n\n" "$1"; exit 1; }

# ---------------------------------------------------------------------------
st "1/6 · Pré-requisitos"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || die "não é um repositório git — rode a partir da raiz do dash2board"

for tool in flutter dart firebase gh; do
  command -v "$tool" >/dev/null 2>&1 || die "'$tool' não encontrado no PATH"
done
ok "flutter, dart, firebase, gh no PATH"

dart pub global list 2>/dev/null | grep -q flutterfire_cli \
  || die "flutterfire_cli não ativado — rode: dart pub global activate flutterfire_cli"
command -v flutterfire >/dev/null 2>&1 \
  || die "'flutterfire' não encontrado no PATH (confira o PATH do pub global: dart pub global list)"
ok "flutterfire_cli disponível"

[ -f "$DECISOES" ] || die "não achei $DECISOES — rode a partir da raiz do repositório"

[ -z "$(git status --porcelain)" ] || {
  printf "\n"; git status --short | sed 's/^/    /'
  die "há mudanças não commitadas. Faça commit, stash ou descarte antes."
}
ok "árvore de trabalho limpa"

# ---------------------------------------------------------------------------
st "2/6 · Branch"

run git switch main || die "não consegui trocar para main"
run git pull --ff-only || wr "pull não avançou (siga se o main já está atualizado)"

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
  wr "branch $BRANCH já existe — retomando"
  run git switch "$BRANCH" || die "não consegui trocar para $BRANCH"
else
  run git switch -c "$BRANCH" || die "não consegui criar $BRANCH"
fi

# ---------------------------------------------------------------------------
st "3/6 · Registrando as 9 decisões em $DECISOES"

python3 - "$DECISOES" "$DATA_HOJE" <<'PYEOF' || die "edição do $DECISOES abortada — arquivo NÃO foi tocado"
import sys

path, hoje = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as f:
    text = f.read()

anchor = (
    "| D-04 | Modelo da 4ª persona | Dimensão separada (`PrincipalKind` "
    "+ `StaffRole` + tenants atribuídos) |"
)
count = text.count(anchor)
if count != 1:
    print(f"ANCORA encontrada {count} vez(es), esperado 1 — arquivo mudou desde a "
          f"última leitura. Edite manualmente.", file=sys.stderr)
    sys.exit(1)

bloco = f"""

## Confirmado em {hoje}

Decisões tomadas em sessão de arquitetura para destravar os prompts 10, 13 e
14, e as pré-condições dos prompts 11 e 12 (a implementação técnica de cada
prompt ainda segue seu próprio portão em `docs/16_PLANO_DE_RETOMADA.md`).

| # | Decisão | Valor confirmado |
|---|---|---|
| D-30 | SLA de resposta a RFS | Crise 2h · urgente 1 dia útil · planejado 5 dias úteis |
| D-29 | Limite de fato relevante | 25% da receita do cliente, por tenant, sem teto adicional |
| D-18 | Um build ou dois flavors | Dois flavors: `client` (lojas públicas) e `staff` (distribuição interna) |
| D-05 | App guarda evidência ou só o registro de custódia | Só o registro de custódia + ponteiro para o cofre forense |
| D-06 | Prazos de retenção da custódia | `CustodyRecord` 10 anos · evidência no cofre 12 meses pós-contrato |
| D-07 | Como aplicar o prazo de custódia | `retentionUntil` + `legalHold` por registro — nunca TTL global |
| D-12 | Plano de faturamento | Blaze, com alerta de orçamento (modelo: R$50, gatilhos 50%/90%) |
| D-13 | Retenção de `audit_logs` | 5 anos |
| D-27 | Validar os 8 modelos de relatório com as disciplinas | **Escopo definido, validação ainda pendente de agendar:** reunião de 1h com pentest, forense, GRC, AppSec lead e SOC/Threat Intel lead |
"""

text = text.replace(anchor, anchor + bloco, 1)
with open(path, "w", encoding="utf-8") as f:
    f.write(text)
print("OK: bloco inserido.")
PYEOF

ok "docs/13 atualizado"
git --no-pager diff --stat -- "$DECISOES" | sed 's/^/    /'

# ---------------------------------------------------------------------------
st "4/6 · flutterfire configure --project=$PROJECT_ID"

wr "comando interativo — escolha as plataformas e confirme o app do projeto $PROJECT_ID"
run flutterfire configure --project="$PROJECT_ID" \
  || die "flutterfire configure falhou — confira 'firebase login' e 'firebase projects:list'"

# ---------------------------------------------------------------------------
st "5/6 · Portão da Fase C2 (docs/16): firebase_options.dart sem PLACEHOLDER"

[ -f "$OPTIONS_FILE" ] || die "$OPTIONS_FILE não foi gerado — o flutterfire configure não completou"
if grep -qi "PLACEHOLDER" "$OPTIONS_FILE"; then
  er "$OPTIONS_FILE ainda contém PLACEHOLDER"
  die "portão C2 reprovado — rode o flutterfire configure de novo apontando para o app certo"
fi
ok "$OPTIONS_FILE sem PLACEHOLDER"

# ---------------------------------------------------------------------------
st "6/6 · Portões de qualidade, commit, PR e merge (./scripts/prompt ship)"

MSG="chore(firebase): configurar projeto real via flutterfire e registrar decisões D-05/06/07/12/13/18/27/29/30"
run ./scripts/prompt ship "$MSG" || die "ship reprovou — corrija o apontado acima e rode de novo"

printf "\n${G}Fase C2 concluída.${N} Próximo passo: Fase C3 — "
printf "flutter run --dart-define=DATA_SOURCE=firestore (com os emuladores + seed).\n\n"
