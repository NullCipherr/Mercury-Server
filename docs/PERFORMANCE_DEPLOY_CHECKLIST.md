# Checklist de Performance Pré-Deploy (Alta Prioridade)

## 1) Lighthouse real em produção

- Execução manual local:

```bash
LIGHTHOUSE_URL="https://nullcipherr.github.io/Mercury-Server/" npm run lighthouse:prod
```

- Execução automática:
  - Workflow: `.github/workflows/lighthouse-production.yml`
  - Gatilhos: push na `gh-pages`, execução manual e agendamento semanal.

## 2) Fontes self-hosted

- Removida dependência de Google Fonts no `index.html`.
- Fontes locais em `assets/fonts/`.
- `@font-face` configurado em `assets/css/styles.css` com `font-display: swap`.

## 3) Minificação + hash de assets

- Pipeline local:

```bash
npm run build
```

- Resultado:
  - gera `dist/`;
  - minifica CSS/JS;
  - aplica hash em CSS/JS;
  - reescreve `index.html` para os arquivos hashados.

## 4) Cache-Control agressivo via CDN/proxy

GitHub Pages não permite controlar cabeçalhos de cache por arquivo com granularidade fina.

Recomendação: usar CDN/proxy na frente do Pages (ex.: Cloudflare) com regras:

- `/*.html` e `/`:
  - `Cache-Control: public, max-age=0, must-revalidate`
- `/assets/css/*`, `/assets/js/*`, `/assets/fonts/*`, `/assets/og/*`:
  - `Cache-Control: public, max-age=31536000, immutable`
- `/assets/data/*.json`:
  - `Cache-Control: public, max-age=300, s-maxage=600, stale-while-revalidate=86400`

## 5) OG dedicada 1200x630 (WebP + fallback)

- Criadas:
  - `assets/og/og-image.webp`
  - `assets/og/og-image.png`
- Meta tags configuradas com WebP e fallback PNG em `index.html`.
- Metadados dinâmicos atualizados em `assets/js/main.js` + `assets/data/content.*.json`.

## 6) Search Console: sitemap e cobertura/indexação

Após deploy em produção:

1. Acessar Google Search Console e adicionar a propriedade de domínio/URL.
2. Enviar sitemap: `https://nullcipherr.github.io/Mercury-Server/sitemap.xml`.
3. Verificar relatórios:
   - Cobertura de páginas;
   - Indexação;
   - Experiência (Core Web Vitals).
4. Corrigir páginas excluídas/erro e solicitar nova indexação quando necessário.

## 7) Monitoramento sintético (uptime + regressão)

- Workflow: `.github/workflows/synthetic-monitoring.yml`.
- Frequência: a cada 15 minutos.
- Valida:
  - status HTTP (uptime);
  - TTFB com limiar configurável (`MONITOR_TTFB_THRESHOLD_MS`, padrão `1200ms`).
