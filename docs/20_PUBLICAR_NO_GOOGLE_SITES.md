# Publicar o plano do épico E-W no Google Sites

Três caminhos, do mais robusto ao mais imediato. O arquivo de origem é
`docs/19_PLANO_INTERFACE_WEB.html`; a cópia em texto puro para colar está em
`docs/19_PLANO_INTERFACE_WEB_googlesites.txt`.

## O limite que atrapalha o "copiar e colar"

A caixa **Inserir → Incorporar → Código incorporado** do Google Sites aceita
cerca de **10.000 caracteres**. O plano tem **~33.000**. Ou seja: colar o
arquivo inteiro provavelmente será recusado ou truncado. Por isso a via
recomendada é hospedar o HTML e incorporar por URL — o snippet fica com menos
de 200 caracteres.

## Caminho A — Firebase Hosting (recomendado)

Você já tem o projeto `elytron-d2b-dev`, e Hosting cabe no plano Spark (D-12
não muda). Uma pasta separada evita conflito com o futuro build do app.

```bash
cd ~/Projetos_APP/dash2board
mkdir -p site-publico
cp docs/19_PLANO_INTERFACE_WEB.html site-publico/index.html
```

Em `firebase.json`, acrescente (ou ajuste) o bloco de hosting:

```json
"hosting": {
  "public": "site-publico",
  "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
  "headers": [
    {
      "source": "**",
      "headers": [
        { "key": "X-Content-Type-Options", "value": "nosniff" },
        { "key": "Referrer-Policy", "value": "strict-origin-when-cross-origin" },
        { "key": "Content-Security-Policy",
          "value": "default-src 'none'; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src https://fonts.gstatic.com; script-src 'unsafe-inline'; img-src 'self' data:; frame-ancestors https://sites.google.com https://*.googleusercontent.com" }
      ]
    }
  ]
}
```

> `frame-ancestors` precisa listar o Google Sites, senão o iframe abre em
> branco. **Nunca** use `frame-ancestors *` — isso é clickjacking servido de
> bandeja, e contradiz a HU-W-05 do próprio plano.

```bash
firebase deploy --only hosting
# URL: https://elytron-d2b-dev.web.app
```

No Google Sites: **Inserir → Incorporar → Por URL**, cole a URL. Se preferir
controlar a altura, use **Código incorporado** com:

```html
<iframe src="https://elytron-d2b-dev.web.app"
        title="Épico E-W — Interface Web"
        style="width:100%;height:1400px;border:0"
        loading="lazy"></iframe>
```

Atualizar o plano depois é `cp` + `firebase deploy --only hosting` — a página
do Sites nem precisa ser tocada.

## Caminho B — Google Drive (sem CLI, mas frágil)

Subir o HTML no Drive e compartilhar não renderiza a página: o Drive serve o
arquivo como download. Só funciona via serviços de terceiros que reescrevem o
link, o que coloca conteúdo interno em um intermediário. **Não recomendado.**

## Caminho C — Colar o código, aceitando a poda

Se precisar mesmo colar e a versão puder ser reduzida, dá para gerar um
recorte com o cabeçalho, o critério de aceitação e as tabelas — sem os 24
cartões e sem JavaScript — que cabe nos 10.000 caracteres. Peça a versão
"resumida para Sites" quando for o caso.

## Observação sobre incorporar por URL

O Google Sites carrega o iframe em um domínio `googleusercontent.com`. Páginas
que exigem login (como um artefato do Claude) **não** incorporam: o visitante
vê uma tela de autenticação ou um quadro em branco. Por isso a hospedagem
própria é o caminho.
