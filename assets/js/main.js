const SUPPORTED_LANGS = ["pt-BR", "en"];
const DEFAULT_LANG = "en";
const LANG_STORAGE_KEY = "mercury_landing_lang";
const LANG_QUERY_PARAM = "lang";
let currentUi = null;

// Company standard: each locale ships as an independent static JSON file
// so content updates can happen without touching layout code.
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

// Company standard: clear container nodes before each render to avoid
// duplicated UI blocks after language switches.
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

function setLinkHref(selector, href) {
  const element = document.querySelector(selector);
  if (element && href) {
    element.setAttribute("href", href);
  }
}

function getSiteBaseUrl(content) {
  return content?.meta?.siteUrl || "https://nullcipherr.github.io/Mercury-Server/";
}

function getPublicUrlForLang(content, lang) {
  const base = new URL(getSiteBaseUrl(content));
  if (lang && lang !== DEFAULT_LANG) {
    base.searchParams.set(LANG_QUERY_PARAM, lang);
  } else {
    base.searchParams.delete(LANG_QUERY_PARAM);
  }
  return base.toString();
}

function setStructuredData(content, lang) {
  const node = document.getElementById("structured-data");
  if (!node) return;

  const data = {
    "@context": "https://schema.org",
    "@type": "SoftwareSourceCode",
    name: content.brand?.name || "Mercury Server",
    url: getPublicUrlForLang(content, lang),
    codeRepository: "https://github.com/NullCipherr/Mercury-Server",
    programmingLanguage: "Zig",
    license: "https://github.com/NullCipherr/Mercury-Server/blob/main/LICENSE",
    description: content.meta?.description || ""
  };

  node.textContent = JSON.stringify(data);
}

function updateBrowserUrl(lang) {
  const url = new URL(window.location.href);
  if (lang === DEFAULT_LANG) {
    url.searchParams.delete(LANG_QUERY_PARAM);
  } else {
    url.searchParams.set(LANG_QUERY_PARAM, lang);
  }
  window.history.replaceState({}, "", `${url.pathname}${url.search}${url.hash}`);
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
  setText("benchmark-context-title", metrics.contextTitle);
  setText("benchmark-comparison-title", metrics.comparisonTitle);

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

  clearElement("benchmark-context-list");
  const contextList = document.getElementById("benchmark-context-list");
  if (contextList && metrics.contextItems) {
    metrics.contextItems.forEach((item) => {
      const li = document.createElement("li");
      li.textContent = item;
      contextList.appendChild(li);
    });
  }

  clearElement("benchmark-comparison-grid");
  const comparisonGrid = document.getElementById("benchmark-comparison-grid");
  if (comparisonGrid && metrics.comparisonItems) {
    metrics.comparisonItems.forEach((item) => {
      const card = document.createElement("article");
      card.className = "benchmark-mini-card";

      const name = document.createElement("strong");
      name.textContent = item.name;

      const detail = document.createElement("span");
      detail.textContent = item.summary;

      card.appendChild(name);
      card.appendChild(detail);
      comparisonGrid.appendChild(card);
    });
  }
}

function renderContribution(contribution) {
  setText("contribution-title", contribution.title);
  setText("contribution-description", contribution.description);
  setText("contribution-panel-title", contribution.panel?.title);
  setText("contribution-panel-description", contribution.panel?.description);
  setText("contribution-checklist-title", contribution.checklistTitle);

  clearElement("contribution-steps");
  const steps = document.getElementById("contribution-steps");
  if (steps) {
    contribution.steps.forEach((step, index) => {
      const li = document.createElement("li");
      if (typeof step === "string") {
        li.textContent = step;
      } else {
        const strong = document.createElement("strong");
        strong.className = "step-title";
        strong.textContent = step.title || `Step ${index + 1}`;
        const detail = document.createElement("p");
        detail.className = "step-description";
        detail.textContent = step.description || "";
        li.appendChild(strong);
        li.appendChild(detail);
      }
      steps.appendChild(li);
    });
  }

  clearElement("contribution-actions");
  const actions = document.getElementById("contribution-actions");
  if (actions) {
    contribution.actions.forEach((action) => actions.appendChild(createButton(action)));
  }

  clearElement("contribution-panel-links");
  const panelLinks = document.getElementById("contribution-panel-links");
  if (panelLinks && contribution.panel?.links) {
    contribution.panel.links.forEach((linkData) => {
      const li = document.createElement("li");
      const link = document.createElement("a");
      setLink(link, linkData);
      li.appendChild(link);
      panelLinks.appendChild(li);
    });
  }

  clearElement("contribution-checklist");
  const checklist = document.getElementById("contribution-checklist");
  if (checklist && contribution.checklist) {
    contribution.checklist.forEach((item) => {
      const li = document.createElement("li");
      li.textContent = item;
      checklist.appendChild(li);
    });
  }
}

function renderFooter(content) {
  setText("footer-brand-name", content.brand.name);
  setText("footer-description", content.footer.description);
  setText("footer-legal", content.footer.legalText);

  clearElement("footer-badges");
  const badges = document.getElementById("footer-badges");
  if (badges) {
    content.footer.badges.forEach((badgeText) => {
      const badge = document.createElement("span");
      badge.className = "footer-badge";
      badge.textContent = badgeText;
      badges.appendChild(badge);
    });
  }

  clearElement("footer-link-groups");
  const groupsContainer = document.getElementById("footer-link-groups");
  if (groupsContainer) {
    content.footer.groups.forEach((group) => {
      const section = document.createElement("section");
      section.className = "footer-group";

      const title = document.createElement("h3");
      title.textContent = group.title;

      const list = document.createElement("ul");
      group.links.forEach((linkData) => {
        const li = document.createElement("li");
        const link = document.createElement("a");
        setLink(link, linkData);
        li.appendChild(link);
        list.appendChild(li);
      });

      section.appendChild(title);
      section.appendChild(list);
      groupsContainer.appendChild(section);
    });
  }

  clearElement("footer-bottom-links");
  const bottomLinks = document.getElementById("footer-bottom-links");
  if (bottomLinks) {
    content.footer.bottomLinks.forEach((linkData) => {
      const link = document.createElement("a");
      setLink(link, linkData);
      bottomLinks.appendChild(link);
    });
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

// Company standard: map browser variations to supported locales.
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
  const fromQuery = new URLSearchParams(window.location.search).get(LANG_QUERY_PARAM);
  const normalizedQuery = normalizeLang(fromQuery);
  if (fromQuery && SUPPORTED_LANGS.includes(normalizedQuery)) {
    return normalizedQuery;
  }

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
  setMetaTag('#og-image-webp', content.meta.ogImage);
  setMetaTag('#og-image-webp-type', "image/webp");
  setMetaTag('#og-image-fallback', content.meta.ogImageFallback || content.meta.ogImage);
  setMetaTag('#og-image-fallback-type', content.meta.ogImageFallback ? "image/png" : "image/webp");
  setMetaTag('meta[name="twitter:title"]', content.meta.ogTitle);
  setMetaTag('meta[name="twitter:description"]', content.meta.ogDescription);
  setMetaTag('meta[name="twitter:image"]', content.meta.ogImageFallback || content.meta.ogImage);
  setMetaTag('meta[name="theme-color"]', content.meta.themeColor);

  setText("skip-link", content.ui.skipLink);
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
  renderFooter(content);
}

async function loadContent(lang) {
  const response = await fetch(getContentUrl(lang), { cache: "default" });
  if (!response.ok) {
    throw new Error(`JSON ${response.status}`);
  }

  return response.json();
}

// Company standard: language switch is stateful and persisted locally
// to keep user preference across sessions.
async function switchLanguage(lang) {
  const status = document.getElementById("status");
  const normalized = normalizeLang(lang);

  try {
    const content = await loadContent(normalized);
    applyContent(content);
    const publicUrl = getPublicUrlForLang(content, normalized);
    setLinkHref("#canonical-link", publicUrl);
    setMetaTag('meta[property="og:url"]', publicUrl);
    setMetaTag('meta[property="og:locale"]', normalized === "pt-BR" ? "pt_BR" : "en_US");
    setStructuredData(content, normalized);
    updateBrowserUrl(normalized);
    setActiveLangButton(normalized);
    window.localStorage.setItem(LANG_STORAGE_KEY, normalized);
    if (status) {
      status.textContent = "";
    }
  } catch (error) {
    if (status) {
      const prefix = currentUi?.loadErrorPrefix ||
        "Failed to load content";
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
