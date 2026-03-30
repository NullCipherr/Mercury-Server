<div align="center">
  <img src="assets/favicon.svg" alt="Mercury Server Landing" width="110" />
  <h1>Mercury Server Landing</h1>
  <p><i>Landing page oficial do Mercury Server para GitHub Pages, com i18n, SEO técnico e arquitetura estática modular.</i></p>

  <p>
    <img src="https://img.shields.io/badge/Stack-HTML%20%7C%20CSS%20%7C%20JS-0ea5e9?style=flat-square" alt="Stack" />
    <img src="https://img.shields.io/badge/i18n-EN%20%7C%20PT--BR-ef4444?style=flat-square" alt="i18n" />
    <img src="https://img.shields.io/badge/Deploy-GitHub%20Pages-111827?style=flat-square" alt="Deploy" />
  </p>
</div>

---

## Visão Geral

Esta branch (`gh-pages`) isola a camada de apresentação pública do projeto, sem acoplamento ao código do servidor.

Objetivos da landing:

- comunicar proposta de valor do Mercury Server;
- apresentar recursos e benchmark com contexto técnico;
- facilitar contribuição open source;
- entregar base com SEO técnico forte para indexação e compartilhamento.

---

## Principais Recursos

- Layout estático modular (`index.html` + CSS + JS).
- Conteúdo centralizado em JSON por idioma.
- Fontes self-hosted (`assets/fonts`) com `font-display: swap`.
- Imagem Open Graph dedicada 1200x630 (`assets/og`) com WebP + fallback PNG.
- Toggle de idioma com persistência (`localStorage`) e suporte por query string (`?lang=pt-BR`).
- Pipeline de build otimizado com minificação e hash de CSS/JS (`npm run build`).
- Monitoramento sintético e auditoria Lighthouse em produção via GitHub Actions.
- SEO técnico com:
  - Open Graph completo;
  - Twitter Cards;
  - canonical dinâmico;
  - `hreflang`;
  - JSON-LD (`SoftwareSourceCode`);
  - `robots.txt` e `sitemap.xml`.
- Estrutura pronta para GitHub Pages com `.nojekyll`.

---

## Estrutura do Projeto

```text
.
├── assets/
│   ├── css/
│   │   └── styles.css
│   ├── data/
│   │   ├── content.en.json
│   │   └── content.pt-BR.json
│   ├── fonts/
│   ├── og/
│   ├── js/
│   │   └── main.js
│   └── favicon.svg
├── scripts/
│   ├── build.mjs
│   └── uptime-check.mjs
├── .github/workflows/
│   ├── lighthouse-production.yml
│   └── synthetic-monitoring.yml
├── docs/
│   ├── README.md
│   ├── SITE_ARCHITECTURE.md
│   ├── SEO_TECHNICAL_GUIDE.md
│   ├── CONTENT_AND_I18N.md
│   ├── DEPLOY_GITHUB_PAGES.md
│   └── PERFORMANCE_DEPLOY_CHECKLIST.md
├── lighthouserc.cjs
├── package.json
├── .nojekyll
├── index.html
├── robots.txt
└── sitemap.xml
```

---

## Documentação

- [Índice da documentação do site](docs/README.md)
- [Arquitetura do site](docs/SITE_ARCHITECTURE.md)
- [SEO técnico](docs/SEO_TECHNICAL_GUIDE.md)
- [Conteúdo e i18n](docs/CONTENT_AND_I18N.md)
- [Deploy no GitHub Pages](docs/DEPLOY_GITHUB_PAGES.md)
- [Checklist de performance pré-deploy](docs/PERFORMANCE_DEPLOY_CHECKLIST.md)

---

## Desenvolvimento Local

Instalação:

```bash
npm install
```

Build otimizado (minify + hash):

```bash
npm run build
```

Preview simples do projeto-fonte (sem build):

```bash
python -m http.server 8080
```

Acesse:

- `http://localhost:8080/`

---

## Fluxo de Conteúdo

Todo conteúdo textual é mantido em:

- `assets/data/content.en.json`
- `assets/data/content.pt-BR.json`

Boas práticas de edição:

1. Alterar conteúdo no JSON do idioma correspondente.
2. Manter a mesma estrutura de chaves entre idiomas.
3. Validar JSON antes do commit:

```bash
jq empty assets/data/content.en.json
jq empty assets/data/content.pt-BR.json
```

---

## SEO e Indexação

Arquivos e configurações relevantes:

- metadados em `index.html` + atualização dinâmica em `assets/js/main.js`;
- `robots.txt`;
- `sitemap.xml`.

Antes de publicar, valide:

1. URL canônica final (`siteUrl` em `assets/data/content.*.json`).
2. Preview Open Graph/Twitter.
3. Lighthouse (SEO, Acessibilidade, Performance).
4. OG dedicada (`assets/og/og-image.webp` e `assets/og/og-image.png`).

---

## Deploy

Referência completa: [Deploy no GitHub Pages](docs/DEPLOY_GITHUB_PAGES.md)

Resumo:

1. `npm run build`
2. publicar conteúdo de `dist/` na branch de deploy
3. GitHub `Settings > Pages`
4. `Deploy from a branch` com branch `gh-pages`

---

## Manutenção Recomendada

- revisar periodicamente dados de benchmark exibidos na landing;
- manter links de docs e comunidade atualizados;
- rodar auditoria Lighthouse após mudanças visuais maiores;
- atualizar `sitemap.xml` caso novas rotas públicas sejam adicionadas.

---

## Licença

O conteúdo desta landing acompanha o projeto principal Mercury Server e segue a política de licença definida no repositório.
