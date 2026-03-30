# Arquitetura do Site

## Visão Geral

A landing é um projeto estático composto por HTML, CSS e JavaScript vanilla, com conteúdo desacoplado em JSON por idioma.

Princípios aplicados:

- Estrutura simples para publicação em GitHub Pages.
- Conteúdo versionado e editável sem alterar layout.
- SEO técnico tratado no HTML base e reforçado no runtime.
- Sem dependências externas de framework.

## Estrutura de Pastas

```text
.
├── assets/
│   ├── css/
│   │   └── styles.css
│   ├── data/
│   │   ├── content.en.json
│   │   └── content.pt-BR.json
│   ├── js/
│   │   └── main.js
│   └── favicon.svg
├── docs/
│   ├── README.md
│   ├── SITE_ARCHITECTURE.md
│   ├── SEO_TECHNICAL_GUIDE.md
│   ├── CONTENT_AND_I18N.md
│   └── DEPLOY_GITHUB_PAGES.md
├── index.html
├── robots.txt
└── sitemap.xml
```

## Renderização

1. `index.html` carrega a estrutura semântica da página.
2. `assets/js/main.js` detecta idioma e carrega o JSON correspondente.
3. O JS injeta conteúdo nas seções (hero, features, benchmark, contribute, footer).
4. Metadados SEO críticos são atualizados em runtime (canonical, OG URL, locale, JSON-LD).

## Convenções

- IDs de seção em inglês para consistência técnica (`#features`, `#benchmark`, `#contribute`).
- Copy e links de negócio ficam exclusivamente nos arquivos `assets/data/content.*.json`.
- Estilo global e responsividade ficam em `assets/css/styles.css`.
