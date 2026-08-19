# Roteiro — repositório Git e GitHub

Corrige o achado **C-01** da auditoria. Sete passos, na ordem. Os passos 1 a 5
são automatizados por `scripts/git-init.sh`; os passos 6 e 7 são no
github.com, com as telas ilustradas em `docs/guia-github.html`.

---

## Passo 0 · Por que não é só `git init`

Rodar `git init && git add -A && git commit` agora versionaria
**`scripts/seed/node_modules` — 134 pacotes**, porque o `.gitignore` cobria
`functions/node_modules/` mas não os demais subprojetos. Um `node_modules` que
entra no primeiro commit fica no histórico **para sempre**: remover depois exige
reescrever a história do repositório.

Isso já foi corrigido. O `.gitignore` agora usa `**/node_modules/`, e o
`.firebaserc` passou a ser versionado — ids de projeto não são segredo, e
mantê-lo fora do repositório foi a origem do achado A-01.

---

## Passos 1 a 5 · Local, automatizados

```bash
cd /Volumes/Dev_environment/DEV_CLAUDE/elytron_dash2board
chmod +x scripts/git-init.sh
./scripts/git-init.sh
```

O script executa, parando em qualquer inconsistência:

| Passo | O que faz | Por que importa |
|---|---|---|
| 1 | Verifica o git e detecta repositório existente | Não sobrescreve trabalho |
| 2 | **Backup** em `~/Backups/…tar.gz` | O projeto vive num volume externo; cópia antes de mexer |
| 3 | Configura autor, `main` como branch padrão, `pull.rebase` | Histórico linear e autoria correta |
| 4 | `git init -b main` e prepara os arquivos | — |
| 5 | **Cinco portões de validação** | Impede o commit errado |

Os portões: nada de `node_modules`/`build`/`Pods`/`.dart_tool`; nenhum segredo
conhecido; varredura por chave privada e API key fora de
`firebase_options.dart`; nenhum arquivo acima de 5 MB; e conferência de que o
alias `default` do `.firebaserc` existe de verdade na sua conta Firebase.

Se qualquer portão reprovar, **o script aborta sem comitar**.

Ao final ele cria o commit inicial e a tag `v0.1.0-auditado`.

### Conferência manual depois

```bash
git log --stat --oneline | head -20
git ls-files | wc -l                      # deve ficar na casa de 200–400
git ls-files | grep node_modules           # deve retornar VAZIO
git count-objects -vH | grep size-pack     # deve ficar em poucos MB
```

---

## Passo 6 · Criar o repositório no GitHub

Telas ilustradas em **`docs/guia-github.html`** (abra no navegador).

1. Acesse **https://github.com/new**
2. Preencha:
   - **Owner:** sua organização (recomendado) ou sua conta
   - **Repository name:** `dash2board`
   - **Description:** `Inteligência de segurança cibernética para CISOs e tomadores de decisão`
   - **Visibility: Private** ← obrigatório
   - **Initialize this repository with:** deixe **tudo desmarcado**.
     README, `.gitignore` e license já existem aqui; marcar cria commit no
     remoto e o primeiro `push` falha com "rejected — fetch first".
3. **Create repository**

### Autenticação — escolha SSH

HTTPS pede token a cada operação. SSH resolve uma vez e vale para tudo:

```bash
# 1. Existe chave?
ls -la ~/.ssh/id_ed25519.pub 2>/dev/null

# 2. Se não, crie
ssh-keygen -t ed25519 -C "daniel.tupinamba@elytronsecurity.com"
#    (Enter para o caminho padrão; defina uma passphrase)

# 3. Registre no agente e no Keychain do macOS
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519

# 4. Copie a chave PÚBLICA
pbcopy < ~/.ssh/id_ed25519.pub
```

No GitHub: **foto do perfil → Settings → SSH and GPG keys → New SSH key**.
Title: `MacBook Air Daniel`. Key type: `Authentication Key`. Cole e salve.

```bash
ssh -T git@github.com     # deve dizer: Hi <usuário>! You've successfully authenticated
```

### Publicar

```bash
git remote add origin git@github.com:dtupig/dash2board.git
git push -u origin main --follow-tags
```

---

## Passo 7 · Proteger o branch e ligar a CI

A CI já está pronta em `.github/workflows/ci.yaml` e roda no primeiro push.
São três jobs: **flutter** (format, analyze com `--fatal-infos`, test),
**guardrails** (as regras do `CLAUDE.md` verificadas por grep) e **rules**
(testes de security rules, quando `test/rules` existir).

Depois do primeiro push, em **Settings → Rules → Rulesets → New branch ruleset**:

| Campo | Valor |
|---|---|
| Ruleset Name | `protect-main` |
| Enforcement status | Active |
| Target branches | Include default branch |
| Require a pull request before merging | ✅ |
| Required approvals | 1 (ou 0 se você trabalha sozinho) |
| Require status checks to pass | ✅ → adicione `flutter` e `guardrails` |
| Block force pushes | ✅ |

Se você é o único desenvolvedor, mantenha `Required approvals: 0` mas **exija
os status checks**: é o que impede subir código com `analyze` sujo.

---

## Repositório publicado

| | |
|---|---|
| **Remote** | `git@github.com:dtupig/dash2board.git` |
| **Branch padrão** | `main` |
| **Tag do estado auditado** | `v0.1.0-auditado` |
| **Chave SSH** | `~/.ssh/id_ed25519_elytron`, amarrada via `core.sshCommand` |
| **Primeiro push** | 290 objetos, 357 KiB — confirma que nenhum `node_modules` entrou |

A chave está ligada a **este** repositório por `core.sshCommand` em
`.git/config`, não por alias em `~/.ssh/config`. Se um dia o push reclamar de
permissão, confira primeiro:

```bash
git config --get core.sshCommand
```

## Fluxo do dia a dia

```bash
git switch -c prompt/10-catalogo-servicos     # um branch por prompt
# ... roda o prompt no Claude Code ...
flutter analyze && flutter test
dart format lib test
git add -A && git commit -m "feat(servicos): catálogo dos 44 serviços e wizard de RFS"
git push -u origin HEAD
gh pr create --fill                            # ou pela interface
```

**Um branch por prompt.** Se o prompt 12 (retrofit da persona de especialista)
der errado, `git switch main` desfaz tudo. É exatamente a rede que faltava.

### Convenção de mensagem

`tipo(escopo): resumo no imperativo`

Tipos: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`, `sec`.
Escopos usuais: `auth`, `strategic`, `charts`, `servicos`, `relatorios`,
`staff`, `rules`, `seed`, `ci`.

Use `sec(...)` para qualquer mudança em `firestore.rules`, política de acesso ou
classificação de relatório — facilita auditar depois exatamente o que mexeu em
segurança.

---

## O que NÃO versionar (já configurado)

`build/`, `.dart_tool/`, `**/node_modules/`, `ios/Pods/`, `functions/lib/`,
`scripts/seed/lib/`, `.DS_Store`, `google-services.json`,
`GoogleService-Info.plist`, `*.keystore`, `*.jks`, `key.properties`, `.env*`,
`service-account*.json`, `audit-report.txt`.

**Versionado de propósito:** `pubspec.lock` (build reproduzível),
`lib/firebase_options.dart` (chaves de cliente do Firebase são públicas por
design; a proteção real está nas security rules e no App Check) e
`.firebaserc`.

---

## Se algo der errado

| Situação | Saída |
|---|---|
| Commitei um segredo | **Rotacione a credencial primeiro.** Reescrever histórico não desfaz o vazamento |
| `push` rejeitado com "fetch first" | Você marcou README ao criar o repo. `git pull --rebase origin main` e empurre de novo |
| `node_modules` entrou no commit | Se ainda não empurrou: `git reset --soft HEAD~1`, corrija o `.gitignore`, recomite |
| Preciso voltar ao estado auditado | `git checkout v0.1.0-auditado` |
| Perdi tudo | Restaure o `.tar.gz` de `~/Backups/` |
