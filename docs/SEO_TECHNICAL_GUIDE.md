# SEO Técnico e Boas Práticas

## Itens implementados

- `title` e `meta description` por idioma.
- Open Graph completo (`og:title`, `og:description`, `og:image`, `og:url`, `og:locale`, `og:site_name`).
- Open Graph com imagem dedicada 1200x630 (WebP + fallback PNG).
- Twitter Cards (`summary_large_image`).
- `canonical` dinâmico por idioma.
- `hreflang` (`en`, `pt-BR`, `x-default`).
- JSON-LD (`SoftwareSourceCode`) para entendimento semântico por buscadores.
- `robots.txt` com referência ao `sitemap.xml`.
- `sitemap.xml` com URLs indexáveis da landing.

## Checklist de revisão antes de release

1. Confirmar `siteUrl` nos JSONs de conteúdo.
2. Verificar `canonical` apontando para domínio final de produção.
3. Garantir que imagem OG esteja acessível publicamente.
4. Validar `sitemap.xml` e `robots.txt` com URL final.
5. Rodar Lighthouse e registrar notas de SEO, Acessibilidade e Performance.
6. Enviar `sitemap.xml` no Google Search Console e acompanhar cobertura/indexação.

## Ferramentas recomendadas

- Lighthouse (Chrome DevTools).
- Rich Results Test (Google) para validar JSON-LD.
- Open Graph Preview / Twitter Card Validator.
