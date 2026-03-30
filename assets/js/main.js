const CONTENT_URL = "assets/data/content.json";

function setText(id, value) {
  const element = document.getElementById(id);
  if (element) {
    element.textContent = value || "";
  }
}

function setLink(element, link) {
  if (!element || !link) return;
  element.textContent = link.label || "";
  element.href = link.href || "#";
  if (link.external) {
    element.target = "_blank";
    element.rel = "noreferrer";
  }
}

function createButton(link) {
  const anchor = document.createElement("a");
  const variant = link.variant === "ghost" ? "btn-ghost" : "btn-primary";
  anchor.className = `btn ${variant}`;
  setLink(anchor, link);
  return anchor;
}

function setMetaTag(selector, content) {
  const element = document.querySelector(selector);
  if (element && content) {
    element.setAttribute("content", content);
  }
}

function renderNav(links) {
  const list = document.getElementById("nav-menu-list");
  if (!list) return;

  links.forEach((link) => {
    const li = document.createElement("li");
    const a = document.createElement("a");
    setLink(a, link);
    li.appendChild(a);
    list.appendChild(li);
  });
}

function renderHero(hero) {
  setText("hero-eyebrow", hero.eyebrow);
  setText("hero-title", hero.title);
  setText("hero-description", hero.description);

  const actions = document.getElementById("hero-actions");
  if (actions) {
    hero.actions.forEach((action) => actions.appendChild(createButton(action)));
  }

  const heroMeta = document.getElementById("hero-meta");
  if (heroMeta) {
    hero.meta.forEach((item) => {
      const span = document.createElement("span");
      span.textContent = item;
      heroMeta.appendChild(span);
    });
  }
}

function renderTerminal(terminal) {
  setText("terminal-path", terminal.path);

  const container = document.getElementById("terminal-lines");
  if (!container) return;

  terminal.lines.forEach((line, index) => {
    const span = document.createElement("span");
    span.textContent = line.text || "";
    if (line.kind === "ok") span.className = "line-ok";
    if (line.kind === "warn") span.className = "line-warn";
    container.appendChild(span);
    if (index < terminal.lines.length - 1) {
      container.appendChild(document.createTextNode("\n"));
    }
  });
}

function renderFeatures(features) {
  setText("features-title", features.title);
  setText("features-description", features.description);

  const grid = document.getElementById("features-grid");
  if (!grid) return;

  features.cards.forEach((card) => {
    const article = document.createElement("article");
    article.className = "card";

    const title = document.createElement("h3");
    title.textContent = card.title;

    const description = document.createElement("p");
    description.textContent = card.description;

    article.appendChild(title);
    article.appendChild(description);
    grid.appendChild(article);
  });
}

function renderMetrics(metrics) {
  setText("metrics-title", metrics.title);
  setText("metrics-description", metrics.description);

  const grid = document.getElementById("metrics-grid");
  if (!grid) return;

  metrics.items.forEach((item) => {
    const article = document.createElement("article");
    article.className = "metric";

    const value = document.createElement("strong");
    value.textContent = item.value;

    const label = document.createElement("span");
    label.textContent = item.label;

    article.appendChild(value);
    article.appendChild(label);
    grid.appendChild(article);
  });
}

function renderContribution(contribution) {
  setText("contribution-title", contribution.title);
  setText("contribution-description", contribution.description);

  const steps = document.getElementById("contribution-steps");
  if (steps) {
    contribution.steps.forEach((step, index) => {
      const li = document.createElement("li");
      li.textContent = `${index + 1}. ${step}`;
      steps.appendChild(li);
    });
  }

  const actions = document.getElementById("contribution-actions");
  if (actions) {
    contribution.actions.forEach((action) => actions.appendChild(createButton(action)));
  }
}

function applyContent(content) {
  if (content.lang) {
    document.documentElement.lang = content.lang;
  }

  document.title = content.meta.title;
  setMetaTag('meta[name="description"]', content.meta.description);
  setMetaTag('meta[property="og:title"]', content.meta.ogTitle);
  setMetaTag('meta[property="og:description"]', content.meta.ogDescription);
  setMetaTag('meta[property="og:image"]', content.meta.ogImage);
  setMetaTag('meta[name="theme-color"]', content.meta.themeColor);

  setText("skip-link", content.ui.skipLink);

  const brandLogo = document.getElementById("brand-logo");
  if (brandLogo) {
    brandLogo.src = content.brand.logoUrl;
    brandLogo.alt = content.brand.logoAlt;
  }
  setText("brand-name", content.brand.name);

  renderNav(content.navigation.links);

  const repoButton = document.getElementById("repo-button");
  setLink(repoButton, content.navigation.repoButton);

  renderHero(content.hero);
  renderTerminal(content.terminal);
  renderFeatures(content.features);
  renderMetrics(content.metrics);
  renderContribution(content.contribution);

  setText("footer-text", content.footer.text);
}

async function initLanding() {
  const status = document.getElementById("status");

  try {
    const response = await fetch(CONTENT_URL, { cache: "no-store" });
    if (!response.ok) {
      throw new Error(`Falha ao carregar JSON (${response.status})`);
    }

    const content = await response.json();
    applyContent(content);
    if (status) status.textContent = "";
  } catch (error) {
    if (status) {
      status.textContent = `Erro ao carregar conteúdo: ${error.message}`;
    }
  }
}

initLanding();
