import { performance } from "node:perf_hooks";

const siteUrl = process.env.MONITOR_URL || "https://nullcipherr.github.io/Mercury-Server/";
const thresholdMs = Number(process.env.MONITOR_TTFB_THRESHOLD_MS || 1200);

async function main() {
  const start = performance.now();
  const response = await fetch(siteUrl, { redirect: "follow" });
  const firstByteMs = performance.now() - start;

  if (!response.ok) {
    throw new Error(`Uptime check falhou com status ${response.status}`);
  }

  if (firstByteMs > thresholdMs) {
    throw new Error(
      `TTFB acima do limite: ${firstByteMs.toFixed(2)}ms (limite: ${thresholdMs}ms)`
    );
  }

  process.stdout.write(
    `Uptime OK | status=${response.status} | ttfb=${firstByteMs.toFixed(2)}ms | limite=${thresholdMs}ms\n`
  );
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
