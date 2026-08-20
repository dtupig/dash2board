# Runbook — provisionamento e operação do Firebase

Sequência de comandos para criar e operar os três ambientes. Rode na raiz do
projeto. Confirme a sintaxe de cada comando com `--help` antes de executar em
produção: a CLI do Firebase e o `gcloud` mudam com frequência.

---

## 1. Ferramentas

```bash
npm install -g firebase-tools
brew install --cask google-cloud-sdk     # macOS
firebase --version && gcloud --version
firebase login
gcloud auth login
```

## 2. Criar os três projetos

IDs são globais: se o nome estiver em uso, acrescente sufixo.

```bash
firebase projects:create elytron-d2b-dev --display-name "Elytron Dash2Board DEV"
firebase projects:create elytron-d2b-stg --display-name "Elytron Dash2Board STG"
firebase projects:create elytron-d2b-prd --display-name "Elytron Dash2Board PRD"

firebase use --add    # repita para cada um, criando os aliases dev/stg/prd
cat .firebaserc
```

Cloud Functions, Storage e exportação agendada exigem **plano Blaze**. Por
decisão D-12, **dev e staging seguem no Spark** — Functions são exercitadas via
`firebase emulators:start`, sem deploy ao vivo e sem custo. Ative Blaze **só no
projeto `prd`**, com alerta de orçamento, antes do primeiro deploy real:

```bash
gcloud billing budgets create \
  --billing-account=<SUA_CONTA> \
  --display-name="Dash2Board PRD" \
  --budget-amount=50BRL \
  --threshold-rule=percent=50 --threshold-rule=percent=90
```

## 3. Criar o Firestore (uma vez por projeto)

**A região é permanente.** Escolha antes de qualquer escrita.

```bash
firebase use dev
gcloud firestore databases create \
  --database='(default)' \
  --location=southamerica-east1 \
  --type=firestore-native \
  --project=elytron-d2b-dev
```

Repita para `stg` e `prd`.

## 4. Realtime Database (apenas presença e efêmeros)

```bash
firebase database:instances:create elytron-d2b-dev-presence --project=elytron-d2b-dev
```

Crie `database.rules.json` com o conteúdo do anexo de
`docs/11_MODELO_FISICO_DADOS.md` e registre no `firebase.json`:

```json
"database": { "rules": "database.rules.json" }
```

## 5. Autenticação

No console: **Authentication → Sign-in method → E-mail/senha: ativar**.
Desative o cadastro aberto — a admissão é controlada pela Cloud Function
`gateSignUp`.

MFA obrigatório para staff: **Authentication → Multi-factor**.

## 6. Deploy de regras e índices

```bash
firebase use dev
firebase deploy --only firestore:rules,firestore:indexes,database,storage
firebase deploy --only functions
```

Índices compostos levam minutos para construir. Acompanhe:

```bash
gcloud firestore indexes composite list --project=elytron-d2b-dev
```

## 7. Emuladores (o ambiente do dia a dia)

```bash
firebase emulators:start --import=./.emulator-data --export-on-exit
```

`--export-on-exit` preserva o estado entre sessões. Use sempre — recarregar o
seed toda vez é desperdício de tempo.

## 8. Seed

```bash
cd scripts/seed && npm install && cd ../..

# emulador (padrão, seguro)
npm --prefix scripts/seed run seed

# projeto real de dev
FIRESTORE_PROJECT=elytron-d2b-dev npm --prefix scripts/seed run seed:dev

# produção: exige confirmação explícita
CONFIRM_PROD=1 npm --prefix scripts/seed run seed:prod
```

## 9. Backup e recuperação

```bash
# PITR (janela de 7 dias)
gcloud firestore databases update --database='(default)' \
  --enable-pitr --project=elytron-d2b-prd

# exportação diária agendada
gcloud firestore backups schedules create \
  --database='(default)' --recurrence=daily --retention=14d \
  --project=elytron-d2b-prd

gcloud firestore backups list --location=southamerica-east1 --project=elytron-d2b-prd
```

**Teste de restauração trimestral**, em projeto descartável:

```bash
gcloud firestore databases restore \
  --source-backup=<BACKUP> --destination-database=restore-test \
  --project=elytron-d2b-restore-test
```

Backup que nunca foi restaurado não é backup — é esperança.

## 10. App Check (obrigatório em produção)

Console → App Check → registre iOS (App Attest) e Android (Play Integrity).
Rode em modo de monitoramento por duas semanas antes de aplicar o bloqueio;
ativar direto derruba usuários legítimos.

## 11. IAM — princípio do menor privilégio

| Papel humano | Papel GCP |
|---|---|
| Desenvolvedor | `roles/firebase.developAdmin` só em `dev` |
| CI/CD | conta de serviço dedicada, deploy em `stg` e `prd` |
| DBA / SRE | `roles/datastore.owner` em `prd`, com aprovação |
| Suporte | `roles/datastore.viewer`, apenas leitura, com registro |

Ninguém usa a conta de proprietário no dia a dia. Acesso a `prd` é nominal e
auditado.

## 12. Verificação pós-provisionamento

```bash
firebase projects:list
gcloud firestore databases describe --database='(default)' --project=<ID>
gcloud firestore indexes composite list --project=<ID>
firebase deploy --only firestore:rules --dry-run
npm --prefix test/rules run test:rules
```

Só considere o ambiente pronto quando os testes de regras passarem contra ele.
