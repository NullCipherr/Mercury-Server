<div align="center">
  <img src="assets/favicon.svg" alt="Mercury Server Landing" width="110" />
  <h1>Mercury Server Landing</h1>
  <p><i>Official Mercury Server landing page for GitHub Pages, with i18n, technical SEO, and a modular static architecture.</i></p>

  <p>
    <img src="https://img.shields.io/badge/Stack-HTML%20%7C%20CSS%20%7C%20JS-0ea5e9?style=flat-square" alt="Stack" />
    <img src="https://img.shields.io/badge/i18n-EN%20%7C%20PT--BR-ef4444?style=flat-square" alt="i18n" />
    <img src="https://img.shields.io/badge/Deploy-GitHub%20Pages-111827?style=flat-square" alt="Deploy" />
  </p>
</div>

> Language: **English (default)** | [Português (pt-BR)](./README.pt-BR.md)

---

## Overview

This branch (`gh-pages`) isolates the public presentation layer of Mercury Server without coupling to the server runtime code.

Landing page goals:

- communicate Mercury Server's value proposition;
- present features and benchmark context with technical clarity;
- streamline open source contribution entry points;
- provide a strong technical SEO baseline for indexation and sharing.

---

## Key Features

- Modular static layout (`index.html` + CSS + JS).
- Content centralized in per-language JSON files.
- Self-hosted fonts (`assets/fonts`) with `font-display: swap`.
- Dedicated Open Graph image 1200x630 (`assets/og`) with WebP + PNG fallback.
- Language toggle with persistence (`localStorage`) and query-string support (`?lang=pt-BR`).
- Optimized build pipeline with CSS/JS minification and hashed assets (`npm run build`).
- Synthetic monitoring and production Lighthouse audits via GitHub Actions.
- Technical SEO with:
  - full Open Graph tags;
  - Twitter Cards;
  - dynamic canonical;
  - `hreflang`;
  - JSON-LD (`SoftwareSourceCode`);
  - `robots.txt` and `sitemap.xml`.
- GitHub Pages ready setup with `.nojekyll`.

---

## Project Structure

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

## Documentation

- [Documentation index](docs/README.md)
- [Site architecture](docs/SITE_ARCHITECTURE.md)
- [Technical SEO](docs/SEO_TECHNICAL_GUIDE.md)
- [Content and i18n](docs/CONTENT_AND_I18N.md)
- [GitHub Pages deploy](docs/DEPLOY_GITHUB_PAGES.md)
- [Pre-deploy performance checklist](docs/PERFORMANCE_DEPLOY_CHECKLIST.md)

---

## Local Development

Install dependencies:

```bash
npm install
```

Run optimized build (minify + hash):

```bash
npm run build
```

Simple source preview (without build):

```bash
python -m http.server 8080
```

Open:

- `http://localhost:8080/`

---

## Content Workflow

All textual content is managed in:

- `assets/data/content.en.json`
- `assets/data/content.pt-BR.json`

Editing best practices:

1. Update content in the corresponding language JSON.
2. Keep the same key structure across locales.
3. Validate JSON before committing:

```bash
jq empty assets/data/content.en.json
jq empty assets/data/content.pt-BR.json
```

---

## SEO and Indexation

Relevant files/configuration:

- metadata in `index.html` + dynamic updates in `assets/js/main.js`;
- `robots.txt`;
- `sitemap.xml`.

Before publishing, validate:

1. Final canonical URL (`siteUrl` in `assets/data/content.*.json`).
2. Open Graph / Twitter preview.
3. Lighthouse (SEO, Accessibility, Performance).
4. Dedicated OG assets (`assets/og/og-image.webp` and `assets/og/og-image.png`).

---

## Deploy

Full reference: [Deploy on GitHub Pages](docs/DEPLOY_GITHUB_PAGES.md)

Summary:

1. `npm run build`
2. publish `dist/` content to the deploy branch
3. GitHub `Settings > Pages`
4. `Deploy from a branch` using `gh-pages`

---

## Recommended Maintenance

- periodically review benchmark numbers shown on the landing;
- keep docs and community links up to date;
- run Lighthouse audits after major visual updates;
- update `sitemap.xml` whenever new public routes are added.

---

## License

This landing page follows the licensing policy defined in the main Mercury Server repository.
