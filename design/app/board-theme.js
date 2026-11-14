/* Matscape design pages — Dark mode switch.
   Adds one switch to a board or phone page. It flips the page's own backdrop
   and tells every live app on the page (and the app inside this page, on the
   phone pages) to use the light or dark theme — the same as the app's
   Settings → Theme. The choice is remembered across the design pages. */
(function () {
  'use strict';
  var KEY = 'matscape-board-theme', store = null;
  try { localStorage.setItem('__mbt', '1'); localStorage.removeItem('__mbt'); store = localStorage; } catch (e) { store = null; }
  var saved = store ? store.getItem(KEY) : null;
  var theme = saved || (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light');

  var css = [
    /* board pages: their own chrome tokens go dark */
    ':root[data-board-theme="dark"]:not([data-mbt-inline]) { --stage: #0b0d11; --ink: #eceff4; --ink-2: #b9c0cb; --ink-3: #959dab; --line: #2a303b; --surface: #161920;',
    '  --accent: #8ea8ff; --accent-ink: #a9bcff; --accent-soft: #1e2847; color-scheme: dark; }',
    ':root[data-board-theme="dark"]:not([data-mbt-inline]) body { background-color: var(--stage); }',
    ':root[data-board-theme="dark"] .board .seg { background: #242934; }',
    ':root[data-board-theme="dark"] .board .seg button[aria-pressed="true"] { background: #161920; color: #eceff4; }',
    /* phone pages share token names with the app inside them: only the stage changes */
    ':root[data-board-theme="dark"][data-mbt-inline] { --phone-stage-bg: #0b0d11; }',
    '.mbt { display: inline-flex; align-items: center; gap: 10px; min-height: 40px; padding: 0 12px 0 14px; border-radius: 10px;',
    '  border: 1px solid var(--line, #d3d8df); background: var(--surface, #fff); color: var(--ink, #12151a); cursor: pointer;',
    '  font: 600 14px/1 -apple-system, BlinkMacSystemFont, "SF Pro Text", "Segoe UI", Roboto, system-ui, sans-serif; }',
    '.mbt:focus-visible { outline: 2px solid var(--accent, #1f43c9); outline-offset: 2px; }',
    '.mbt-track { position: relative; width: 34px; height: 20px; border-radius: 999px; background: #c3c9d2; transition: background 200ms cubic-bezier(.2,.8,.2,1); flex: none; }',
    '.mbt-track::after { content: ""; position: absolute; top: 2px; left: 2px; width: 16px; height: 16px; border-radius: 50%; background: #fff;',
    '  box-shadow: 0 1px 2px rgba(0,0,0,.25); transition: transform 200ms cubic-bezier(.2,.8,.2,1); }',
    '.mbt[aria-pressed="true"] .mbt-track { background: var(--accent, #1f43c9); }',
    '.mbt[aria-pressed="true"] .mbt-track::after { transform: translateX(14px); }',
    '.mbt--float { position: fixed; z-index: 50; top: 16px; right: 16px; box-shadow: 0 8px 24px rgba(0,0,0,.12); }',
    '@media (max-width: 479px) { .mbt--float { display: none; } }',
    '@media (hover: hover) { .mbt:hover { border-color: var(--accent, #1f43c9); } }',
    '@media (prefers-reduced-motion: reduce) { .mbt-track, .mbt-track::after { transition: none; } }'
  ].join('\n');
  if (document.getElementById('app')) document.documentElement.setAttribute('data-mbt-inline', '');
  var st = document.createElement('style'); st.textContent = css; document.head.appendChild(st);

  var btn = document.createElement('button');
  btn.type = 'button'; btn.className = 'mbt';
  btn.innerHTML = '<span>Dark mode</span><span class="mbt-track" aria-hidden="true"></span>';
  var slot = document.querySelector('[data-theme-slot]') || document.querySelector('.bar .nav') || document.querySelector('.board-head');
  if (slot) slot.appendChild(btn); else { btn.classList.add('mbt--float'); document.body.appendChild(btn); }

  function send(win) { try { if (win) win.postMessage({ type: 'matscape-theme', theme: theme }, '*'); } catch (e) { /* frame not ready */ } }
  function broadcast() { Array.prototype.forEach.call(document.querySelectorAll('iframe'), function (f) { send(f.contentWindow); }); send(window); }
  function paint() { document.documentElement.setAttribute('data-board-theme', theme); btn.setAttribute('aria-pressed', String(theme === 'dark')); }
  paint();
  // Only push a theme into the apps once one has been chosen here.
  var chosen = !!saved;
  if (chosen) broadcast();
  document.addEventListener('load', function (e) { if (chosen && e.target && e.target.tagName === 'IFRAME') send(e.target.contentWindow); }, true);
  btn.addEventListener('click', function () {
    theme = theme === 'dark' ? 'light' : 'dark'; chosen = true;
    if (store) { try { store.setItem(KEY, theme); } catch (e) { /* full */ } }
    paint(); broadcast();
  });
  window.addEventListener('storage', function (e) { if (e.key === KEY && e.newValue && e.newValue !== theme) { theme = e.newValue; chosen = true; paint(); broadcast(); } });
})();
