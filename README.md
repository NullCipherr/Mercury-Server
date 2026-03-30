# Landing Page - Branch `gh-pages`

Esta branch contém somente os arquivos da landing page para publicação no GitHub Pages.

## Estrutura de pastas

```text
.
├── assets/
│   ├── css/
│   │   └── styles.css
│   ├── data/
│   │   ├── content.en.json
│   │   └── content.pt-BR.json
│   └── js/
│       └── main.js
├── .nojekyll
└── index.html
```

## Como manter conteúdo

Todo o conteúdo textual da landing está centralizado em JSON, separado por idioma:

- `assets/data/content.pt-BR.json`
- `assets/data/content.en.json`

Alterações rotineiras (copy, links, títulos, cards, métricas, contribuição) devem ser feitas nesses arquivos.

## Toggle de idioma

A página possui seletor `PT | EN` no header.

- O idioma inicial tenta usar `localStorage`.
- Se não houver valor salvo, usa o idioma do navegador.
- O conteúdo é recarregado dinamicamente sem alterar a estrutura HTML.

## Publicação no GitHub Pages

1. Faça push da branch `gh-pages`.
2. No repositório GitHub, configure: `Settings > Pages`.
3. Em Source, selecione: `Deploy from a branch`.
4. Branch: `gh-pages` / Folder: `/ (root)`.
