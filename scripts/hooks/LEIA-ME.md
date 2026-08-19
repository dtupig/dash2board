# Hooks locais

Hooks do git **não são versionados** — ficam em `.git/hooks/`, que é local a
cada clone. Por isso eles moram aqui e são instalados por comando:

```bash
./scripts/hooks/install.sh
```

## `pre-push`

1. **Bloqueia push direto no `main`.** Substitui parcialmente a proteção de
   branch do GitHub quando ela não está disponível — proteção de branch em
   repositório privado exige plano pago.
2. Reprova se a formatação estiver pendente.
3. Roda `flutter analyze --fatal-infos --fatal-warnings`, nos mesmos termos da
   CI.

## `pre-commit`

Só a checagem de formatação — rápido, para não atrapalhar o ritmo de commit.

## Limites, sem ilusão

Guarda local **não é** proteção de branch. Ela vale nesta máquina, pode ser
contornada com `--no-verify`, e não se aplica a quem clonar o repositório
sem instalar os hooks. Serve para evitar o erro por distração, não o ato
deliberado. A proteção de verdade é do lado do servidor.
