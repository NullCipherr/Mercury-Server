const SUPPORTED_LANGS = ["pt-BR", "en"];
const DEFAULT_LANG = "pt-BR";
const LANG_STORAGE_KEY = "mercury_landing_lang";
let currentUi = null;

function getContentUrl(lang) {
  return `assets/data/content.${lang}.json`;
}

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
  } else {
    element.removeAttribute("target");
    element.removeAttribute("rel");
  }
}

function clearElement(id) {
  const element = document.getElementById(id);
  if (element) {
    element.innerHTML = "";
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
  clearElement("nav-menu-list");
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

  clearElement("hero-actions");
  const actions = document.getElementById("hero-actions");
  if (actions) {
    hero.actions.forEach((action) => actions.appendChild(createButton(action)));
  }

  clearElement("hero-meta");
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

  clearElement("terminal-lines");
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

  clearElement("features-grid");
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

  clearElement("metrics-grid");
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

  clearElement("contribution-steps");
  const steps = document.getElementById("contribution-steps");
  if (steps) {
    contribution.steps.forEach((step, index) => {
      const li = document.createElement("li");
      li.textContent = `${index + 1}. ${step}`;
      steps.appendChild(li);
    });
  }

  clearElement("contribution-actions");
  const actions = document.getElementById("contribution-actions");
  if (actions) {
    contribution.actions.forEach((action) => actions.appendChild(createButton(action)));
  }
}

function setActiveLangButton(lang) {
  const buttons = document.querySelectorAll(".lang-btn");
  buttons.forEach((button) => {
    const isActive = button.dataset.lang === lang;
    button.classList.toggle("is-active", isActive);
    button.setAttribute("aria-pressed", isActive ? "true" : "false");
  });
}

function normalizeLang(inputLang) {
  if (!inputLang) return DEFAULT_LANG;

  if (inputLang.toLowerCase().startsWith("pt")) {
    return "pt-BR";
  }

  if (inputLang.toLowerCase().startsWith("en")) {
    return "en";
  }

  return DEFAULT_LANG;
}

function getInitialLang() {
  const stored = window.localStorage.getItem(LANG_STORAGE_KEY);
  if (SUPPORTED_LANGS.includes(stored)) {
    return stored;
  }

  return normalizeLang(window.navigator.language);
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
  setText("footer-text", content.footer.text);
  currentUi = content.ui || null;

  const langToggle = document.getElementById("lang-toggle");
  if (langToggle && content.ui.langToggleAria) {
    langToggle.setAttribute("aria-label", content.ui.langToggleAria);
  }

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
}

async function loadContent(lang) {
  const response = await fetch(getContentUrl(lang), { cache: "no-store" });
  if (!response.ok) {
    throw new Error(`JSON ${response.status}`);
  }

  return response.json();
}

async function switchLanguage(lang) {
  const status = document.getElementById("status");
  const normalized = normalizeLang(lang);

  try {
    const content = await loadContent(normalized);
    applyContent(content);
    setActiveLangButton(normalized);
    window.localStorage.setItem(LANG_STORAGE_KEY, normalized);
    if (status) {
      status.textContent = "";
    }
  } catch (error) {
    if (status) {
      const prefix = currentUi?.loadErrorPrefix ||
        (document.documentElement.lang === "en" ? "Failed to load content" : "Erro ao carregar conteúdo");
      status.textContent = `${prefix}: ${error.message}`;
    }
  }
}

function setupLanguageToggle() {
  const buttons = document.querySelectorAll(".lang-btn");
  buttons.forEach((button) => {
    button.addEventListener("click", () => {
      switchLanguage(button.dataset.lang || DEFAULT_LANG);
    });
  });
}

function initLanding() {
  setupLanguageToggle();
  switchLanguage(getInitialLang());
}

initLanding();
