// Exports the Matscape icon set from the SVG sources in brand/icon.
// Opaque store icons are flattened (no alpha); adaptive layers keep transparency.
import { createRequire } from 'node:module';
import { pathToFileURL, fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
const here = path.dirname(fileURLToPath(import.meta.url));
const require = createRequire(path.join(process.env.PPTR_DIR, 'noop.js'));
const puppeteer = require('puppeteer-core');
const out = path.join(here, 'icon', 'export');
fs.mkdirSync(out, { recursive: true });
const jobs = [
  ['icon.svg', 1024, 'app-store-1024.png', false],
  ['icon.svg', 512, 'google-play-512.png', false],
  ['icon-ios-dark.svg', 1024, 'ios-dark-1024.png', false],
  ['icon-ios-tinted.svg', 1024, 'ios-tinted-1024.png', false],
  ['adaptive-background.svg', 432, 'android-adaptive-background-432.png', false],
  ['adaptive-foreground.svg', 432, 'android-adaptive-foreground-432.png', true],
  ['adaptive-monochrome.svg', 432, 'android-adaptive-monochrome-432.png', true],
];
const browser = await puppeteer.launch({ executablePath: process.env.CHROME, headless: true, args: ['--force-color-profile=srgb', '--allow-file-access-from-files'] });
for (const [src, size, name, alpha] of jobs) {
  const page = await browser.newPage();
  await page.setViewport({ width: size, height: size, deviceScaleFactor: 1 });
  await page.goto(pathToFileURL(path.join(here, 'icon', src)).href, { waitUntil: 'load' });
  const dest = path.join(out, name);
  if (alpha) {
    await page.screenshot({ path: dest, type: 'png', omitBackground: true });
  } else {
    const tmp = dest + '.tmp.jpg';
    await page.screenshot({ path: tmp, type: 'jpeg', quality: 100 });
    execFileSync('/usr/bin/sips', ['-s', 'format', 'png', tmp, '--out', dest], { stdio: 'ignore' });
    fs.unlinkSync(tmp);
  }
  await page.close();
  console.log('wrote', name, size);
}
await browser.close();
