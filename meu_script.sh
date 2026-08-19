python3 - <<'PATCH'
import re, pathlib

# ---- 1) scripts/prompt: espera o GitHub registrar os check runs -----------
p = pathlib.Path("scripts/prompt"); s = p.read_text()
if "registrando os checks" in s:
    print("prompt: já corrigido")
else:
    espera = '''  # O GitHub leva alguns segundos para registrar os check runs de um PR recem
  # criado. Sem esta espera, `gh pr checks` responde "no checks reported" e
  # sai com erro - o que parecia reprovacao da CI, mas era corrida.
  local waited=0
  while gh pr checks 2>&1 | grep -q "no checks reported"; do
    waited=$((waited + 3))
    [ "$waited" -gt 90 ] && die "a CI nao registrou nenhum check em 90s — confira .github/workflows/ci.yaml"
    printf "\\r    registrando os checks… %ss" "$waited"
    sleep 3
  done
  [ "$waited" -gt 0 ] && printf "\\r%*s\\r" 44 ""
'''
    linha = [l for l in s.splitlines() if "gh pr checks --watch" in l][0]
    s = s.replace(linha, espera + linha, 1)
    p.write_text(s); print("prompt: corrigido")

# ---- 2) scripts/audit.sh: rede/sessao vira ATENCAO, nao FALHA ------------
a = pathlib.Path("scripts/audit.sh"); t = a.read_text()
if "nao consegui listar projetos" in t or "não consegui listar projetos" in t:
    print("audit.sh: já corrigido")
else:
    novo = '''if [ -f .firebaserc ]; then
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
'''
    t2 = re.sub(r"if \[ -f \.firebaserc \]; then.*?\nfi\n(?=for f in firestore\.rules)",
                novo, t, count=1, flags=re.S)
    assert t2 != t, "nao achei o bloco do .firebaserc — me avise"
    a.write_text(t2); print("audit.sh: corrigido")
PATCH

chmod +x scripts/prompt scripts/audit.sh
bash -n scripts/prompt && bash -n scripts/audit.sh && echo "SINTAXE OK"
git branch -d chore/tooling 2>/dev/null
