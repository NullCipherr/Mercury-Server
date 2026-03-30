# Deploy no GitHub Pages

## Pré-requisitos

- Branch de publicação: `gh-pages`.
- Arquivo de entrada: `index.html` na raiz.
- `.nojekyll` presente na raiz.
- Node.js 22+ para gerar build otimizado (`dist/`).

## Build otimizado antes do deploy

```bash
npm install
npm run build
```

O build:

- minifica CSS e JS;
- aplica hash em assets críticos;
- gera artefato final em `dist/`.

## Passos

1. Publique o conteúdo de `dist/` na branch de deploy.

```bash
rsync -av --delete dist/ ./
git add .
git commit -m "chore: deploy optimized static build"
git push -u origin gh-pages
```

2. No GitHub:

- `Settings` > `Pages`
- `Source`: `Deploy from a branch`
- `Branch`: `gh-pages`
- `Folder`: `/ (root)`

3. Aguarde a publicação e valide:

- URL principal da landing.
- `robots.txt`.
- `sitemap.xml`.
- Open Graph e Twitter preview.
- Integridade de assets hashados (`assets/css/styles.<hash>.css` e `assets/js/main.<hash>.js`).

## Pós-deploy (recomendado)

- Registrar domínio/propriedade no Google Search Console.
- Enviar `sitemap.xml` no Search Console e validar cobertura/indexação.
- Executar Lighthouse real em produção:

```bash
LIGHTHOUSE_URL="https://nullcipherr.github.io/Mercury-Server/" npm run lighthouse:prod
```

- Habilitar monitoramento sintético:
  - `.github/workflows/synthetic-monitoring.yml` (uptime + regressão de TTFB).
