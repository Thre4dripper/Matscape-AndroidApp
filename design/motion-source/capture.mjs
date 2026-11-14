// Captures real Matscape app states (driven through the live UI) for the films.
// Writes PNG frames + a manifest with tap points into each composition's assets/.
import { createRequire } from 'node:module';
import { pathToFileURL, fileURLToPath } from 'node:url';
import fs from 'node:fs';
import path from 'node:path';
const here = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(path.join(process.env.PPTR_DIR, 'noop.js'));
const puppeteer = require('puppeteer-core');
const appUrl = pathToFileURL(path.join(here, '..', 'app.html')).href;
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// Steps run inside the page. Each returns an optional tap point (CSS px of the page).
const STEP = {
  line: (i, text) => `(() => { const inp = document.querySelectorAll('.line-input')[${i}]; inp.focus(); inp.value = ${JSON.stringify(text)}; inp.dispatchEvent(new Event('input', { bubbles: true })); inp.blur(); const r = inp.getBoundingClientRect(); return { x: r.left + 40, y: r.top + r.height / 2 }; })()`,
  scrollLine: (i, offset) => `(() => { const sc = document.getElementById('wsScroll'); const li = document.querySelectorAll('.line')[${i}]; sc.scrollTop = li.offsetTop - ${offset}; const inp = li.querySelector('.line-input'); inp.focus(); inp.blur(); return null; })()`,
  click: (sel) => `(() => { const els = [...document.querySelectorAll(${JSON.stringify(sel)})].filter((e) => e.offsetParent !== null); const el = els[0]; const r = el.getBoundingClientRect(); el.click(); return { x: r.left + r.width / 2, y: r.top + r.height / 2 }; })()`,
  scrollHost: (sel, extra) => `(() => { const hosts = [...document.querySelectorAll('#paneDetail .od-scroll, #subScreen .od-scroll')].filter((e) => e.offsetParent !== null); const sc = hosts[0]; const h = sc.querySelector(${JSON.stringify(sel)}); sc.scrollTop = h ? h.offsetTop - 12 + ${extra} : ${extra}; return null; })()`,
  wsTop: () => `(() => { document.getElementById('wsScroll').scrollTop = 0; return null; })()`,
};
async function run(job) {
  const out = path.join(here, job.dir, 'assets');
  fs.mkdirSync(out, { recursive: true });
  const page = await (await browserP).newPage();
  await page.setViewport({ width: job.w, height: job.h, deviceScaleFactor: job.dsf });
  const manifest = [];
  let loaded = null;
  for (const f of job.frames) {
    const url = appUrl + '?' + (f.query || job.query);
    if (url !== loaded) { await page.goto(url, { waitUntil: 'load' }); await page.evaluate(() => document.fonts.ready); await sleep(900); loaded = url; }
    let tap = null;
    for (const s of f.steps || []) { const r = await page.evaluate(s); if (r) tap = r; await sleep(120); }
    await sleep(f.wait || 650);
    await page.evaluate(() => { if (document.activeElement) document.activeElement.blur(); });
    const file = f.name + '.png';
    await page.screenshot({ path: path.join(out, file), type: 'png' });
    manifest.push({ name: f.name, file: 'assets/' + file, tap: tap ? { x: tap.x * job.dsf, y: tap.y * job.dsf } : null });
    console.log(job.dir, f.name);
  }
  fs.writeFileSync(path.join(out, 'frames.json'), JSON.stringify({ width: Math.round(job.w * job.dsf), height: Math.round(job.h * job.dsf), frames: manifest }, null, 2));
  await page.close();
}
const storyFrames = (opts) => [
  { name: 'f01-empty', steps: [STEP.line(0, '')] },
  { name: 'f02-type-c', steps: [STEP.line(0, 'C')] },
  { name: 'f03-type-inv', steps: [STEP.line(0, 'C⁻¹')] },
  { name: 'f04-exact', steps: [STEP.scrollLine(1, opts.scroll1)] },
  { name: 'f05-det-eig', steps: [STEP.scrollLine(3, opts.scroll2)] },
  { name: 'f06-inspect', steps: [STEP.wsTop(), STEP.click('[data-act="inspect-line"]')], wait: 900 },
  { name: 'f07-properties', steps: [STEP.scrollHost('.props', -60)] },
  { name: 'f08-steps', steps: [STEP.click('[data-act="insp-step"][data-k="inverse"]'), STEP.scrollHost('#stepsH', 0)] },
  { name: 'f09-steps-more', steps: [STEP.scrollHost('#stepsH', opts.stepsMore)] },
  { name: 'f10-kp-matrix', steps: opts.closeInspector ? [STEP.click('[data-act="back"]'), STEP.wsTop(), STEP.click('[data-act="kp-tab"][data-tab="mat"]')] : [STEP.click('[data-act="kp-tab"][data-tab="mat"]')], wait: 900 },
  { name: 'f11-kp-fx', steps: [STEP.click('[data-act="kp-tab"][data-tab="fx"]')] },
  { name: 'f12-kp-more', steps: [STEP.click('[data-act="kp-tab"][data-tab="adv"]')] },
];
const base = 'fresh=1&seed=showcase&shot=1&theme=light';
const JOBS = [
  { dir: 'ios-iphone-preview', w: 443, h: 960, dsf: 2, query: base + '&st=54&sb=34&bar=ios', frames: storyFrames({ scroll1: 90, scroll2: 90, stepsMore: 520, closeInspector: true }) },
  { dir: 'ios-ipad-preview', w: 1032, h: 1376, dsf: 1200 / 1032, query: base + '&st=24&sb=20&bar=ios', frames: storyFrames({ scroll1: 60, scroll2: 60, stepsMore: 640, closeInspector: false }) },
  { dir: 'play-promo', w: 412, h: 915, dsf: 2, query: base + '&st=40&sb=24&bar=android', frames: [
    { name: 'p01-empty', steps: [STEP.line(0, '')] },
    { name: 'p02-type-c', steps: [STEP.line(0, 'C')] },
    { name: 'p03-type-inv', steps: [STEP.line(0, 'C⁻¹')] },
    { name: 'p04-inspect', query: base + '&st=40&sb=24&bar=android&demo=inspect&m=A' },
    { name: 'p05-steps', query: base + '&st=40&sb=24&bar=android&demo=steps&m=C&step=inverse' },
    { name: 'p06-keypad', query: base + '&st=40&sb=24&bar=android&kp=adv&active=3' },
  ] },
  { dir: 'play-promo', w: 744, h: 840, dsf: 2, query: base.replace('theme=light', 'theme=dark') + '&st=32&sb=24&bar=android&posture=book&hinge=24', frames: [{ name: 'p07-foldable', steps: [] }] },
  { dir: 'play-promo', w: 1280, h: 800, dsf: 1.5, query: base + '&st=28&sb=24&bar=android', frames: [{ name: 'p08-tablet', steps: [] }] },
];
const browserP = puppeteer.launch({ executablePath: process.env.CHROME, headless: true, args: ['--allow-file-access-from-files', '--hide-scrollbars', '--force-color-profile=srgb'] });
for (const j of JOBS) {
  // play-promo is split across several jobs; keep one manifest per job type.
  if (j.dir === 'play-promo' && j.frames[0].name !== 'p01-empty') {
    const prev = JSON.parse(fs.readFileSync(path.join(here, j.dir, 'assets', 'frames.json'), 'utf8'));
    await run(j);
    const cur = JSON.parse(fs.readFileSync(path.join(here, j.dir, 'assets', 'frames.json'), 'utf8'));
    prev.extra = (prev.extra || []).concat(cur.frames.map((f) => Object.assign(f, { width: cur.width, height: cur.height })));
    fs.writeFileSync(path.join(here, j.dir, 'assets', 'frames.json'), JSON.stringify(prev, null, 2));
  } else await run(j);
}
await (await browserP).close();
