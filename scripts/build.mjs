import { createHash } from "node:crypto";
import { mkdir, readFile, writeFile, rm, readdir, stat, copyFile } from "node:fs/promises";
import { dirname, join, extname } from "node:path";
import { transform } from "esbuild";

const ROOT = process.cwd();
const DIST_DIR = join(ROOT, "dist");
const ASSETS_DIR = join(ROOT, "assets");

function hashContent(content) {
  return createHash("sha256").update(content).digest("hex").slice(0, 10);
}

async function ensureDir(path) {
  await mkdir(dirname(path), { recursive: true });
}

async function writeDistFile(relativePath, content) {
  const fullPath = join(DIST_DIR, relativePath);
  await ensureDir(fullPath);
  await writeFile(fullPath, content);
}

async function copyRecursive(sourceDir, destinationDir, options = {}) {
  const entries = await readdir(sourceDir, { withFileTypes: true });

  for (const entry of entries) {
    const sourcePath = join(sourceDir, entry.name);
    const destinationPath = join(destinationDir, entry.name);
    const relativePath = destinationPath.slice(DIST_DIR.length + 1);

    if (options.skip?.(sourcePath, relativePath, entry)) {
      continue;
    }

    if (entry.isDirectory()) {
      await mkdir(destinationPath, { recursive: true });
      await copyRecursive(sourcePath, destinationPath, options);
      continue;
    }

    await ensureDir(destinationPath);
    await copyFile(sourcePath, destinationPath);
  }
}

async function minifyCss() {
  const sourceCssPath = join(ASSETS_DIR, "css", "styles.css");
  const cssSource = await readFile(sourceCssPath, "utf8");
  const result = await transform(cssSource, {
    loader: "css",
    minify: true,
    target: "es2020"
  });

  const fileName = `styles.${hashContent(result.code)}.css`;
  await writeDistFile(join("assets", "css", fileName), result.code);
  return fileName;
}

async function minifyJs() {
  const sourceJsPath = join(ASSETS_DIR, "js", "main.js");
  const jsSource = await readFile(sourceJsPath, "utf8");
  const result = await transform(jsSource, {
    loader: "js",
    minify: true,
    target: "es2020"
  });

  const fileName = `main.${hashContent(result.code)}.js`;
  await writeDistFile(join("assets", "js", fileName), result.code);
  return fileName;
}

async function minifyJsonAssets() {
  const dataSourceDir = join(ASSETS_DIR, "data");
  const files = await readdir(dataSourceDir);

  for (const fileName of files) {
    if (extname(fileName) !== ".json") {
      continue;
    }

    const sourcePath = join(dataSourceDir, fileName);
    const raw = await readFile(sourcePath, "utf8");
    const minified = JSON.stringify(JSON.parse(raw));
    await writeDistFile(join("assets", "data", fileName), minified);
  }
}

async function buildIndex(cssFileName, jsFileName) {
  const sourceHtml = await readFile(join(ROOT, "index.html"), "utf8");

  const html = sourceHtml
    .replace("assets/css/styles.css", `assets/css/${cssFileName}`)
    .replace("assets/js/main.js", `assets/js/${jsFileName}`);

  await writeDistFile("index.html", html);
}

async function copyRootFiles() {
  const rootFiles = ["robots.txt", "sitemap.xml", ".nojekyll"];

  for (const file of rootFiles) {
    const sourcePath = join(ROOT, file);
    const fileStats = await stat(sourcePath).catch(() => null);
    if (!fileStats || !fileStats.isFile()) {
      continue;
    }

    const content = await readFile(sourcePath);
    await writeDistFile(file, content);
  }
}

async function writeManifest(manifest) {
  const payload = {
    generatedAt: new Date().toISOString(),
    ...manifest
  };

  await writeDistFile("build-manifest.json", `${JSON.stringify(payload, null, 2)}\n`);
}

async function main() {
  await rm(DIST_DIR, { recursive: true, force: true });
  await mkdir(DIST_DIR, { recursive: true });

  const [cssFileName, jsFileName] = await Promise.all([minifyCss(), minifyJs()]);

  await minifyJsonAssets();

  await copyRecursive(ASSETS_DIR, join(DIST_DIR, "assets"), {
    skip: (sourcePath, _relativePath, entry) => {
      if (entry.isDirectory()) {
        return sourcePath.endsWith(join("assets", "css")) ||
          sourcePath.endsWith(join("assets", "js")) ||
          sourcePath.endsWith(join("assets", "data"));
      }

      return false;
    }
  });

  await Promise.all([
    buildIndex(cssFileName, jsFileName),
    copyRootFiles(),
    writeManifest({
      css: `assets/css/${cssFileName}`,
      js: `assets/js/${jsFileName}`
    })
  ]);

  process.stdout.write(`Build concluído em dist/\nCSS: ${cssFileName}\nJS: ${jsFileName}\n`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
