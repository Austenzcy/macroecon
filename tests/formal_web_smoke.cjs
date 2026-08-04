const fs = require('fs');
const http = require('http');
const path = require('path');
const { chromium } = require(path.join(process.env.CODEX_NODE_MODULES, 'playwright'));

const buildRoot = path.resolve(__dirname, '..', 'web_build');
const artifactRoot = path.resolve(__dirname, 'artifacts');
const targetUrl = process.env.FORMAL_WEB_URL || 'http://127.0.0.1:8766/';
fs.mkdirSync(artifactRoot, { recursive: true });

const mime = {
  '.html': 'text/html; charset=utf-8',
  '.js': 'text/javascript; charset=utf-8',
  '.wasm': 'application/wasm',
  '.pck': 'application/octet-stream',
  '.gz': 'application/octet-stream',
  '.png': 'image/png',
};

const server = http.createServer((request, response) => {
  const requestPath = request.url === '/' ? 'index.html' : request.url.split('?')[0].slice(1);
  const filePath = path.resolve(buildRoot, requestPath);
  if (!filePath.startsWith(buildRoot + path.sep) || !fs.existsSync(filePath)) {
    response.writeHead(404);
    response.end();
    return;
  }
  const stat = fs.statSync(filePath);
  response.writeHead(200, {
    'Content-Type': mime[path.extname(filePath)] || 'application/octet-stream',
    'Content-Length': stat.size,
    'Cache-Control': 'no-store',
  });
  fs.createReadStream(filePath).pipe(response);
});

async function openReadyPage(browser, failures, label) {
  const page = await browser.newPage({ viewport: { width: 1280, height: 720 } });
  page.on('pageerror', error => failures.push(`${label} pageerror: ${error.message}`));
  page.on('response', response => {
    const pathname = new URL(response.url()).pathname;
    if (/\/index\.(html|js|wasm|wasm\.gz|pck)$/.test(pathname) && response.status() >= 400) {
      failures.push(`${label} resource ${pathname} returned ${response.status()}`);
    }
  });
  const response = await page.goto(targetUrl, { waitUntil: 'domcontentloaded' });
  if (!response || response.status() !== 200) {
    failures.push(`${label} index did not return 200`);
  }
  await page.waitForFunction(() => !document.getElementById('status'), null, { timeout: 30000 });
  await page.waitForTimeout(700);
  return page;
}

(async () => {
  const failures = [];
  let browser;
  try {
    if (!process.env.FORMAL_WEB_URL) {
      await new Promise(resolve => server.listen(8766, '127.0.0.1', resolve));
    }
    browser = await chromium.launch({
      headless: true,
      executablePath: process.env.BROWSER_EXE || undefined,
    });

    const page = await openReadyPage(browser, failures, 'carousel');
    await page.screenshot({ path: path.join(artifactRoot, 'formal-level-select.png') });
    await page.mouse.move(640, 330);
    await page.mouse.wheel(0, 180);
    await page.waitForTimeout(1800);
    await page.screenshot({ path: path.join(artifactRoot, 'formal-level-locked.png') });
    await page.mouse.click(1090, 628);
    await page.waitForTimeout(220);
    await page.screenshot({ path: path.join(artifactRoot, 'formal-locked-notice.png') });
    await page.waitForTimeout(550);
    await page.mouse.click(1090, 628);
    await page.waitForTimeout(950);
    await page.screenshot({ path: path.join(artifactRoot, 'formal-locked-notice-finished.png') });

    const startPage = await openReadyPage(browser, failures, 'start');
    await startPage.mouse.click(1090, 628);
    await startPage.waitForTimeout(1800);
    await startPage.screenshot({ path: path.join(artifactRoot, 'formal-first-level-entry.png') });
    // Clear the first-entry narrative so the formal globe can be inspected unobstructed.
    for (let step = 0; step < 30; step += 1) {
      await startPage.mouse.click(650, 680);
      await startPage.waitForTimeout(220);
    }
    await startPage.mouse.move(650, 320);
    await startPage.waitForTimeout(350);
    await startPage.screenshot({ path: path.join(artifactRoot, 'formal-first-level-globe.png') });
    await startPage.mouse.down({ button: 'left' });
    await startPage.mouse.move(760, 365, { steps: 10 });
    await startPage.mouse.up({ button: 'left' });
    await startPage.waitForTimeout(550);
    await startPage.screenshot({ path: path.join(artifactRoot, 'formal-first-level-globe-rotation.png') });
    await startPage.mouse.move(650, 320);
    await startPage.mouse.wheel(0, -480);
    await startPage.waitForTimeout(450);
    await startPage.screenshot({ path: path.join(artifactRoot, 'formal-first-level-map-zoom.png') });

    const hudPage = await openReadyPage(browser, failures, 'hud');
    await hudPage.mouse.click(1166, 47);
    await hudPage.waitForTimeout(1500);
    await hudPage.screenshot({ path: path.join(artifactRoot, 'formal-hud-reference-entry.png') });

    // The reference scene intentionally retains the legacy flat map.
    // Keep exercising its hover, wheel zoom, and middle-button pan independently.
    const regionHoverPoints = {
      consumption: [512, 215],
      industry: [795, 225],
      finance: [488, 435],
      government: [795, 460],
    };
    for (const [regionId, point] of Object.entries(regionHoverPoints)) {
      await hudPage.mouse.move(point[0], point[1]);
      await hudPage.waitForTimeout(350);
      await hudPage.screenshot({ path: path.join(artifactRoot, `formal-hud-reference-hover-${regionId}.png`) });
    }
    await hudPage.mouse.move(650, 330);
    await hudPage.mouse.wheel(0, -480);
    await hudPage.waitForTimeout(450);
    await hudPage.screenshot({ path: path.join(artifactRoot, 'formal-hud-reference-zoom.png') });
    await hudPage.mouse.move(650, 330);
    await hudPage.mouse.down({ button: 'middle' });
    await hudPage.mouse.move(760, 390, { steps: 8 });
    await hudPage.mouse.up({ button: 'middle' });
    await hudPage.waitForTimeout(250);
    await hudPage.screenshot({ path: path.join(artifactRoot, 'formal-hud-reference-pan.png') });

    if (failures.length) {
      failures.forEach(failure => console.error(`FORMAL_WEB_FAILURE: ${failure}`));
      process.exitCode = 1;
    } else {
      console.log('FORMAL_WEB_SMOKE_OK');
    }
  } finally {
    if (browser) await browser.close();
    if (server.listening) {
      await new Promise(resolve => server.close(resolve));
    }
  }
})().catch(error => {
  console.error(error);
  process.exitCode = 1;
  if (server.listening) server.close();
});
