# Landing Page - Branch `gh-pages`

Esta branch contém somente os arquivos da landing page para publicação no GitHub Pages.

## Estrutura de pastas

```text
.
├── assets/
│   ├── css/
│   │   └── styles.css
│   ├── data/
│   │   └── content.json
│   └── js/
│       └── main.js
├── .nojekyll
└── index.html
```

## Como manter conteúdo

Todo o conteúdo textual da landing está centralizado em `assets/data/content.json`.

Alterações rotineiras (copy, links, títulos, cards, métricas, contribuição) devem ser feitas nesse arquivo.

## Publicação no GitHub Pages

1. Faça push da branch `gh-pages`.
2. No repositório GitHub, configure: `Settings > Pages`.
3. Em Source, selecione: `Deploy from a branch`.
4. Branch: `gh-pages` / Folder: `/ (root)`.
