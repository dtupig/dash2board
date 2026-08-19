# Templates de `.github/`

O bridge do Claude não escreve em `.github/` (pasta protegida), então os
arquivos ficam aqui e você os copia com um comando:

```bash
mkdir -p .github/workflows
cp scripts/github-templates/ci.yaml .github/workflows/ci.yaml
cp scripts/github-templates/pull_request_template.md .github/pull_request_template.md
```

Depois de copiados, esta pasta pode ser removida — ou mantida como referência.

## `ci.yaml` — três jobs

| Job | O que roda |
|---|---|
| `flutter` | `dart format --set-exit-if-changed`, `flutter analyze --fatal-infos --fatal-warnings`, `flutter test` |
| `guardrails` | As regras do `CLAUDE.md` por grep: APIs proibidas, acento de marca em gráfico, Firebase em `presentation/`, segredo versionado |
| `rules` | Testes de security rules — avisa e passa enquanto `test/rules` não existir |

O `guardrails` ignora linhas de comentário, então os comentários normativos do
código (que citam `withOpacity` para proibir) não geram falso positivo.
