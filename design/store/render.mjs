// Renders every store image from shot.html at its exact pixel size.
// Usage: node render.mjs [filter]  (env PPTR_DIR = node_modules dir with puppeteer-core,
//                                   CHROME = Chromium executable; macOS sips for PNG output)
import { createRequire } from 'node:module';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const here = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(path.join(process.env.PPTR_DIR, 'noop.js'));
const puppeteer = require('puppeteer-core');

const NAMES = ['01-workspace', '02-textbook-answers', '03-inspector', '04-step-by-step', '05-keypad', '06-tablets-foldables'];
// Steps (04) goes second in every set. File names stay as they are, so upload in this order:
const UPLOAD_ORDER = ['01-workspace', '04-step-by-step', '02-textbook-answers', '03-inspector', '05-keypad', '06-tablets-foldables'];
const SETS = [
  { set: 'app-iphone', W: 1320, H: 2868, dir: 'app-store/iphone-6.9' },
  { set: 'app-ipad', W: 2064, H: 2752, dir: 'app-store/ipad-13' },
  { set: 'play-phone', W: 1080, H: 1920, dir: 'google-play/phone' },
  { set: 'play-tab7', W: 1200, H: 1920, dir: 'google-play/tablet-7' },
  { set: 'play-tab10', W: 2560, H: 1600, dir: 'google-play/tablet-10' },
  { set: 'play-desktop', W: 1920, H: 1080, dir: 'google-play/desktop' },
];
const jobs = [];
for (const s of SETS) NAMES.forEach((name, i) => jobs.push({ ...s, n: i + 1, out: path.join(here, s.dir, name + '.png') }));
jobs.push({ set: 'feature', W: 1024, H: 500, n: 1, out: path.join(here, 'google-play/feature-graphic.jpg') });

const only = process.argv[2];
const browser = await puppeteer.launch({
  executablePath: process.env.CHROME, headless: true,
  args: ['--allow-file-access-from-files', '--hide-scrollbars', '--force-color-profile=srgb', '--font-render-hinting=none'],
});
const base = pathToFileURL(path.join(here, 'shot.html')).href;
for (const j of jobs) {
  if (only && !j.out.includes(only)) continue;
  fs.mkdirSync(path.dirname(j.out), { recursive: true });
  const page = await browser.newPage();
  page.on('pageerror', (e) => console.error('  page error:', e.message));
  await page.setViewport({ width: j.W, height: j.H, deviceScaleFactor: 1 });
  await page.goto(`${base}?set=${j.set}&n=${j.n}`, { waitUntil: 'load', timeout: 60000 });
  await page.waitForFunction('window.__ready === true', { timeout: 60000 });
  // Capture as a maximum-quality JPEG (no alpha channel), then store screenshots
  // are re-encoded as 24-bit RGB PNG with macOS sips; the feature graphic stays JPEG.
  const isJpg = j.out.endsWith('.jpg');
  const tmp = isJpg ? j.out : j.out + '.tmp.jpg';
  await page.screenshot({ path: tmp, type: 'jpeg', quality: isJpg ? 95 : 100, clip: { x: 0, y: 0, width: j.W, height: j.H } });
  await page.close();
  if (!isJpg) {
    execFileSync('/usr/bin/sips', ['-s', 'format', 'png', tmp, '--out', j.out], { stdio: 'ignore' });
    fs.unlinkSync(tmp);
  }
  console.log('wrote', path.relative(here, j.out), `${j.W}x${j.H}`);
}
await browser.close();
console.log('upload order:', UPLOAD_ORDER.join(' → '));
