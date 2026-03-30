const SITE_URL = process.env.LIGHTHOUSE_URL || "https://nullcipherr.github.io/Mercury-Server/";

module.exports = {
  ci: {
    collect: {
      numberOfRuns: 3,
      url: [SITE_URL],
      settings: {
        preset: "desktop"
      }
    },
    assert: {
      assertions: {
        "categories:performance": ["warn", { minScore: 0.9 }],
        "categories:accessibility": ["warn", { minScore: 0.95 }],
        "categories:best-practices": ["warn", { minScore: 0.95 }],
        "categories:seo": ["warn", { minScore: 0.95 }]
      }
    },
    upload: {
      target: "temporary-public-storage"
    }
  }
};
