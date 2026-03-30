# Fluxo de Conteúdo e Internacionalização

## Idiomas suportados

- `en` (padrão)
- `pt-BR`

## Fonte de verdade de conteúdo

- `assets/data/content.en.json`
- `assets/data/content.pt-BR.json`

Cada arquivo controla:

- Metadados (SEO).
- Navegação.
- Hero.
- Features.
- Benchmark.
- Contribute.
- Footer.

## Como atualizar conteúdo

1. Edite o JSON do idioma desejado.
2. Preserve a mesma estrutura de chaves entre os dois idiomas.
3. Valide JSON localmente (`jq empty <arquivo>`).
4. Revise visualmente a seção alterada.

## Padrões

- Evitar texto hardcoded no HTML.
- Evitar links duplicados em múltiplos pontos do código.
- Concentrar copy de produto nos JSONs.
