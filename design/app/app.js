/* Matscape 2 — app prototype (shared by the iPhone and Android entries). */
(function () {
  'use strict';
  const E = window.MatEngine;
  const $ = (sel, root = document) => root.querySelector(sel);
  const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));
  const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
  const uid = () => Math.random().toString(36).slice(2, 10);

  const appEl = document.getElementById('app');
  const screenHost = document.querySelector('[data-phone-screen]') || document.body;
  const overlayRoot = document.createElement('div');
  overlayRoot.className = 'overlay-root';
  screenHost.appendChild(overlayRoot);

  /* ---------- icons (one stroke family, 24px grid, 1.75 stroke) ---------- */
  const ICONS = {
    menu: 'M4 7h16M4 12h16M4 17h16',
    book: 'M5 4.5h11.5A1.5 1.5 0 0 1 18 6v13.5H6.5A1.5 1.5 0 0 1 5 18V4.5ZM5 18a1.5 1.5 0 0 1 1.5-1.5H18M9 8.5h5',
    back: 'M15 18l-6-6 6-6',
    chev: 'M9 18l6-6-6-6',
    down: 'M6 9l6 6 6-6',
    up: 'M6 15l6-6 6 6',
    plus: 'M12 5v14M5 12h14',
    close: 'M6 6l12 12M18 6L6 18',
    trash: 'M4 7h16M10 11v6M14 11v6M6 7l1 13h10l1-13M9 7V4h6v3',
    copy: 'M9 9h11v11H9zM5 15H4V4h11v1',
    search: 'M11 18a7 7 0 1 0 0-14 7 7 0 0 0 0 14zM20 20l-4.2-4.2',
    eye: 'M2 12s3.5-7 10-7 10 7 10 7-3.5 7-10 7S2 12 2 12zM12 15a3 3 0 1 0 0-6 3 3 0 0 0 0 6z',
    save: 'M12 4v11M7 10l5 5 5-5M5 20h14',
    backspace: 'M21 5H9l-6 7 6 7h12zM17 9l-6 6M11 9l6 6',
    left: 'M15 18l-6-6 6-6',
    right: 'M9 18l6-6-6-6',
    enter: 'M20 5v7a3 3 0 0 1-3 3H5M9 11l-4 4 4 4',
    clock: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 7v5l3 2',
    sliders: 'M4 6h9M17 6h3M15 4v4M4 12h3M11 12h9M9 10v4M4 18h11M19 18h1M17 16v4',
    help: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM9.5 9.2a2.5 2.5 0 1 1 3.4 2.3c-.6.3-.9.8-.9 1.5v.5M12 16.8v.2',
    folder: 'M3 6.5A1.5 1.5 0 0 1 4.5 5H9l2 2h8.5A1.5 1.5 0 0 1 21 8.5v9a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 17.5z',
    check: 'M5 12.5l4.5 4.5L19 7',
    minus: 'M6 12h12',
    alert: 'M12 4l9 16H3zM12 10v4M12 17v.2',
    info: 'M12 21a9 9 0 1 0 0-18 9 9 0 0 0 0 18zM12 11v5M12 7.8v.2',
    grid: 'M4 4h16v16H4zM4 9.3h16M4 14.7h16M9.3 4v16M14.7 4v16',
    edit: 'M4 20h4L19 9l-4-4L4 16v4zM13.5 6.5l4 4',
    steps: 'M9 6h11M9 12h11M9 18h11M4.5 6h.01M4.5 12h.01M4.5 18h.01',
  };
  const icon = (n) => `<svg class="od-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="${ICONS[n]}"/></svg>`;
  /* drag grip: a block of dots (same family, heavier stroke so the dots read) */
  const gripIcon = () => '<svg class="od-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3.2" stroke-linecap="round" aria-hidden="true"><path d="M9 6h.01M15 6h.01M9 12h.01M15 12h.01M9 18h.01M15 18h.01"/></svg>';

  /* ---------- storage (falls back to memory when blocked) ---------- */
  /* Demo / screenshot mode (?fresh=1&seed=showcase&demo=…): starts from seed data,
     never touches saved work, and can open straight into a given state. */
  const DEMO = new URLSearchParams(location.search);
  const FRESH = DEMO.has('fresh');
  const storage = FRESH ? null : (() => { try { const k = '__ms'; localStorage.setItem(k, '1'); localStorage.removeItem(k); return localStorage; } catch (e) { return null; } })();
  const KEY = 'matscape-2-prototype';
  let saveTimer = 0;
  const persist = () => { if (!storage) return; clearTimeout(saveTimer); saveTimer = setTimeout(() => { try { storage.setItem(KEY, JSON.stringify(state)); } catch (e) { /* storage full or blocked */ } }, 250); };

  /* ---------- seed content ---------- */
  const mx = (name, rows) => ({ id: uid(), name, rows: rows.length, cols: rows[0].length, cells: rows.map((r) => r.map(String)) });
  const lines = (arr) => arr.map((text) => ({ id: uid(), text }));
  /* The twelve sample workspaces of the shipped app: a showcase first, then one
     per topic, in the order someone would learn them. */
  const SAMPLES = [
    ['Rotations & eigenvalues', [['A', [[4, 1, 2], [1, 3, 0], [2, 0, 5]]], ['B', [[1, 2, 3], [4, 5, 6]]], ['C', [[2, 0, 1], [1, 3, 2], [1, 1, 2]]], ['R', [['cos(π/4)', '−sin(π/4)'], ['sin(π/4)', 'cos(π/4)']]]], ['det(A)', 'C⁻¹', 'BA', 'R²', 'eig(A)', 'sin(Bπ/6)', 'M = BBᵀ', 'A + B']],
    ['Basics — add, multiply, transpose', [['A', [[1, 2], [3, 4]]], ['B', [[2, 0], [1, 3]]], ['C', [[1, 2, 3], [4, 5, 6]]]], ['A + B', 'A − B', '3A', 'AB', 'BA', 'AC', 'Cᵀ', 'A⁻¹', 'A²', 'A ∘ B', 'A / B', 'k = 2', 'k·A + I']],
    ['Determinant, trace, rank & norms', [['A', [[2, -1, 0], [-1, 2, -1], [0, -1, 2]]], ['S', [[1, 2], [2, 4]]]], ['det(A)', '|A|', 'tr(A)', 'rank(A)', 'det(S)', 'rank(S)', 'norm(A)', 'norm1(A)', 'norminf(A)', 'norm2(A)', 'cond(A)']],
    ['Building matrices', [['A', [[1, 2, 3], [4, 5, 6], [7, 8, 10]]], ['B', [[1], [2], [3]]]], ['[1, 2; 3, 4]', 'I(3)', 'A − 2I', 'zeros(2, 3)', 'ones(2, 2)', 'diag([1, 2, 3])', 'diag(A)', 'aug(A, B)', 'sub(A, 1, 1)', 'row(A, 2)', 'column(A, 3)', 'kron([1, 2; 3, 4], I(2))']],
    ['Minors, cofactors & adjugate', [['A', [[1, 2, 3], [0, 1, 4], [5, 6, 0]]]], ['minors(A)', 'cof(A)', 'adj(A)', 'det(A)', 'adj(A) / det(A)', 'A⁻¹']],
    ['Linear systems', [['A', [[2, 1, -1], [-3, -1, 2], [-2, 1, 2]]], ['B', [[8], [-11], [-3]]]], ['solve(A, B)', 'rref(aug(A, B))', 'A⁻¹B', 'N = [1, 2; 2, 4]', 'rank(N)', 'null(N)', 'colsp(N)', 'pinv(N)', 'solve(N, [3; 6])']],
    ['Vectors — dot and cross', [['U', [[1], [2], [3]]], ['V', [[4], [5], [6]]]], ['dot(U, V)', 'cross(U, V)', 'UᵀV', 'UVᵀ', 'norm(U)', 'U / norm(U)', 'dot(U, cross(U, V))']],
    ['Decompositions — LU, QR, Cholesky, SVD', [['A', [[4, 12, -16], [12, 37, -43], [-16, -43, 98]]], ['B', [[1, 2], [3, 4], [5, 6]]]], ['lu(A)', 'qr(A)', 'chol(A)', 'svd(B)', 'qr(B)']],
    ['Eigenvalues & eigenvectors', [['A', [[4, 1], [2, 3]]], ['S', [[2, 1, 0], [1, 2, 1], [0, 1, 2]]], ['R', [[0, -1], [1, 0]]]], ['eig(A)', 'eigvec(A)', 'charpoly(A)', 'det(A − 5I)', 'eig(S)', 'eig(R)', 'tr(A)', 'det(A)']],
    ['Matrix functions — expm, sinm, sqrtm', [['D', [[1, 0], [0, 2]]], ['S', [[0, -1], [1, 0]]], ['P', [[5, 4], [4, 5]]]], ['expm(D)', 'expm(π/2·S)', 'sinm(S)', 'cosm(S)', 'sqrtm(P)', 'P^0.5', 'sqrtm(P)²']],
    ['Trig inside matrices', [['T', [['cos(30°)', '−sin(30°)', '0'], ['sin(30°)', 'cos(30°)', '0'], ['0', '0', '1']]], ['S', [[0, -1], [1, 0]]]], ['TᵀT', 'det(T)', 'sin(T)', 'expm(π/2·S)', 'sinm(S)', 'svd(T)']],
    ['Numbers, fractions & exact results', [['A', [['1/2', '1/3'], ['√2', 'π']]]], ['1/3 + 1/6', '√8', '∛27', 'sin(π/6)', 'cos(45°)', 'asin(1/2)', 'ln(e)', 'log(1000)', '5!', 'mod(17, 5)', 'abs(−3.5)', 'round(2.6)', 'x = 2√3', 'x²', '2A']],
  ];
  const sampleWorkspace = ([name, mats, ls], k = 0) => ({
    id: uid(), name, updated: Date.now() - 1000 * k,
    matrices: mats.map(([n, rows]) => mx(n, rows.map((r) => r.map((x) => String(x).replace(/^-/, '−'))))),
    lines: lines(ls),
  });
  function seedWorkspaces() { return SAMPLES.map(sampleWorkspace); }
  const DEFAULT_SETTINGS = { theme: 'system', angle: 'rad', display: 'exact', precision: 4, defRows: 3, defCols: 3, defFill: 'zero', copyAs: 'plain' };
  let state = null;
  if (storage) { try { state = JSON.parse(storage.getItem(KEY)); } catch (e) { state = null; } }
  if (DEMO.get('seed') === 'showcase') {
    state = { workspaces: [{
      id: uid(), name: 'Linear algebra · week 6', updated: Date.now(),
      matrices: [
        mx('A', [[4, 1, 2], [1, 3, 0], [2, 0, 5]]),
        mx('B', [[1, 2, 3], [4, 5, 6]]),
        mx('C', [[2, 0, 1], [1, 3, 2], [1, 1, 2]]),
        mx('R', [['cos(π/4)', '−sin(π/4)'], ['sin(π/4)', 'cos(π/4)']]),
      ],
      lines: lines(['C⁻¹', 'sin(Bπ/6)', 'det(A)', 'eig([2, 1; 1, 2])', 'R²', 'lu(C)']),
    }], currentId: null, history: [] };
  }
  if (!state || !Array.isArray(state.workspaces) || !state.workspaces.length) {
    const t = Date.now();
    state = {
      workspaces: seedWorkspaces(), currentId: null,
      history: [
        { text: 'det([2, 1; 1, 3])', summary: '5', ts: t - 36e5 * 3 },
        { text: 'eig([2, 1; 1, 2])', summary: 'λ = 3, 1', ts: t - 36e5 * 26 },
        { text: 'sin(30°)', summary: '1/2', ts: t - 36e5 * 50 },
      ],
    };
  }
  state.settings = Object.assign({}, DEFAULT_SETTINGS, state.settings || {});
  if (!state.workspaces.some((w) => w.id === state.currentId)) state.currentId = state.workspaces[0].id;
  state.history = state.history || [];
  const ws = () => state.workspaces.find((w) => w.id === state.currentId);

  const ui = {
    activeLineId: null, kpTab: 'num', kpCollapsed: false,
    screen: null, params: null, returnFocus: null, wsScroll: 0,
    libGroup: 'All', libQuery: '', inspStep: 'det', inspDec: 'lu',
    editor: null, layers: [],
    st: { key: null }, autoPart: {}, drag: null,
  };
  ui.activeLineId = (ws().lines[0] || {}).id || null;

  /* ---------- theme ---------- */
  const mq = window.matchMedia ? window.matchMedia('(prefers-color-scheme: dark)') : null;
  function applyTheme() {
    const t = state.settings.theme === 'system' ? (mq && mq.matches ? 'dark' : 'light') : state.settings.theme;
    document.documentElement.dataset.theme = t;
  }
  if (mq && mq.addEventListener) mq.addEventListener('change', applyTheme);
  applyTheme();

  /* ---------- evaluation ---------- */
  let cache = { mats: new Map(), lines: new Map() };
  function evaluateAll() {
    const w = ws(), angle = state.settings.angle, vars = {}, mats = new Map();
    const matrixNames = new Set(w.matrices.map((m) => m.name));
    for (const m of w.matrices) {
      const data = []; let bad = null;
      for (let i = 0; i < m.rows; i++) {
        const row = [];
        for (let j = 0; j < m.cols; j++) {
          const r = E.evalScalar(String((m.cells[i] || [])[j] ?? ''), angle);
          if (r.ok) row.push(r.value); else { row.push(NaN); if (!bad) bad = { i, j, error: r.error }; }
        }
        data.push(row);
      }
      const res = bad ? { ok: false, bad } : { ok: true, value: Object.assign(E.mat(data), { label: m.name }) };
      mats.set(m.id, res);
      vars[m.name] = res.ok ? res.value : { type: 'invalid', name: m.name, where: `Row ${bad.i + 1}, column ${bad.j + 1}: ${bad.error}.` };
    }
    const env = { vars, angle, matrixNames }, out = new Map();
    const pending = w.lines.filter((l) => E.splitAssignment(l.text));
    let progress = true;
    while (pending.length && progress) {
      progress = false;
      for (let k = 0; k < pending.length; k++) {
        const l = pending[k], r = E.evaluate(l.text, env);
        if (r.ok || !r.unknown) {
          out.set(l.id, r);
          if (r.ok && r.assign && (E.isMat(r.value) || E.isNum(r.value))) vars[r.assign] = E.isMat(r.value) ? Object.assign(r.value, { label: r.assign }) : r.value;
          pending.splice(k, 1); k--; progress = true;
        }
      }
    }
    pending.forEach((l) => out.set(l.id, E.evaluate(l.text, env)));
    w.lines.forEach((l) => { if (!out.has(l.id)) out.set(l.id, E.evaluate(l.text, env)); });
    cache = { mats, lines: out, env: { vars, angle } };
  }

  /* ---------- formatting ---------- */
  const fracHTML = (top, den) => `<span class="frac"><span>${top}</span><span>${den}</span></span>`;
  function numHTML(x) {
    const s = state.settings, d = E.describe(x, s.display, s.precision), sign = d.neg ? '−' : '';
    switch (d.kind) {
      case 'special': return esc(d.text);
      case 'int': return sign + d.n;
      case 'frac': return sign + fracHTML(d.n, d.d);
      case 'surd': { const top = `${d.n === 1 ? '' : d.n}√<span class="rad">${d.k}</span>`; return sign + (d.d === 1 ? top : fracHTML(top, d.d)); }
      case 'pi': { const top = `${d.n === 1 ? '' : d.n}π`; return sign + (d.d === 1 ? top : fracHTML(top, d.d)); }
      default: return sign + (d.text != null ? d.text : `<span class="sci">${d.mant}×10<sup>${d.exp}</sup></span>`);
    }
  }
  const numText = (x) => E.plain(x, state.settings.display, state.settings.precision);
  function complexParts(z, f) {
    if (E.isNum(z)) return f(z);
    const re = Math.abs(z.re) < 1e-11 ? 0 : z.re, im = Math.abs(z.im);
    const ip = (Math.abs(im - 1) < 1e-12 ? '' : f(im)) + 'i';
    if (re === 0) return (z.im < 0 ? '−' : '') + ip;
    return `${f(re)} ${z.im < 0 ? '−' : '+'} ${ip}`;
  }
  const complexHTML = (z) => complexParts(z, numHTML).replace(/i$/, '<i>i</i>');
  const complexText = (z) => complexParts(z, numText);
  function matrixHTML(M, opts = {}) {
    const cells = [], aria = [];
    M.data.forEach((row, i) => {
      row.forEach((x, j) => cells.push(`<span class="mx-c${opts.aug && j === opts.aug ? ' aug' : ''}">${numHTML(x)}</span>`));
      aria.push(`row ${i + 1}: ${row.map(numText).join(', ')}`);
    });
    return `<span class="mx" style="--cols:${M.cols}" role="img" aria-label="${M.rows} by ${M.cols} matrix. ${esc(aria.join('; '))}">${cells.join('')}</span>`;
  }
  function previewHTML(M) {
    const r = Math.min(M.rows, 3), c = Math.min(M.cols, 3), more = M.cols > 3, cells = [];
    for (let i = 0; i < r; i++) { for (let j = 0; j < c; j++) cells.push(`<span class="mx-c">${numHTML(M.data[i][j])}</span>`); if (more) cells.push('<span class="mx-c">⋯</span>'); }
    if (M.rows > 3) for (let j = 0; j < c + (more ? 1 : 0); j++) cells.push('<span class="mx-c">⋮</span>');
    return `<span class="mx" style="--cols:${c + (more ? 1 : 0)}" aria-hidden="true">${cells.join('')}</span>`;
  }
  function polyHTML(cf, v = 'λ') {
    const n = cf.length - 1, terms = [];
    cf.forEach((c, k) => {
      const p = n - k; if (Math.abs(c) < 1e-11) return;
      const a = Math.abs(c), coef = Math.abs(a - 1) < 1e-12 && p > 0 ? '' : numHTML(a);
      const varPart = p === 0 ? '' : p === 1 ? `<i>${v}</i>` : `<i>${v}</i><sup>${p}</sup>`;
      terms.push({ neg: c < 0, s: coef + varPart });
    });
    if (!terms.length) return '0';
    return terms.map((t, i) => (i === 0 ? (t.neg ? '−' : '') + t.s : ` ${t.neg ? '−' : '+'} ${t.s}`)).join('');
  }
  const matText = (M) => `[${M.data.map((r) => r.map((x) => cellText(x)).join(', ')).join('; ')}]`;
  function cellText(x) {
    const d = E.describe(x, 'exact');
    if (d.kind !== 'dec' && d.kind !== 'special') return E.plain(x, 'exact');
    let s = String(Number(x.toPrecision(12)));
    if (/e/.test(s)) s = x.toFixed(14).replace(/0+$/, '').replace(/\.$/, '');
    return s.replace('-', '−');
  }
  function resultSummary(v) {
    if (E.isNum(v)) return numText(v);
    if (E.isMat(v)) return `${v.rows}×${v.cols} matrix`;
    if (v.type === 'list') return `λ = ${v.items.map(complexText).join(', ')}`;
    if (v.type === 'multi') return v.relation || `${v.parts.length} results`;
    if (v.type === 'poly') return 'Characteristic polynomial';
    return v.text || '';
  }

  /* ---------- result rendering ---------- */
  const errorHTML = (msg, hint) => `<div class="res-error">${icon('alert')}<div><p class="err-msg">${esc(msg)}</p>${hint ? `<p class="err-hint">${esc(hint)}</p>` : ''}</div></div>`;
  /* A value on its own (just "A" or "5") has nothing to work out, so no Steps. */
  const stepsBtnHTML = (line) => (E.hasSteps(line.text, cache.env)
    ? `<button type="button" class="text-btn res-btn" data-act="steps-line" data-line="${line.id}">${icon('steps')}Steps</button>` : '');
  const copyBtnHTML = (id, what) => `<button type="button" class="icon-btn icon-btn--sm" data-act="copy-line" data-line="${id}" aria-label="Copy ${what}">${icon('copy')}</button>`;
  /* Any value, typeset (used by results, the Steps screen and library examples). */
  function valueHTML(v) {
    if (E.isNum(v)) return `<span class="res-value">${numHTML(v)}</span>`;
    if (E.isMat(v)) return matrixHTML(v);
    if (v.type === 'list') return `<span class="res-list res-value">${v.items.map((z, i) => `<span><i>λ</i><span class="sub">${i + 1}</span> = ${complexHTML(z)}</span>`).join('')}</span>`;
    if (v.type === 'multi') return `<span class="res-parts">${v.parts.map((p) => `<span class="res-part res-part--static"><span class="res-part-label">${esc(p.label)}</span><span class="res-eq">=</span>${matrixHTML(p.value)}</span>`).join('')}</span>`;
    if (v.type === 'poly') return `<span class="res-value">${polyHTML(v.coeffs)}</span>`;
    return `<span class="res-hint">${esc(v.text || '')}</span>`;
  }
  function resultHTML(line) {
    const res = cache.lines.get(line.id);
    if (!line.text.trim() || !res) return '';
    if (res.empty) return `<p class="res-hint">Finish the expression after “=”.</p>`;
    if (!res.ok) return errorHTML(res.error, res.hint);
    const v = res.value, id = line.id, steps = stepsBtnHTML(line);
    const notes = (res.warnings || []).map((w) => `<p class="res-note">${icon('info')}<span>${esc(w)}</span></p>`).join('');
    let body = '';
    if (E.isNum(v)) {
      body = `<div class="res-row"><span class="res-eq">=</span><div class="res-scroll"><span class="res-value">${numHTML(v)}</span></div>${steps}${copyBtnHTML(id, 'result')}</div>`;
    } else if (E.isMat(v)) {
      body = `<div class="res-row"><span class="res-eq">=</span><div class="res-scroll">${matrixHTML(v)}</div></div>
        <div class="res-meta"><span class="dims od-truncate">${v.rows}×${v.cols}${res.assign ? ` · saved as ${esc(res.assign)}` : ''}</span>
          ${steps}
          <button type="button" class="text-btn res-btn" data-act="inspect-line" data-line="${id}">${icon('eye')}Inspect</button>
          <button type="button" class="text-btn res-btn" data-act="save-line" data-line="${id}">${icon('save')}Save</button>
          ${copyBtnHTML(id, 'matrix')}
        </div>`;
    } else if (v.type === 'list') {
      body = `<div class="res-row"><div class="res-scroll"><div class="res-list res-value">${v.items.map((z, i) => `<span><i>λ</i><span class="sub">${i + 1}</span> = ${complexHTML(z)}</span>`).join('')}</div></div>${steps}${copyBtnHTML(id, 'eigenvalues')}</div>`;
    } else if (v.type === 'multi') {
      body = `${v.relation ? `<span class="res-relation">${esc(v.relation)} · tap a matrix to inspect it</span>` : '<span class="res-relation">Tap a matrix to inspect it</span>'}
        <div class="res-scroll"><div class="res-parts">${v.parts.map((p, i) => `<button type="button" class="res-part" data-act="inspect-part" data-line="${id}" data-part="${i}"><span class="res-part-label">${esc(p.label)}</span><span class="res-eq">=</span>${matrixHTML(p.value)}</button>`).join('')}</div></div>
        ${steps ? `<div class="res-meta res-meta--end">${steps}${copyBtnHTML(id, 'result')}</div>` : ''}`;
    } else if (v.type === 'poly') {
      body = `<div class="res-row"><span class="res-eq">=</span><div class="res-scroll"><span class="res-value">${polyHTML(v.coeffs)}</span></div>${steps}${copyBtnHTML(id, 'polynomial')}</div><span class="res-relation">p(λ) = det(λI − A)</span>`;
    } else if (v.type === 'text') {
      body = `<div class="res-row"><p class="res-hint od-fill">${esc(v.text)}</p>${steps}</div>`;
    }
    return `<div class="res">${body}${notes}</div>`;
  }

  /* ---------- keypad definition ---------- */
  const K = (label, ins, o = {}) => Object.assign({ label, ins }, o);
  const dg = (n) => K(n, n);
  const op = (l, ins, aria) => K(l, ins == null ? l : ins, { cls: 'key--op', aria });
  const fn = (l, name, aria) => K(l, name + '()', { cls: 'key--fn', back: 1, aria });
  const mk = (l, ins, aria, back) => K(l, ins, { cls: 'key--fn is-math', aria, back });
  const KEYPAD = {
    num: { label: '123', rows: [
      [dg('7'), dg('8'), dg('9'), op('÷', '÷', 'Divide'), op('('), op(')')],
      [dg('4'), dg('5'), dg('6'), op('×', '·', 'Multiply'), op('[', '[', 'Open matrix bracket'), op(']', ']', 'Close matrix bracket')],
      [dg('1'), dg('2'), dg('3'), op('−', '−', 'Minus'), op('x<sup>□</sup>', '^', 'Power'), op(',', ', ', 'Comma — next entry')],
      [dg('0'), dg('.'), K('π', 'π', { cls: 'key--op' }), op('+', '+', 'Plus'), op(';', '; ', 'Semicolon — next row'), op('√', '√', 'Square root')],
    ] },
    mat: { label: 'Matrix', rows: [
      [fn('det', 'det', 'Determinant'), fn('tr', 'tr', 'Trace'), fn('rank', 'rank', 'Rank'), mk('<i>A</i><sup>T</sup>', 'ᵀ', 'Transpose'), mk('<i>A</i><sup>−1</sup>', '⁻¹', 'Inverse'), mk('<i>A</i><sup>2</sup>', '²', 'Squared')],
      [fn('adj', 'adj', 'Adjugate'), fn('cof', 'cof', 'Cofactor matrix'), fn('minors', 'minors', 'Matrix of minors'), fn('rref', 'rref', 'Reduced row echelon form'), fn('null', 'null', 'Null space'), fn('colsp', 'colsp', 'Column space')],
      [mk('I(<i>n</i>)', 'I()', 'Identity matrix', 1), fn('diag', 'diag', 'Diagonal'), fn('zeros', 'zeros', 'Zero matrix'), fn('ones', 'ones', 'Matrix of ones'), fn('aug', 'aug', 'Augment side by side'), fn('sub', 'sub', 'Submatrix without row i, column j')],
      [fn('dot', 'dot', 'Dot product'), fn('cross', 'cross', 'Cross product'), fn('kron', 'kron', 'Kronecker product'), mk('∘', '∘', 'Entrywise product'), fn('solve', 'solve', 'Solve A x = b'), fn('norm', 'norm', 'Frobenius norm')],
    ] },
    fx: { label: 'f(x)', rows: [
      [fn('sin', 'sin'), fn('cos', 'cos'), fn('tan', 'tan'), fn('sec', 'sec'), fn('csc', 'csc'), fn('cot', 'cot')],
      [K('sin<sup>−1</sup>', 'asin()', { cls: 'key--fn', back: 1, aria: 'Inverse sine' }), K('cos<sup>−1</sup>', 'acos()', { cls: 'key--fn', back: 1, aria: 'Inverse cosine' }), K('tan<sup>−1</sup>', 'atan()', { cls: 'key--fn', back: 1, aria: 'Inverse tangent' }), fn('sinh', 'sinh'), fn('cosh', 'cosh'), fn('tanh', 'tanh')],
      [fn('ln', 'ln', 'Natural log'), fn('log', 'log', 'Log base 10'), mk('<i>e</i><sup>x</sup>', 'exp()', 'e to the power', 1), mk('√', '√', 'Square root'), mk('∛', '∛', 'Cube root'), mk('<i>n</i>!', '!', 'Factorial')],
      [mk('π', 'π', 'Pi'), mk('<i>e</i>', 'e', 'Euler’s number'), mk('°', '°', 'Degrees'), mk('=', ' = ', 'Name a value'), K('', '', { op: 'angle', cls: 'key--toggle span-2c' })],
    ] },
    adv: { label: 'More', rows: [
      [fn('eig', 'eig', 'Eigenvalues'), fn('eigvec', 'eigvec', 'Eigenvectors'), mk('<i>p</i>(<i>λ</i>)', 'charpoly()', 'Characteristic polynomial', 1), fn('lu', 'lu', 'LU decomposition'), fn('qr', 'qr', 'QR decomposition'), fn('chol', 'chol', 'Cholesky decomposition')],
      [fn('svd', 'svd', 'Singular value decomposition'), fn('pinv', 'pinv', 'Pseudo-inverse'), fn('cond', 'cond', 'Condition number'), mk('<i>e</i><sup><i>A</i></sup>', 'expm()', 'Matrix exponential', 1), fn('sinm', 'sinm', 'Matrix sine'), fn('cosm', 'cosm', 'Matrix cosine')],
      [fn('sqrtm', 'sqrtm', 'Matrix square root'), mk('‖·‖<sub>1</sub>', 'norm1()', '1-norm', 1), mk('‖·‖<sub>2</sub>', 'norm2()', 'Spectral norm', 1), mk('‖·‖<sub>∞</sub>', 'norminf()', 'Infinity norm', 1), mk('|<i>x</i>|', '||', 'Absolute value or determinant bars', 1), K('mod', 'mod(, )', { cls: 'key--fn', back: 3, aria: 'Modulo' })],
      [fn('round', 'round'), fn('floor', 'floor'), fn('ceil', 'ceil'), fn('row', 'row', 'Row i of a matrix'), fn('column', 'column', 'Column j of a matrix'), fn('abs', 'abs', 'Absolute value of each entry')],
    ] },
  };
  const angleLabel = () => (state.settings.angle === 'rad'
    ? '<span class="on">RAD</span>&nbsp;·&nbsp;<span class="off">DEG</span>'
    : '<span class="off">RAD</span>&nbsp;·&nbsp;<span class="on">DEG</span>');
  function keyHTML(k) {
    const attrs = [`data-act="key"`];
    if (k.op) attrs.push(`data-op="${k.op}"`);
    if (k.ins != null && !k.op) attrs.push(`data-ins="${esc(k.ins)}"`);
    if (k.back) attrs.push(`data-back="${k.back}"`);
    const aria = k.op === 'angle' ? `Angle unit: ${state.settings.angle === 'rad' ? 'radians' : 'degrees'}. Switch to ${state.settings.angle === 'rad' ? 'degrees' : 'radians'}` : k.aria;
    if (aria) attrs.push(`aria-label="${esc(aria)}"`);
    return `<button type="button" class="key ${k.cls || ''}" ${attrs.join(' ')}>${k.op === 'angle' ? angleLabel() : k.label}</button>`;
  }

  /* ---------- workspace screen ---------- */
  const visibleEl = (sel) => $$(sel, appEl).find((el) => el.offsetParent !== null) || null;
  const NAV = [['workspaces', 'folder', 'Workspaces'], ['history', 'clock', 'History'], ['library', 'book', 'Operations library'], ['settings', 'sliders', 'Settings'], ['help', 'help', 'Help & tips']];
  appEl.innerHTML = `
    <aside class="pane-side" id="paneSide" aria-label="Navigation and matrices">
      <div class="side-head"><span class="wordmark">Mat<i>scape</i></span><span class="ws-name od-truncate" id="sideWsName"></span></div>
      <nav class="side-nav" aria-label="Main">${NAV.map(([to, ic, label]) => `<button type="button" class="nav-item" data-act="go" data-to="${to}">${icon(ic)}${label}</button>`).join('')}</nav>
      <section class="side-mx" aria-labelledby="sideMxHead">
        <div class="section-head"><h2 id="sideMxHead">Matrices</h2><button type="button" class="text-btn" data-act="new-matrix">${icon('plus')}New</button></div>
        <div class="mx-list" id="mxList"></div>
      </section>
    </aside>
    <section class="screen od-screen ws-main" data-screen="workspace" aria-label="Workspace">
      <header class="topbar" id="wsBar">
        <button type="button" class="icon-btn" data-act="open-drawer" aria-label="Open menu">${icon('menu')}</button>
        <button type="button" class="ws-title" data-act="go" data-to="workspaces">
          <span class="sr-only">Switch workspace. Current:</span>
          <span class="wordmark" aria-hidden="true">Mat<i>scape</i></span>
          <span class="ws-name od-truncate" id="wsName"></span>
        </button>
        <button type="button" class="icon-btn" data-act="go" data-to="library" aria-label="Operations library">${icon('book')}</button>
      </header>
      <div class="od-scroll ws-scroll" id="wsScroll">
        <section class="ws-section ws-section--mx" aria-labelledby="mxHead">
          <div class="section-head"><h2 id="mxHead">Matrices</h2><button type="button" class="text-btn" data-act="new-matrix">${icon('plus')}New</button></div>
          <div class="od-rail mx-rail" id="mxRail"></div>
        </section>
        <section class="ws-section" aria-labelledby="lnHead">
          <div class="section-head"><h2 id="lnHead">Expressions</h2><button type="button" class="text-btn" data-act="go" data-to="history">${icon('clock')}History</button></div>
          <ol class="lines" id="lines"></ol>
          <button type="button" class="add-line" data-act="add-line">${icon('plus')}Add expression</button>
        </section>
      </div>
      <footer class="keypad" id="keypad" aria-label="Math keypad">
        <div class="kp-bar">
          <div class="kp-tabs" role="tablist" aria-label="Keypad pages" id="kpTabs"></div>
          <span class="od-fill"></span>
          <button type="button" class="text-btn kp-show" data-act="kp-toggle">${icon('up')}Show keypad</button>
          <button type="button" class="icon-btn kp-hide" data-act="kp-toggle" aria-label="Hide keypad">${icon('down')}</button>
        </div>
        <div class="kp-names">
          <div class="od-rail names-rail" id="namesRail" aria-label="Insert a matrix name"></div>
          <button type="button" class="key key--util kp-arrow" data-act="key" data-op="left" aria-label="Move cursor left">${icon('left')}</button>
          <button type="button" class="key key--util kp-arrow" data-act="key" data-op="right" aria-label="Move cursor right">${icon('right')}</button>
        </div>
        <div class="kp-grid" id="kpGrid" role="tabpanel"></div>
      </footer>
    </section>
    <section class="screen od-screen" data-screen="sub" id="subScreen" hidden></section>
    <div class="hinge" aria-hidden="true"></div>
    <aside class="screen od-screen pane-detail" id="paneDetail" aria-label="Details"></aside>
    <section class="glance" id="glance" aria-label="Matscape at a glance"></section>
    <aside class="strip-rail" id="stripRail" aria-label="Matrices"></aside>`;
  const wsScreen = $('[data-screen="workspace"]', appEl), subScreen = $('#subScreen'), wsScroll = $('#wsScroll');
  const paneDetail = $('#paneDetail'), mxListEl = $('#mxList'), glanceEl = $('#glance'), stripEl = $('#stripRail');
  const linesEl = $('#lines'), railEl = $('#mxRail'), namesEl = $('#namesRail'), kpGrid = $('#kpGrid'), kpTabs = $('#kpTabs'), keypadEl = $('#keypad');

  function renderHeader() { $('#wsName').textContent = ws().name; $('#sideWsName').textContent = ws().name; }
  function renderRail() {
    const w = ws();
    const card = (m) => {
      const r = cache.mats.get(m.id), ok = r && r.ok;
      const body = ok ? `<span class="mx-card-prev">${previewHTML(r.value)}</span>` : `<span class="tag-bad">${icon('alert')}Fix entry</span>`;
      return `<div class="mx-item" data-id="${m.id}">
        <button type="button" class="mx-card${ok ? '' : ' is-invalid'}" data-act="edit-matrix" data-id="${m.id}" aria-label="Matrix ${m.name}, ${m.rows} by ${m.cols}${ok ? '' : ', has an entry to fix'}. Edit">
          <span class="mx-card-name">${esc(m.name)}</span><span class="mx-card-dims">${m.rows}×${m.cols}</span>${body}</button>
        <button type="button" class="grip grip--card" data-drag="matrix" data-id="${m.id}" aria-label="Move matrix ${esc(m.name)}. Drag, or use the arrow keys">${gripIcon()}</button>
      </div>`;
    };
    railEl.innerHTML = w.matrices.map(card).join('') + `<div class="mx-item mx-item--new"><button type="button" class="mx-card mx-card--new" data-act="new-matrix">${icon('plus')}<span>New matrix</span></button></div>`;
    mxListEl.innerHTML = railEl.innerHTML;
    stripEl.innerHTML = `<div class="strip-list">${w.matrices.map((m) => {
      const r = cache.mats.get(m.id), ok = r && r.ok;
      return `<div class="mx-item strip-item" data-id="${m.id}"><button type="button" class="strip-tile${ok ? '' : ' is-invalid'}" data-act="edit-matrix" data-id="${m.id}" aria-label="Matrix ${m.name}, ${m.rows} by ${m.cols}${ok ? '' : ', has an entry to fix'}. Edit"><span class="strip-name">${esc(m.name)}</span><span class="strip-dims">${m.rows}×${m.cols}</span></button></div>`;
    }).join('')}<button type="button" class="strip-tile strip-tile--new" data-act="new-matrix" aria-label="New matrix">${icon('plus')}</button></div>`;
    namesEl.innerHTML = w.matrices.map((m) => `<button type="button" class="name-key" data-act="key" data-ins="${esc(m.name)}" aria-label="Insert matrix ${esc(m.name)}">${esc(m.name)}</button>`).join('')
      + `<button type="button" class="name-key name-key--new" data-act="new-matrix" aria-label="New matrix">${icon('plus')}New</button>`;
  }
  function lineHTML(l, i) {
    return `<li class="line${l.id === ui.activeLineId ? ' is-active' : ''}" data-line="${l.id}">
      <div class="line-gutter"><span class="line-num" aria-hidden="true">${i + 1}</span><button type="button" class="grip grip--line" data-drag="line" data-id="${l.id}" aria-label="Move expression ${i + 1}. Drag, or use the arrow keys">${gripIcon()}</button></div>
      <div class="line-body">
        <input class="line-input" id="in-${l.id}" data-line="${l.id}" value="${esc(l.text)}" inputmode="none" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false" aria-label="Expression ${i + 1}" placeholder="Type or tap the keys below">
        <div class="line-out" id="out-${l.id}"></div>
      </div>
      <button type="button" class="icon-btn icon-btn--sm line-del" data-act="delete-line" data-line="${l.id}" aria-label="Delete expression ${i + 1}">${icon('close')}</button>
    </li>`;
  }
  function renderLines() { linesEl.innerHTML = ws().lines.map(lineHTML).join(''); updateResults(); }
  function updateResults() {
    ws().lines.forEach((l) => {
      const out = document.getElementById('out-' + l.id); if (!out) return;
      out.innerHTML = resultHTML(l);
      const res = cache.lines.get(l.id);
      out.closest('.line').classList.toggle('has-error', !!(l.text.trim() && res && !res.ok && !res.empty));
    });
    afterResults();
  }
  function afterResults() {
    if (hasDetail() && (!ui.screen || ui.screen === 'inspect' || ui.screen === 'steps')) renderDetail(true);
    else if (ui.screen === 'steps' && !hasDetail()) rerenderSteps();
    if (ui.layout === 'glance') renderGlance();
  }
  function renderKeypad() {
    const dual = !!ui.xl;
    if (dual && ui.kpTab === 'num') ui.kpTab = 'mat';
    const tabs = Object.entries(KEYPAD).filter(([k]) => !(dual && k === 'num'));
    kpTabs.innerHTML = tabs.map(([k, p]) => `<button type="button" role="tab" class="kp-tab" id="tab-${k}" aria-selected="${ui.kpTab === k}" aria-controls="kpGrid" tabindex="${ui.kpTab === k ? 0 : -1}" data-act="kp-tab" data-tab="${k}">${p.label}</button>`).join('');
    kpGrid.setAttribute('aria-labelledby', 'tab-' + ui.kpTab);
    const pageHTML = (rows, withUtil) => {
      const html = [];
      rows.forEach((row, r) => {
        row.forEach((k) => html.push(keyHTML(k)));
        if (withUtil && r === 0) html.push(`<button type="button" class="key key--util span-2r" data-act="key" data-op="back" aria-label="Delete">${icon('backspace')}</button>`);
        if (withUtil && r === 2) html.push(`<button type="button" class="key key--enter span-2r" data-act="key" data-op="enter" aria-label="Enter — next line">${icon('enter')}</button>`);
      });
      return html.join('');
    };
    if (dual) {
      kpGrid.className = 'kp-dual';
      kpGrid.innerHTML = `<div class="kp-grid kp-grid--6" role="group" aria-label="Numbers">${pageHTML(KEYPAD.num.rows, false)}</div><div class="kp-grid" role="group" aria-label="${esc(KEYPAD[ui.kpTab].label)} keys">${pageHTML(KEYPAD[ui.kpTab].rows, true)}</div>`;
    } else {
      kpGrid.className = 'kp-grid';
      kpGrid.innerHTML = pageHTML(KEYPAD[ui.kpTab].rows, true);
    }
    keypadEl.classList.toggle('is-collapsed', ui.kpCollapsed && ui.layout !== 'tabletop' && ui.layout !== 'landscape');
  }
  function refreshAll() { evaluateAll(); renderHeader(); renderRail(); renderLines(); renderKeypad(); if (ui.layout === 'glance') renderGlance(); }

  /* ---------- line editing ---------- */
  const lineById = (id) => ws().lines.find((l) => l.id === id);
  function setActive(id) {
    const changed = ui.activeLineId !== id;
    ui.activeLineId = id;
    $$('.line', linesEl).forEach((li) => li.classList.toggle('is-active', li.dataset.line === id));
    if (changed && hasDetail() && !ui.screen) renderDetail(true);
  }
  function focusLine(id, caret) {
    const inp = document.getElementById('in-' + id); if (!inp) return;
    inp.focus({ preventScroll: false });
    const p = caret == null ? inp.value.length : caret; inp.setSelectionRange(p, p);
    setActive(id);
    inp.closest('.line').scrollIntoView({ block: 'nearest' });
  }
  function onLineChanged(inp) {
    const l = lineById(inp.dataset.line); if (!l) return;
    l.text = inp.value; ws().updated = Date.now();
    evaluateAll(); updateResults(); persist();
  }
  function addLine(afterId, text = '') {
    const w = ws(), l = { id: uid(), text };
    const idx = afterId ? w.lines.findIndex((x) => x.id === afterId) : w.lines.length - 1;
    w.lines.splice(idx + 1, 0, l);
    evaluateAll(); renderLines(); persist();
    return l;
  }
  function targetInput() {
    let inp = ui.activeLineId && document.getElementById('in-' + ui.activeLineId);
    if (!inp) { const l = ws().lines[ws().lines.length - 1] || addLine(null); ui.activeLineId = l.id; inp = document.getElementById('in-' + l.id); setActive(l.id); }
    return inp;
  }
  function insertInto(inp, str, back = 0) {
    const v = inp.value, s = inp.selectionStart ?? v.length, e = inp.selectionEnd ?? s;
    inp.value = v.slice(0, s) + str + v.slice(e);
    const p = s + str.length - back; inp.setSelectionRange(p, p);
    inp.dispatchEvent(new Event('input', { bubbles: true }));
  }
  function backspaceIn(inp) {
    const v = inp.value; let s = inp.selectionStart ?? v.length, e = inp.selectionEnd ?? s;
    if (s !== e) { inp.value = v.slice(0, s) + v.slice(e); }
    else {
      if (s === 0) return;
      const before = v.slice(0, s), after = v.slice(s);
      const fnm = /[A-Za-z0-9]+\($/.exec(before);
      let cut = 1, extra = 0;
      if (fnm) { cut = fnm[0].length; if (after.startsWith(')')) extra = 1; }
      else if (before.endsWith('⁻¹')) cut = 2;
      else if (/[([|]$/.test(before) && ({ '(': ')', '[': ']', '|': '|' })[before.slice(-1)] === after[0]) extra = 1;
      inp.value = before.slice(0, -cut) + after.slice(extra); s -= cut;
    }
    inp.setSelectionRange(s, s);
    inp.dispatchEvent(new Event('input', { bubbles: true }));
  }
  function moveCaret(inp, d) { const p = Math.max(0, Math.min(inp.value.length, (inp.selectionStart ?? inp.value.length) + d)); inp.setSelectionRange(p, p); }
  function commitLine(id) {
    const w = ws(), l = lineById(id); if (!l) return;
    const res = cache.lines.get(id);
    if (l.text.trim() && res && res.ok) {
      const summary = resultSummary(res.value);
      if (!state.history[0] || state.history[0].text !== l.text) state.history.unshift({ text: l.text, summary, ts: Date.now() });
      state.history = state.history.slice(0, 60);
    }
    const idx = w.lines.indexOf(l), nextL = w.lines[idx + 1];
    if (nextL && !nextL.text.trim()) focusLine(nextL.id);
    else { const nl = addLine(id); focusLine(nl.id); }
    persist();
  }
  function deleteLine(id) {
    const w = ws(), idx = w.lines.findIndex((l) => l.id === id); if (idx < 0) return;
    if (w.lines.length === 1) { w.lines[0].text = ''; evaluateAll(); renderLines(); focusLine(w.lines[0].id); persist(); return; }
    w.lines.splice(idx, 1);
    const nextL = w.lines[Math.max(0, idx - 1)];
    ui.activeLineId = nextL.id;
    evaluateAll(); renderLines(); focusLine(nextL.id); persist();
  }
  function handleKey(btn) {
    const opk = btn.dataset.op;
    if (opk === 'angle') {
      state.settings.angle = state.settings.angle === 'rad' ? 'deg' : 'rad';
      evaluateAll(); renderRail(); updateResults(); renderKeypad(); persist();
      toast(`Angles in ${state.settings.angle === 'rad' ? 'radians' : 'degrees'}`);
      return;
    }
    const inp = targetInput();
    if (opk === 'back') backspaceIn(inp);
    else if (opk === 'left') moveCaret(inp, -1);
    else if (opk === 'right') moveCaret(inp, 1);
    else if (opk === 'enter') commitLine(inp.dataset.line);
    else insertInto(inp, btn.dataset.ins || '', +(btn.dataset.back || 0));
    if (ui.kpCollapsed) { ui.kpCollapsed = false; renderKeypad(); }
  }

  /* ---------- matrices ---------- */
  const LETTERS = 'ABCDEFGHJKLMNOPQRSTUVWXYZ'.split('');
  function freeName() {
    const used = new Set(ws().matrices.map((m) => m.name));
    ws().lines.forEach((l) => { const a = E.splitAssignment(l.text); if (a) used.add(a.name); });
    return LETTERS.find((c) => !used.has(c)) || null;
  }
  const fillCells = (r, c, fill) => Array.from({ length: r }, (_, i) => Array.from({ length: c }, (_, j) => (fill === 'identity' && i === j ? '1' : '0')));
  function createMatrix(cells, nameHint) {
    const name = nameHint || freeName();
    if (!name) { toast('All 25 matrix names are in use'); return null; }
    const m = { id: uid(), name, rows: cells.length, cols: cells[0].length, cells };
    ws().matrices.push(m); ws().updated = Date.now();
    evaluateAll(); renderRail(); updateResults(); persist();
    return m;
  }
  function newMatrix(trigger) {
    const s = state.settings, m = createMatrix(fillCells(s.defRows, s.defCols, s.defFill));
    if (m) openEditor(m.id, trigger, true);
  }
  function saveValueAsMatrix(M) {
    const m = createMatrix(M.data.map((r) => r.map(cellText)));
    if (m) { toast(`Saved as matrix ${m.name}`); railEl.scrollTo({ left: railEl.scrollWidth, behavior: 'smooth' }); }
  }
  function copyText(text) {
    const done = () => toast('Copied');
    if (navigator.clipboard && navigator.clipboard.writeText) navigator.clipboard.writeText(text).then(done, () => toast('Copying isn’t available in this preview'));
    else toast('Copying isn’t available in this preview');
  }
  const latex = () => state.settings.copyAs === 'latex';
  function lineValueText(res) {
    const v = res.value;
    if (latex()) return E.texValue(v, state.settings.display, state.settings.precision);
    if (E.isNum(v)) return numText(v);
    if (E.isMat(v)) return matText(v);
    return resultSummary(v);
  }

  /* ---------- overlays ---------- */
  function openLayer(html, opts = {}) {
    const layer = document.createElement('div');
    layer.className = 'layer';
    layer.innerHTML = html;
    overlayRoot.appendChild(layer);
    ui.layers.push({ el: layer, onClose: opts.onClose, returnFocus: opts.returnFocus || document.activeElement });
    appEl.inert = true;
    ui.layers.slice(0, -1).forEach((l) => { l.el.inert = true; });
    requestAnimationFrame(() => { const f = opts.focus ? $(opts.focus, layer) : $('button, input, select', layer); if (f) f.focus(); });
    return layer;
  }
  function closeLayer(layer) {
    const idx = ui.layers.findIndex((l) => l.el === (layer || (ui.layers[ui.layers.length - 1] || {}).el));
    if (idx < 0) return;
    const entry = ui.layers.splice(idx, 1)[0];
    entry.el.classList.add('is-leaving');
    entry.el.inert = true;
    const reduce = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    setTimeout(() => entry.el.remove(), reduce ? 0 : 230);
    const top = ui.layers[ui.layers.length - 1];
    if (top) top.el.inert = false; else appEl.inert = false;
    if (entry.onClose) entry.onClose();
    const rf = typeof entry.returnFocus === 'function' ? entry.returnFocus() : entry.returnFocus;
    if (rf && rf.isConnected && !rf.closest('[inert]')) rf.focus(); else if (!ui.screen && ui.activeLineId) focusLine(ui.activeLineId);
  }
  function confirmDialog({ title, body, ok, danger = true }, onOk) {
    const layer = openLayer(`<div class="scrim" data-act="alert-cancel"></div>
      <div class="alert" role="alertdialog" aria-modal="true" aria-labelledby="alT" aria-describedby="alB">
        <h2 id="alT">${esc(title)}</h2><p id="alB">${esc(body)}</p>
        <div class="btn-row"><button type="button" class="btn" data-act="alert-cancel">Cancel</button><button type="button" class="btn ${danger ? 'btn--danger' : 'btn--primary'}" data-act="alert-ok">${esc(ok)}</button></div>
      </div>`, { focus: '[data-act="alert-cancel"].btn' });
    layer._onOk = onOk;
  }
  let toastTimer = 0;
  function toast(msg) {
    const old = $('.toast', overlayRoot); if (old) old.remove();
    const t = document.createElement('div'); t.className = 'toast'; t.setAttribute('role', 'status'); t.textContent = msg;
    overlayRoot.appendChild(t); clearTimeout(toastTimer); toastTimer = setTimeout(() => t.remove(), 2200);
  }

  /* drawer */
  function openDrawer() {
    openLayer(`<div class="scrim" data-act="close-layer"></div>
      <div class="drawer" role="dialog" aria-modal="true" aria-label="Menu">
        <div class="drawer-head"><span class="wordmark">Mat<i>scape</i></span><span class="ws-name od-truncate">${esc(ws().name)}</span></div>
        <nav aria-label="Main">
          <button type="button" class="nav-item" data-act="nav" data-to="workspaces">${icon('folder')}Workspaces</button>
          <button type="button" class="nav-item" data-act="nav" data-to="history">${icon('clock')}History</button>
          <button type="button" class="nav-item" data-act="nav" data-to="library">${icon('book')}Operations library</button>
          <button type="button" class="nav-item" data-act="nav" data-to="settings">${icon('sliders')}Settings</button>
          <button type="button" class="nav-item" data-act="nav" data-to="help">${icon('help')}Help & tips</button>
        </nav>
        <p class="drawer-foot">Matscape 2.0 · ByteMechanics</p>
      </div>`);
  }

  /* ---------- matrix editor sheet ----------
     Entries are typed with the editor's own keypad, so the phone's system
     keyboard never opens and the matrix stays visible while you type. */
  const ED_FN = [['π', 'π', 0, 'Pi'], ['√', '√', 0, 'Square root'], ['(', '(', 0, 'Open bracket'], [')', ')', 0, 'Close bracket'], ['x<sup>□</sup>', '^', 0, 'Power'], ['°', '°', 0, 'Degrees'], ['sin', 'sin()', 1], ['cos', 'cos()', 1], ['tan', 'tan()', 1], ['<i>e</i>', 'e', 0, 'Euler’s number'], ['ln', 'ln()', 1]];
  const ED_PRESETS = [['zero', 'Zeros'], ['identity', 'Identity'], ['random', 'Random'], ['symmetric', 'Symmetric'], ['diagonal', 'Diagonal'], ['rotation', 'Rotation 30°']];
  function edPadHTML() {
    const d = (n) => `<button type="button" class="key" data-act="ed-key" data-ins="${n}">${n}</button>`;
    const o = (l, ins, aria) => `<button type="button" class="key key--op" data-act="ed-key" data-ins="${esc(ins)}" aria-label="${aria}">${l}</button>`;
    const u = (op, inner, aria, cls) => `<button type="button" class="key ${cls || 'key--util'}" data-act="ed-key" data-op="${op}" aria-label="${aria}">${inner}</button>`;
    return [
      d(7), d(8), d(9), o('÷', '/', 'Divide'), u('back', icon('backspace'), 'Delete'),
      d(4), d(5), d(6), o('×', '·', 'Multiply'), u('left', icon('left'), 'Move cursor left'),
      d(1), d(2), d(3), o('−', '−', 'Minus'), u('right', icon('right'), 'Move cursor right'),
      u('sign', '±', 'Change sign', 'key--op'), d(0), o('.', '.', 'Decimal point').replace('key--op', ''), o('+', '+', 'Plus'),
      '<button type="button" class="key key--enter ed-next" data-act="ed-key" data-op="next" id="edNext"></button>',
    ].join('');
  }
  function openEditor(id, trigger, isNew) {
    const m = ws().matrices.find((x) => x.id === id); if (!m) return;
    ui.editor = { id, cell: [0, 0], isNew, strip: 'fn' };
    const layer = openLayer(`<div class="scrim" data-act="ed-close"></div>
      <div class="sheet sheet--editor" role="dialog" aria-modal="true" aria-labelledby="edTitle">
        <div class="grabber" aria-hidden="true"></div>
        <div class="ed-head">
          <h2 id="edTitle" class="ed-title">Matrix</h2>
          <select id="edName" class="ed-name" data-act="ed-name" aria-label="Matrix name"></select>
          <span class="od-fill"></span>
          <button type="button" class="icon-btn icon-btn--danger" data-act="ed-delete" aria-label="Delete matrix">${icon('trash')}</button>
          <button type="button" class="icon-btn" data-act="ed-dup" aria-label="Duplicate matrix">${icon('copy')}</button>
          <button type="button" class="icon-btn" data-act="ed-inspect" aria-label="Inspect matrix">${icon('eye')}</button>
          <button type="button" class="ed-done" data-act="ed-close">Done</button>
        </div>
        <div class="ed-dims" id="edDims"></div>
        <div class="ed-grid-wrap" id="edGridWrap"></div>
        <div class="ed-entry">
          <label class="ed-entry-label" for="edEntry" id="edEntryLabel"></label>
          <input id="edEntry" class="ed-entry-input" inputmode="none" autocomplete="off" autocorrect="off" autocapitalize="off" spellcheck="false">
          <output class="ed-entry-val" id="edVal" for="edEntry"></output>
        </div>
        <p class="ed-msg" id="edMsg" aria-live="polite"></p>
        <div class="ed-input">
          <div class="ed-strip" id="edStrip"></div>
          <div class="ed-pad" role="group" aria-label="Number keypad">${edPadHTML()}</div>
        </div>
      </div>`, { focus: '#edEntry', returnFocus: () => visibleEl(`.mx-card[data-id="${id}"]`) || (trigger && trigger.isConnected && trigger.offsetParent !== null ? trigger : visibleEl('.mx-card--new')), onClose: () => { ui.editor = null; } });
    ui.editor.layer = layer;
    renderEditor();
    requestAnimationFrame(() => requestAnimationFrame(selectEntryAll));
  }
  function edMatrix() { return ui.editor && ws().matrices.find((m) => m.id === ui.editor.id); }
  function edCommit() { ws().updated = Date.now(); evaluateAll(); renderRail(); updateResults(); persist(); }
  function renderEditor() {
    const m = edMatrix(); if (!m) return;
    const L = ui.editor.layer, used = new Set(ws().matrices.map((x) => x.name));
    ui.editor.cell = [Math.min(ui.editor.cell[0], m.rows - 1), Math.min(ui.editor.cell[1], m.cols - 1)];
    $('#edName', L).innerHTML = LETTERS.filter((c) => c === m.name || !used.has(c)).map((c) => `<option value="${c}"${c === m.name ? ' selected' : ''}>${c}</option>`).join('');
    renderEdDims(); renderEdGrid(); renderEdEntry(); renderEdStrip();
  }
  function renderEdDims() {
    const m = edMatrix(), L = ui.editor.layer, res = cache.mats.get(m.id);
    let det = '';
    if (res && res.ok && m.rows === m.cols) { try { det = `det ${numText(E.det(res.value))}`; } catch (e) { det = ''; } }
    const st = (k, label, noun, v) => `<div class="ed-dim"><span id="edL-${k}">${label}</span><div class="stepper" role="group" aria-labelledby="edL-${k}"><button type="button" data-act="ed-dim" data-k="${k}" data-d="-1" aria-label="Fewer ${noun}" ${v <= 1 ? 'disabled' : ''}>−</button><output>${v}</output><button type="button" data-act="ed-dim" data-k="${k}" data-d="1" aria-label="More ${noun}" ${v >= 8 ? 'disabled' : ''}>+</button></div></div>`;
    $('#edDims', L).innerHTML = st('rows', 'Rows', 'rows', m.rows) + st('cols', 'Cols', 'columns', m.cols) + `<span class="ed-det od-truncate" title="${esc(det)}">${esc(det)}</span>`;
  }
  function renderEdGrid() {
    const m = edMatrix(), L = ui.editor.layer, [si, sj] = ui.editor.cell, angle = state.settings.angle;
    const rows = m.cells.map((row, i) => `<div role="row" style="display:contents">${row.map((txt, j) => {
      const r = E.evalScalar(txt, angle), sel = i === si && j === sj;
      const disp = r.ok ? numHTML(r.value) : esc(txt.trim() ? txt : '?');
      return `<button type="button" class="cell${sel ? ' is-sel' : ''}${r.ok ? '' : ' is-bad'}" role="gridcell" aria-selected="${sel}" data-act="ed-cell" data-i="${i}" data-j="${j}" aria-label="Row ${i + 1}, column ${j + 1}: ${esc(txt.trim() || 'empty')}${r.ok ? '' : ', needs fixing'}">${disp}</button>`;
    }).join('')}</div>`).join('');
    const wrap = $('#edGridWrap', L);
    wrap.innerHTML = `<div class="ed-grid" role="grid" aria-label="Entries of ${esc(m.name)}" style="--cols:${m.cols}">${rows}</div>`;
    const selEl = $('.cell.is-sel', wrap);
    if (selEl) {
      const top = selEl.offsetTop - wrap.offsetTop, left = selEl.offsetLeft - wrap.offsetLeft;
      if (top < wrap.scrollTop || top + selEl.offsetHeight > wrap.scrollTop + wrap.clientHeight) wrap.scrollTop = top - 8;
      if (left < wrap.scrollLeft || left + selEl.offsetWidth > wrap.scrollLeft + wrap.clientWidth) wrap.scrollLeft = left - 8;
    }
  }
  function renderEdEntry() {
    const m = edMatrix(), L = ui.editor.layer, [i, j] = ui.editor.cell;
    $('#edEntryLabel', L).innerHTML = `<i>${esc(m.name)}</i><sub>${i + 1},${j + 1}</sub><span class="sr-only">, row ${i + 1}, column ${j + 1}</span>`;
    $('#edEntry', L).value = m.cells[i][j];
    updateEdPreview();
    const last = i === m.rows - 1 && j === m.cols - 1, nb = $('#edNext', L);
    nb.textContent = last ? 'Done' : 'Next';
    nb.setAttribute('aria-label', last ? 'Done editing' : 'Next entry');
  }
  function updateEdPreview() {
    const m = edMatrix(), L = ui.editor.layer, [i, j] = ui.editor.cell, txt = m.cells[i][j];
    const r = E.evalScalar(txt, state.settings.angle), val = $('#edVal', L), msg = $('#edMsg', L);
    if (r.ok) {
      val.innerHTML = /^\s*[−-]?\d*\.?\d+\s*$/.test(txt) ? '' : `= ${numHTML(r.value)}`;
      msg.className = 'ed-msg';
      msg.textContent = 'Tap any entry to edit it · sin(30°), 2√3, 1/3 all work';
    } else if (!txt.trim()) {
      val.innerHTML = '';
      msg.className = 'ed-msg';
      msg.textContent = 'Type a value for this entry';
    } else {
      val.innerHTML = '';
      msg.className = 'ed-msg is-error';
      msg.innerHTML = `${icon('alert')}<span class="od-truncate">${esc(r.error)}</span>`;
    }
  }
  function renderEdStrip() {
    const L = ui.editor.layer, s = ui.editor.strip;
    const chips = s === 'fn'
      ? ED_FN.map(([l, ins, back, aria]) => `<button type="button" class="key ${/^[a-z]{2}/.test(l) ? 'key--fn' : 'key--op'}" data-act="ed-key" data-ins="${esc(ins)}" data-back="${back}"${aria ? ` aria-label="${aria}"` : ''}>${l}</button>`).join('')
      : ED_PRESETS.map(([k, l]) => `<button type="button" class="chip" data-act="ed-preset" data-p="${k}">${l}</button>`).join('');
    $('#edStrip', L).innerHTML = `<div class="seg seg--sm" role="group" aria-label="Extra keys"><button type="button" data-act="ed-strip" data-k="fn" aria-pressed="${s === 'fn'}">f(x)</button><button type="button" data-act="ed-strip" data-k="fill" aria-pressed="${s === 'fill'}">Fill</button></div><div class="od-rail ed-rail">${chips}</div>`;
  }
  function selectEntryAll() {
    if (!ui.editor) return;
    const inp = $('#edEntry', ui.editor.layer); if (!inp) return;
    inp.focus(); inp.setSelectionRange(0, inp.value.length);
  }
  function selectCell(i, j) {
    ui.editor.cell = [i, j];
    renderEdGrid(); renderEdEntry(); selectEntryAll();
  }
  function edNext() {
    const m = edMatrix(); let [i, j] = ui.editor.cell;
    j++; if (j >= m.cols) { j = 0; i++; }
    if (i >= m.rows) { closeLayer(ui.editor.layer); return; }
    selectCell(i, j);
  }
  function edKey(btn) {
    const inp = $('#edEntry', ui.editor.layer), opk = btn.dataset.op;
    if (opk === 'next') { edNext(); return; }
    if (opk === 'back') backspaceIn(inp);
    else if (opk === 'left') moveCaret(inp, -1);
    else if (opk === 'right') moveCaret(inp, 1);
    else if (opk === 'sign') {
      const v = inp.value.trim();
      const nv = /^[−-]/.test(v) ? v.slice(1) : (/[+−-]/.test(v) ? `−(${v})` : '−' + v);
      inp.value = nv; inp.setSelectionRange(nv.length, nv.length);
      inp.dispatchEvent(new Event('input', { bubbles: true }));
    } else insertInto(inp, btn.dataset.ins || '', +(btn.dataset.back || 0));
  }
  function edAfterChange(focusSel) {
    edCommit(); renderEditor();
    const f = focusSel && $(focusSel, ui.editor.layer);
    if (f && !f.disabled) f.focus(); else selectEntryAll();
  }
  function resizeEditor(k, d) {
    const m = edMatrix(); if (!m) return;
    const fill = state.settings.defFill;
    if (k === 'rows') {
      const n = Math.max(1, Math.min(8, m.rows + d));
      while (m.cells.length < n) { const i = m.cells.length; m.cells.push(Array.from({ length: m.cols }, (_, j) => (fill === 'identity' && i === j ? '1' : '0'))); }
      m.cells.length = n; m.rows = n;
    } else {
      const n = Math.max(1, Math.min(8, m.cols + d));
      m.cells.forEach((row, i) => { while (row.length < n) { const j = row.length; row.push(fill === 'identity' && i === j ? '1' : '0'); } row.length = n; });
      m.cols = n;
    }
    edAfterChange(`[data-act="ed-dim"][data-k="${k}"][data-d="${d}"]`);
    const b = $(`[data-act="ed-dim"][data-k="${k}"][data-d="${d}"]`, ui.editor.layer);
    if (b && b.disabled) { const alt = $(`[data-act="ed-dim"][data-k="${k}"]:not([disabled])`, ui.editor.layer); if (alt) alt.focus(); }
  }
  function presetEditor(p) {
    const m = edMatrix(); if (!m) return;
    const rnd = () => String(Math.floor(Math.random() * 19) - 9).replace('-', '−');
    let r = m.rows, c = m.cols;
    if (p === 'rotation') {
      if (!(r === c && (r === 2 || r === 3))) { r = c = 2; toast('Set to a 2×2 rotation'); }
      m.cells = r === 2 ? [['cos(30°)', '−sin(30°)'], ['sin(30°)', 'cos(30°)']] : [['cos(30°)', '−sin(30°)', '0'], ['sin(30°)', 'cos(30°)', '0'], ['0', '0', '1']];
    } else if (p === 'symmetric') {
      const g = fillCells(r, c, 'zero');
      for (let i = 0; i < r; i++) for (let j = 0; j < c; j++) { if (j < i && i < c) g[i][j] = g[j][i]; else g[i][j] = rnd(); }
      m.cells = g;
    } else {
      m.cells = Array.from({ length: r }, (_, i) => Array.from({ length: c }, (_, j) => {
        if (p === 'identity') return i === j ? '1' : '0';
        if (p === 'random') return rnd();
        if (p === 'diagonal') return i === j ? String(1 + Math.floor(Math.random() * 9)) : '0';
        return '0';
      }));
    }
    m.rows = r; m.cols = c;
    edAfterChange(`[data-act="ed-preset"][data-p="${p}"]`);
  }

  /* ---------- sub screens & detail pane ----------
     compact / medium: a sub screen replaces the workspace column.
     expanded / book: it opens in the detail pane beside the workspace.
     tabletop: it takes the upper half; the keypad stays on the lower half. */
  const hasDetail = (l = ui.layout) => l === 'expanded' || l === 'book';
  const host = () => (hasDetail() ? paneDetail : subScreen);
  function markNav() { $$('.side-nav .nav-item', appEl).forEach((b) => { if (b.dataset.to === ui.screen) b.setAttribute('aria-current', 'page'); else b.removeAttribute('aria-current'); }); }
  function openScreen(name, params, opener) {
    if (!ui.screen) { ui.wsScroll = wsScroll.scrollTop; ui.returnFocus = opener || document.activeElement; }
    ui.screen = name; ui.params = params || {};
    if (hasDetail()) {
      renderSub(); markNav();
      paneDetail.classList.remove('is-entering'); void paneDetail.offsetWidth; paneDetail.classList.add('is-entering');
      const hd = $('h1', paneDetail); if (hd) hd.focus();
      return;
    }
    renderSub(); markNav();
    subScreen.hidden = false;
    if (ui.layout === 'tabletop') appEl.classList.add('has-sub'); else wsScreen.hidden = true;
    subScreen.classList.remove('is-entering'); void subScreen.offsetWidth; subScreen.classList.add('is-entering');
    const h = $('h1', subScreen); if (h) h.focus();
  }
  function closeScreen() {
    if (!ui.screen) return;
    ui.screen = null; markNav();
    const rf = ui.returnFocus;
    if (hasDetail()) {
      renderDetail(false);
    } else {
      subScreen.hidden = true; subScreen.innerHTML = ''; wsScreen.hidden = false; appEl.classList.remove('has-sub');
      wsScroll.scrollTop = ui.wsScroll;
      wsScreen.classList.remove('is-entering'); void wsScreen.offsetWidth; wsScreen.classList.add('is-entering');
    }
    if (rf && rf.isConnected && rf.offsetParent !== null) rf.focus(); else if (ui.activeLineId) focusLine(ui.activeLineId);
  }
  const SPACER = '<span class="od-spacer" style="width:44px;height:44px"></span>';
  function subHead(title, right = SPACER) {
    if (hasDetail()) {
      const left = ui.screen ? `<button type="button" class="icon-btn" data-act="back" aria-label="Close panel">${icon('close')}</button>` : '';
      return `<header class="topbar is-raised topbar--pane">${left}<h1 tabindex="-1">${esc(title)}</h1>${right}</header>`;
    }
    return `<header class="topbar is-raised"><button type="button" class="icon-btn" data-act="back" aria-label="Back to workspace">${icon('back')}</button><h1 tabindex="-1">${esc(title)}</h1>${right}</header>`;
  }
  function autoInspectParams() {
    const w = ws(), isMatLike = (r) => r && r.ok && (E.isMat(r.value) || (r.value && r.value.type === 'multi'));
    if (lineById(ui.activeLineId)) return { kind: 'line', id: ui.activeLineId, part: ui.autoPart[ui.activeLineId] || 0, auto: true };
    // Fall back to the first plain matrix result from the top (never a by-product such as P from lu()).
    for (let i = 0; i < w.lines.length; i++) { const r = cache.lines.get(w.lines[i].id); if (r && r.ok && E.isMat(r.value)) return { kind: 'line', id: w.lines[i].id, part: 0, auto: true }; }
    const m = w.matrices.find((x) => { const r = cache.mats.get(x.id); return r && r.ok; });
    return m ? { kind: 'matrix', id: m.id, auto: true } : null;
  }
  function renderSub() {
    const el = host();
    let name = ui.screen;
    if (!name && hasDetail()) { name = 'inspect'; ui.params = autoInspectParams(); }
    if (!name) { el.innerHTML = ''; return; }
    const r = { library: renderLibrary, op: renderOp, inspect: renderInspector, steps: renderSteps, workspaces: renderWorkspaces, history: renderHistory, settings: renderSettings, help: renderHelp }[name];
    el.innerHTML = r ? r() : '';
    if (name === 'library') renderLibList();
  }
  function renderDetail(keepScroll) {
    if (!hasDetail()) return;
    const before = $('.od-scroll', paneDetail), top = before ? before.scrollTop : 0;
    const prevKey = ui.detailKey;
    renderSub();
    ui.detailKey = (ui.screen || 'auto') + JSON.stringify(ui.params || null);
    const after = $('.od-scroll', paneDetail);
    if (after && keepScroll && prevKey === ui.detailKey) after.scrollTop = top;
  }

  /* glance view (small cover screens): read-only latest results */
  function renderGlance() {
    const w = ws(), items = [];
    for (let i = w.lines.length - 1; i >= 0 && items.length < 2; i--) {
      const l = w.lines[i], r = cache.lines.get(l.id);
      if (!l.text.trim() || !r || !r.ok) continue;
      const v = r.value;
      const val = E.isNum(v) ? `= ${numHTML(v)}` : E.isMat(v) ? previewHTML(v) : esc(resultSummary(v));
      items.unshift(`<li class="glance-item"><span class="g-expr od-truncate">${esc(l.text)}</span><span class="g-val">${val}</span></li>`);
    }
    glanceEl.innerHTML = `
      <div class="glance-head"><span class="wordmark">Mat<i>scape</i></span><span class="ws-name od-truncate">${esc(w.name)}</span></div>
      ${items.length ? `<ul class="glance-list">${items.join('')}</ul>` : '<p class="glance-empty">No results yet</p>'}
      <p class="glance-hint">${icon('up')}<span>Open the phone to edit</span></p>`;
  }

  /* library */
  /* Operations library — the same 51 operations, wording and examples as the shipped app (lib/ui/library_data.dart). */
  const LIBDATA = {"ops":[{"group":"Basics","title":"Add and subtract","syntax":"A + B,  A − B","ins":"+","back":0,"desc":"Add or subtract matrices of the same size","about":"Adding two matrices adds the entries that sit in the same place, and subtracting works the same way. The result has the same size as the two matrices you started with.","examples":["[1, 2; 3, 4] + [5, 6; 7, 8]","[1, 2; 3, 4] − 2I"],"more":[],"notes":["Both matrices must have the same number of rows and columns.","A number can’t be added to a matrix. To shift the diagonal, use the identity matrix, as in A − 2I."],"keywords":"sum difference plus minus"},{"group":"Basics","title":"Multiply by a number","syntax":"3A  or  k·A","ins":"·","back":0,"desc":"Scale every entry by a number","about":"Multiplying a matrix by a number multiplies every entry by it. Write the number in front of the matrix. Dividing a matrix by a number divides every entry.","examples":["3[1, 2; 3, 4]","[2, 4; 6, 8] / 2"],"more":[],"notes":["A number can sit right against a matrix: 3A.","A named value needs the dot: k·A. Written together, kA is read as one name."],"keywords":"scalar multiply scale"},{"group":"Basics","title":"Matrix product","syntax":"AB  or  A·B","ins":"·","back":0,"desc":"Matrix product — columns of A must match rows of B","about":"The product AB combines each row of A with each column of B: the entry in row i, column j is the dot product of row i of A and column j of B. An m×n matrix times an n×p matrix gives an m×p matrix.","examples":["[1, 2; 3, 4]·[0, 1; 1, 0]","[1, 2, 3]·[4; 5; 6]"],"more":[],"notes":["The number of columns of A must equal the number of rows of B.","Order matters: AB and BA are usually different, and one can exist when the other doesn’t.","Capital letters written together are multiplied, so BA means B·A."],"keywords":"multiply product times"},{"group":"Basics","title":"Division","syntax":"A / B","ins":"/","back":0,"desc":"Right division, worked out as A·B⁻¹","about":"Matrices can’t be divided the way numbers can. Matscape reads A / B as A multiplied by the inverse of B, that is A·B⁻¹.","examples":["[2, 4; 6, 8] / [1, 0; 0, 2]"],"more":[],"notes":["B must be square and invertible.","To solve A·x = b, solve(A, b) is more direct than dividing."],"keywords":"divide division quotient"},{"group":"Basics","title":"Transpose","syntax":"Aᵀ","ins":"ᵀ","back":0,"desc":"Transpose — rows become columns","about":"The transpose flips a matrix over its main diagonal: row 1 becomes column 1, row 2 becomes column 2, and so on. An m×n matrix becomes n×m.","examples":["[1, 2, 3; 4, 5, 6]ᵀ"],"more":[],"notes":["A matrix that equals its own transpose is called symmetric.","On a hardware keyboard, an apostrophe types the transpose."],"keywords":"transpose flip"},{"group":"Basics","title":"Inverse","syntax":"A⁻¹","ins":"⁻¹","back":0,"desc":"Inverse of a square, non-singular matrix","about":"The inverse A⁻¹ undoes A: multiplying A by A⁻¹, in either order, gives the identity matrix. It plays the part that 1/a plays for numbers.","examples":["[4, 7; 2, 6]⁻¹","[4, 7; 2, 6]·[4, 7; 2, 6]⁻¹"],"more":[["For a 2×2 matrix","Take a matrix with rows (a, b) and (c, d). Swap a and d, change the signs of b and c, and divide every entry by the determinant, which is a times d minus b times c.\n\nIn the first example the determinant is 4 × 6 − 7 × 2 = 10."]],"notes":["Only square matrices with a non-zero determinant have an inverse.","For a singular or non-square matrix, pinv(A) is the closest substitute.","Inspect shows the inverse worked out step by step."],"keywords":"inverse invert reciprocal"},{"group":"Basics","title":"Powers","syntax":"A²,  A^n","ins":"^","back":0,"desc":"Whole-number powers; negative powers use the inverse","about":"A² means A·A, A³ means A·A·A, and so on. A negative power uses the inverse, so A⁻² is the inverse multiplied by itself, and A to the power 0 is the identity.","examples":["[1, 1; 0, 1]^5","[2, 0; 0, 4]^−1"],"more":[],"notes":["The matrix must be square.","Type ^ followed by the power.","Powers are whole numbers, with one exception: A^0.5 is the matrix square root."],"keywords":"power exponent square cube"},{"group":"Basics","title":"Entrywise product","syntax":"A ∘ B","ins":"∘","back":0,"desc":"Entrywise (Hadamard) product","about":"The entrywise product multiplies each entry of A by the entry of B in the same place. It is not the matrix product, which combines rows with columns. It is also called the Hadamard product.","examples":["[1, 2; 3, 4] ∘ [5, 6; 7, 8]"],"more":[],"notes":["Both matrices must be the same size."],"keywords":"hadamard elementwise schur"},{"group":"Basics","title":"Inline matrix","syntax":"[1, 2; 3, 4]","ins":"[]","back":1,"desc":"Write a matrix inline — “,” between entries, “;” between rows","about":"You can write a matrix straight into an expression without saving it first. Put the entries in square brackets, with a comma between entries and a semicolon between rows.\n\nSo [1, 2; 3, 4] has the rows 1 2 and 3 4. The examples on the other pages are shown both ways: with named matrices, and typed in one line like this.","examples":["[1, 2; 3, 4]","[1, 2, 3]","[1; 2; 3]","[cos(60°), √4; 1/2, 2²]"],"more":[],"notes":["Entries can be expressions: fractions, roots, trig.","One row makes a row vector, [1, 2, 3]. One column is [1; 2; 3].","Tap “Save” under a matrix result to keep it as a named matrix."],"keywords":"literal inline vector brackets","inlineOnly":true},{"group":"Basics","title":"Named values","syntax":"k = 3","ins":"k = ","back":0,"desc":"Name a value and reuse it in other lines","about":"Give any result a name by writing the name, an equals sign and the expression. You can then use that name in the other lines of the workspace, and they update whenever it changes.","examples":["k = 3","k·[1, 2; 3, 4]"],"more":[],"notes":["A name starts with a letter and can be a whole word, such as total.","It can’t be the name of one of your matrices, or a built-in name such as I, e or sin.","Order doesn’t matter: a name can be used above the line that sets it."],"keywords":"variable assign name store equals"},{"group":"Measures","title":"Determinant","syntax":"det(A)  or  |A|","ins":"det()","back":1,"desc":"Determinant of a square matrix","about":"The determinant is a single number that says how a square matrix scales area or volume. If it is zero, the matrix squashes space flat: it is singular and has no inverse.\n\nFor a 2×2 matrix with rows (a, b) and (c, d), it is a times d minus b times c. In the first example that is 2 × 3 − 1 × 1 = 5.","examples":["det([2, 1; 1, 3])","|[1, 2; 2, 4]|"],"more":[],"notes":["Only square matrices have a determinant.","It can also be written with bars: |A|.","A negative determinant means the matrix also flips orientation, as a mirror does.","Inspect shows the determinant worked out step by step."],"keywords":"determinant singular"},{"group":"Measures","title":"Trace","syntax":"tr(A)","ins":"tr()","back":1,"desc":"Trace — sum of the diagonal","about":"The trace is the sum of the entries on the main diagonal. It also equals the sum of the eigenvalues.","examples":["tr([1, 2; 3, 4])"],"more":[],"notes":["The matrix must be square."],"keywords":"trace diagonal sum"},{"group":"Measures","title":"Rank","syntax":"rank(A)","ins":"rank()","back":1,"desc":"Number of independent rows or columns","about":"The rank is the number of rows that are truly independent — the ones that can’t be built from the others. Counting independent columns gives the same number.\n\nIn the first example the second row is twice the first, so only one row counts and the rank is 1.","examples":["rank([1, 2; 2, 4])","rank([1, 2; 3, 4])"],"more":[],"notes":["A square matrix is invertible exactly when its rank equals its size.","It is the number of non-zero rows left after row reduction, rref(A).","The rank plus the number of vectors in null(A) equals the number of columns."],"keywords":"rank independent"},{"group":"Measures","title":"Frobenius norm","syntax":"norm(A)","ins":"norm()","back":1,"desc":"Frobenius norm","about":"A norm measures the size of a matrix as one number. The Frobenius norm squares every entry, adds them up and takes the square root. For a vector that is its ordinary length.","examples":["norm([3, 4])","norm([1, 2; 3, 4])"],"more":[],"notes":[],"keywords":"magnitude length size euclidean"},{"group":"Measures","title":"Column and row norms","syntax":"norm1(A),  norminf(A)","ins":"norm1()","back":1,"desc":"Largest column sum, largest row sum","about":"norm1 adds up the absolute values in each column and returns the largest total. norminf does the same with the rows.","examples":["norm1([1, −2; 3, 4])","norminf([1, −2; 3, 4])"],"more":[],"notes":[],"keywords":"one infinity norm column row sum"},{"group":"Measures","title":"Spectral norm","syntax":"norm2(A)","ins":"norm2()","back":1,"desc":"Spectral norm — the largest singular value","about":"The spectral norm is the most a matrix can stretch a vector. It equals the largest singular value.","examples":["norm2([3, 0; 0, 4])"],"more":[],"notes":["svd(A) gives all the singular values."],"keywords":"two norm singular stretch"},{"group":"Measures","title":"Condition number","syntax":"cond(A)","ins":"cond()","back":1,"desc":"Condition number — how sensitive A is to rounding","about":"The condition number says how much a small change in the input, such as a rounding error, can grow when you solve with this matrix. 1 is ideal; a large value means the answer should be read with care.","examples":["cond([1, 2; 3, 4])","cond([1, 2; 2, 4])"],"more":[["How to read it","Think of it as an error multiplier. With a condition number of 1000, an error in the fourth decimal place of the input can show up in the first decimal place of the answer.\n\nIt is the largest singular value divided by the smallest, so it measures how unevenly the matrix stretches different directions. A singular matrix flattens some direction completely, and its condition number is infinite."]],"notes":[],"keywords":"condition sensitivity stability"},{"group":"Build","title":"Identity matrix","syntax":"I(n)","ins":"I()","back":1,"desc":"n×n identity. Bare I adapts to its neighbour: A − 2I","about":"The identity matrix has ones on the diagonal and zeros everywhere else. Multiplying by it changes nothing, like multiplying a number by 1.","examples":["I(3)","[2, 1; 1, 3] − 2I"],"more":[],"notes":["I(n) gives the n×n identity.","A bare I takes whatever size its neighbour needs, so A − 2I works for any square A."],"keywords":"identity unit eye"},{"group":"Build","title":"Zeros and ones","syntax":"zeros(m, n),  ones(m, n)","ins":"zeros()","back":1,"desc":"Matrix of zeros or ones","about":"zeros(m, n) builds a matrix with m rows and n columns filled with zeros, and ones(m, n) one filled with ones. With a single number you get a square matrix.","examples":["zeros(2, 3)","ones(2)"],"more":[],"notes":["Sizes up to 64 are supported."],"keywords":"zero one fill empty"},{"group":"Build","title":"Diagonal","syntax":"diag(v)","ins":"diag()","back":1,"desc":"Diagonal matrix from a vector, or the diagonal of a matrix","about":"Given a vector, diag builds a square matrix with those values on the diagonal and zeros elsewhere. Given a matrix, it does the opposite and returns the diagonal as a column.","examples":["diag([1, 2, 3])","diag([1, 2; 3, 4])"],"more":[],"notes":[],"keywords":"diagonal"},{"group":"Build","title":"Augment","syntax":"aug(A, B)","ins":"aug()","back":1,"desc":"Place B to the right of A","about":"aug places B to the right of A to make one wider matrix. Its usual job is the augmented matrix [A | b] of a linear system, ready for row reduction.","examples":["aug([1, 2; 3, 4], [5; 6])","rref(aug([2, 1; 1, 3], [3; 5]))"],"more":[],"notes":["A and B need the same number of rows."],"keywords":"augment concatenate join append"},{"group":"Build","title":"Submatrix","syntax":"sub(A, i, j)","ins":"sub()","back":1,"desc":"Submatrix without row i and column j","about":"sub(A, i, j) removes row i and column j from A and returns what is left. The determinant of that smaller matrix is the minor used in cofactor expansion.","examples":["sub([1, 2, 3; 4, 5, 6; 7, 8, 9], 1, 1)"],"more":[],"notes":["Rows and columns are counted from 1."],"keywords":"submatrix delete remove minor"},{"group":"Build","title":"Rows and columns","syntax":"row(A, i),  column(A, j)","ins":"row()","back":1,"desc":"Pull out one row or one column","about":"row(A, i) returns row i of a matrix as a row vector, and column(A, j) returns column j as a column vector.","examples":["row([1, 2; 3, 4], 2)","column([1, 2; 3, 4], 1)"],"more":[],"notes":["Rows and columns are counted from 1."],"keywords":"row column extract vector"},{"group":"Build","title":"Kronecker product","syntax":"kron(A, B)","ins":"kron()","back":1,"desc":"Kronecker product","about":"The Kronecker product builds one large matrix out of two smaller ones. Every entry of the first matrix is replaced by a whole copy of the second matrix multiplied by that entry, so the result is a grid of blocks.\n\nIn the example the first matrix has the entries 1, 2, 3 and 4, so the result is made of four blocks: 1 times the second matrix, 2 times it, 3 times it and 4 times it.","examples":["kron([1, 2; 3, 4], [1, 0; 0, 1])"],"more":[],"notes":["A matrix with m rows and n columns and one with p rows and q columns give m × p rows and n × q columns.","Order matters: kron(A, B) and kron(B, A) arrange the same numbers differently.","The result can have up to 64 rows and columns."],"keywords":"tensor kronecker block"},{"group":"Cofactors","title":"Matrix of minors","syntax":"minors(A)","ins":"minors()","back":1,"desc":"Matrix of minors","about":"The minor of an entry is the determinant of what is left after deleting that entry’s row and column. minors(A) works this out for every entry and returns the results as a matrix.","examples":["minors([1, 2, 3; 0, 1, 4; 5, 6, 0])"],"more":[],"notes":["The matrix must be square."],"keywords":"minor"},{"group":"Cofactors","title":"Cofactor matrix","syntax":"cof(A)","ins":"cof()","back":1,"desc":"Cofactor matrix","about":"A cofactor is a minor with a sign attached: plus where row + column is even, minus where it is odd, in a chessboard pattern. Cofactors are what you multiply by when expanding a determinant along a row or column.","examples":["cof([1, 2, 3; 0, 1, 4; 5, 6, 0])"],"more":[],"notes":["The matrix must be square."],"keywords":"cofactor sign"},{"group":"Cofactors","title":"Adjugate","syntax":"adj(A)","ins":"adj()","back":1,"desc":"Adjugate (classical adjoint)","about":"The adjugate is the transpose of the cofactor matrix. Dividing it by the determinant gives the inverse: A⁻¹ = adj(A) / det(A).","examples":["adj([1, 2; 3, 4])","adj([1, 2; 3, 4]) / det([1, 2; 3, 4])"],"more":[],"notes":["It is also called the classical adjoint."],"keywords":"adjoint adjugate"},{"group":"Systems","title":"Row reduction","syntax":"rref(A)","ins":"rref()","back":1,"desc":"Reduced row echelon form — with steps in Inspect","about":"Row reduction uses three moves — swap two rows, multiply a row by a number, add a multiple of one row to another — until every leading entry is 1 with zeros above and below it. The result is the reduced row echelon form.\n\nThese moves never change the solutions of the system the matrix stands for, which is why the answer can be read straight from the result.","examples":["rref([1, 2, 3; 4, 5, 6; 7, 8, 10])","rref(aug([2, 1; 1, 3], [3; 5]))"],"more":[["How to read the result","The first non-zero entry of each row is a 1, called a pivot. The number of pivots is the rank.\n\nFor an augmented matrix [A | b], the last column is the answer when every column of A has a pivot — as in the second example, where x = 4/5 and y = 7/5.\n\nA column of A without a pivot is a free variable: the system has infinitely many solutions. A row that reads 0 … 0 | 1 says 0 = 1: the system has no solution."]],"notes":["To solve a system, augment first: rref(aug(A, b)).","Inspect lists every row operation in order."],"keywords":"echelon gauss jordan elimination reduce"},{"group":"Systems","title":"Solve a system","syntax":"solve(A, b)","ins":"solve()","back":1,"desc":"Solve Ax = b, including systems with free variables","about":"solve(A, b) finds the x for which A·x = b. If there is exactly one solution you get it. If there are infinitely many you get one of them, with a note. If there are none, Matscape says so.","examples":["solve([2, 1; 1, 3], [3; 5])","solve([1, 2; 2, 4], [3; 6])"],"more":[],"notes":["b needs as many rows as A.","With infinitely many solutions, add any multiple of null(A) to get the others.","With no solution, pinv(A)·b gives the least-squares best fit."],"keywords":"equation linear system unknowns"},{"group":"Systems","title":"Null space","syntax":"null(A)","ins":"null()","back":1,"desc":"Basis for the null space (kernel)","about":"The null space is every vector x that the matrix sends to zero: A·x = 0. null(A) returns a basis for it — a few vectors, as columns, from which all the others can be built by scaling and adding.\n\nIn the first example the answer is (−2, 1): take −2 of the first column of the matrix and 1 of the second, and they cancel.","examples":["null([1, 2; 2, 4])","null([1, 2, 3; 4, 5, 6])"],"more":[["Why it matters","If A·x = b has one solution, every other solution is that one plus something from the null space. So the null space is exactly the freedom the solutions have.\n\nWhen only the zero vector is sent to zero, the columns of A are independent and a solution, if there is one, is the only one. Matscape says so instead of returning a vector."]],"notes":["The number of basis vectors is the number of columns minus the rank.","It is also called the kernel."],"keywords":"kernel nullspace homogeneous"},{"group":"Systems","title":"Column space","syntax":"colsp(A)","ins":"colsp()","back":1,"desc":"Basis for the column space (range)","about":"The column space is everything A·x can produce: all the combinations of the columns of A. colsp(A) returns a basis for it, chosen from the columns of A.\n\nIn the example the second column is twice the first, so one column is enough to describe everything the matrix can reach.","examples":["colsp([1, 2; 2, 4])"],"more":[],"notes":["A·x = b has a solution exactly when b lies in the column space.","The number of basis vectors is the rank.","It is also called the range or the image."],"keywords":"range image column space span"},{"group":"Systems","title":"Pseudo-inverse","syntax":"pinv(A)","ins":"pinv()","back":1,"desc":"Moore–Penrose pseudo-inverse","about":"Many matrices have no inverse: they are not square, or they are singular. The pseudo-inverse is the best available substitute, and every matrix has exactly one. For an invertible matrix it is the ordinary inverse.","examples":["pinv([1, 2; 2, 4])","pinv([1; 2; 3])"],"more":[["What pinv(A)·b gives you","For the system A·x = b:\n\nIf there is exactly one solution, it gives that solution.\n\nIf there is no solution, it gives the least-squares answer: the x that brings A·x as close to b as possible. This is how a line is fitted through points that don’t lie exactly on one.\n\nIf there are infinitely many solutions, it gives the shortest one."],["How it is built","From the singular value decomposition, svd(A). Where A stretches a direction, the pseudo-inverse shrinks it back by the same amount. Where A flattens a direction to nothing, there is nothing to undo, and the pseudo-inverse leaves it at zero."]],"notes":["Its full name is the Moore–Penrose pseudo-inverse."],"keywords":"pseudo inverse least squares moore penrose"},{"group":"Systems","title":"Dot and cross product","syntax":"dot(u, v),  cross(u, v)","ins":"dot()","back":1,"desc":"Dot product; cross product of 3-vectors","about":"The dot product multiplies the matching entries of two vectors and adds them up; it is zero when the vectors are perpendicular. The cross product of two 3-vectors is a third vector perpendicular to both.","examples":["dot([1; 2; 3], [4; 5; 6])","cross([1; 0; 0], [0; 1; 0])"],"more":[],"notes":["The vectors can be rows or columns, with the same number of entries.","The cross product needs exactly three entries in each vector."],"keywords":"vector inner scalar perpendicular","sample":"Vectors — dot and cross"},{"group":"Decompose","title":"LU decomposition","syntax":"lu(A)","ins":"lu()","back":1,"desc":"PA = LU with partial pivoting","about":"LU decomposition rewrites a square matrix as a product of two triangular matrices. It is what Gaussian elimination produces if you keep a record of every step instead of throwing it away.","examples":["lu([4, 3; 6, 3])"],"more":[["What the three matrices are","L is lower triangular: every entry above its diagonal is zero, and the diagonal is all ones. Below the diagonal it keeps the multipliers that elimination used to clear each column.\n\nU is upper triangular: every entry below its diagonal is zero. It is the matrix that elimination ends with.\n\nP is a permutation matrix: an identity matrix with its rows in a different order. It records the row swaps made along the way, which keep the arithmetic accurate.\n\nTogether they satisfy P·A = L·U. In the example the two rows were swapped, which is why P is not the identity."],["Why it is useful","Triangular systems are easy to solve, one unknown at a time. Once A is factored, A·x = b becomes two quick steps: solve L·y = P·b, then U·x = y. The same L and U work for any number of right-hand sides b.\n\nThe determinant comes with it: multiply the diagonal of U, and change the sign once for every row swap."]],"notes":["The matrix must be square.","Tap any of the matrices in the result to inspect it.","A result with several parts can’t be used inside a larger expression, so keep lu on its own line."],"keywords":"lu decomposition factorization triangular gaussian"},{"group":"Decompose","title":"QR decomposition","syntax":"qr(A)","ins":"qr()","back":1,"desc":"A = QR, Q orthogonal and R upper triangular","about":"QR decomposition writes a matrix as A = Q·R: a matrix Q whose columns are perpendicular unit vectors, times an upper-triangular matrix R.","examples":["qr([3, 1; 4, 2])"],"more":[["What the two matrices are","Q is orthogonal: its columns are perpendicular to one another and each has length 1. Multiplying by Q never stretches anything — it only rotates or reflects — and its inverse is simply its transpose.\n\nR is upper triangular: every entry below its diagonal is zero. It says how to rebuild each column of A from the columns of Q.\n\nThe columns of Q are made from the columns of A, straightened one after another so that each is perpendicular to the ones before it. That is the Gram–Schmidt process. In the example the first column of A is (3, 4), which has length 5, so the first column of Q is (3/5, 4/5)."],["Why it is useful","QR is the standard way to solve least-squares problems, such as fitting a line through points that don’t lie exactly on one. Because Q doesn’t distort lengths, the problem reduces to a triangular system in R.\n\nRepeating QR again and again is also how computers find eigenvalues."]],"notes":["A doesn’t have to be square.","Tap either matrix in the result to inspect it."],"keywords":"qr decomposition orthogonal gram schmidt least squares"},{"group":"Decompose","title":"Cholesky decomposition","syntax":"chol(A)","ins":"chol()","back":1,"desc":"A = LLᵀ for symmetric positive definite A","about":"Cholesky decomposition writes a symmetric positive definite matrix as A = L·Lᵀ: a lower-triangular matrix times its own transpose. It is the matrix version of a square root.","examples":["chol([4, 2; 2, 3])"],"more":[["Which matrices it works for","Symmetric means the matrix equals its transpose. Positive definite means every eigenvalue is positive.\n\nMatrices of the form Aᵀ·A, where the columns of A are independent, are always like this. So are the covariance matrices used in statistics."],["Why it is useful","For these matrices it does the job of LU in about half the work, and it never needs row swaps.\n\nIt is also the quickest test for positive definiteness: if the matrix isn’t positive definite the factorisation fails, and Matscape says what is wrong."]],"notes":["Lower triangular: every entry above the diagonal is zero."],"keywords":"cholesky positive definite symmetric"},{"group":"Decompose","title":"Singular value decomposition","syntax":"svd(A)","ins":"svd()","back":1,"desc":"A = UΣVᵀ, singular value decomposition","about":"The singular value decomposition writes any matrix, square or not, as A = U·Σ·Vᵀ. It shows that every matrix, however complicated it looks, does three simple things in a row: turn, stretch, turn.","examples":["svd([3, 0; 0, 4])","svd([2, 2; −1, 1])"],"more":[["What the three matrices are","Vᵀ turns the input — a rotation or a reflection — so that the directions the matrix treats most simply line up with the axes.\n\nΣ is diagonal. It stretches each axis by a singular value. Singular values are never negative, and they are listed largest first.\n\nU turns the stretched result into its final position."],["How to read it","The number of non-zero singular values is the rank. A singular value of zero means a whole direction is flattened to nothing.\n\nThe largest singular value is the most the matrix can stretch any vector, which is norm2(A). The largest divided by the smallest is the condition number, cond(A)."],["Why it is useful","Keeping only the largest few singular values gives the best approximation of a matrix by a simpler one. That is the idea behind image compression, noise removal and principal component analysis.\n\nThe pseudo-inverse, pinv(A), is built from it too."]],"notes":["Tap any of the three matrices in the result to inspect it."],"keywords":"singular value svd pca compression"},{"group":"Eigen","title":"Eigenvalues","syntax":"eig(A)","ins":"eig()","back":1,"desc":"Eigenvalues, including complex ones","about":"Most vectors change direction when a matrix multiplies them. An eigenvector is one that doesn’t: A·v lies along the same line as v, only longer, shorter or reversed. The factor it is scaled by is the eigenvalue λ, so A·v = λ·v.\n\neig(A) lists every eigenvalue of the matrix.","examples":["eig([4, 1; 2, 3])","eig([0, −1; 1, 0])"],"more":[["How to read them","A matrix with n rows and n columns has n eigenvalues, counting repeats.\n\nA real eigenvalue is a stretch factor along its eigenvector: more than 1 stretches, between 0 and 1 shrinks, a negative one flips, and 0 means the matrix is singular.\n\nComplex eigenvalues come in pairs and mean the matrix rotates. The second example is a quarter turn: it leaves no line where it was, so it has no real eigenvalue."],["Why they matter","Eigenvalues describe what happens when a matrix is applied again and again: whether something grows, dies away or oscillates. They give the natural frequencies of a vibrating structure, the stability of a system of differential equations, and the long-run behaviour of a Markov chain."]],"notes":["The matrix must be square.","Their sum is the trace and their product is the determinant.","They are the roots of the characteristic polynomial, charpoly(A)."],"keywords":"eigenvalue spectrum lambda"},{"group":"Eigen","title":"Eigenvectors","syntax":"eigvec(A)","ins":"eigvec()","back":1,"desc":"Eigenvectors grouped by eigenvalue","about":"For each eigenvalue λ, the eigenvectors are the directions that the matrix leaves on their own line, only scaling them by λ. eigvec(A) returns them grouped by eigenvalue.\n\nIn the example, multiplying the matrix by (1, 1) gives (5, 5): the same direction, five times as long.","examples":["eigvec([4, 1; 2, 3])"],"more":[["Diagonalising a matrix","Suppose a matrix with n rows and columns has n independent eigenvectors. Put them side by side as the columns of a matrix P, and put the eigenvalues on the diagonal of a matrix D. Then A = P·D·P⁻¹.\n\nThis makes powers easy: a power of A is P times the same power of D times P⁻¹, and a power of D just raises each eigenvalue to that power."]],"notes":["Any multiple of an eigenvector is also an eigenvector, so the scale shown is a choice.","Eigenvectors are given for real eigenvalues. eig(A) still lists complex ones."],"keywords":"eigenvector direction diagonalise"},{"group":"Eigen","title":"Characteristic polynomial","syntax":"charpoly(A)","ins":"charpoly()","back":1,"desc":"Characteristic polynomial det(λI − A)","about":"The characteristic polynomial is det(λI − A), written out as a polynomial in λ. Setting it equal to zero and solving gives the eigenvalues.","examples":["charpoly([4, 1; 2, 3])","eig([4, 1; 2, 3])"],"more":[["How it connects","For a 2×2 matrix it is always λ² minus the trace times λ plus the determinant. In the example the trace is 7 and the determinant is 10.\n\nIt factors as (λ − 5)(λ − 2), so the eigenvalues are 5 and 2, which is what the second example shows."]],"notes":["The matrix must be square."],"keywords":"characteristic polynomial roots"},{"group":"Matrix functions","title":"Matrix exponential","syntax":"expm(A)","ins":"expm()","back":1,"desc":"Matrix exponential, e to the power A","about":"For a number, eˣ = 1 + x + x²/2! + x³/3! + … The matrix exponential uses the same series with a square matrix in place of x: I + A + A²/2! + A³/3! + … The result is a matrix of the same size.","examples":["expm([1, 0; 0, 2])","expm([0, −π; π, 0])"],"more":[["Not the same as exp","exp(A) raises e to each entry on its own. expm(A) uses matrix powers, so the entries mix.\n\nFor a diagonal matrix, expm raises e to each diagonal entry and leaves the zeros alone, as the first example shows."],["Why it is useful","It solves systems of linear differential equations. If the rate of change of x is A·x, then x at time t is expm(t·A) times x at the start.\n\nThe second example is a rotation. Its matrix describes turning at π radians per unit of time, and the exponential is the result after one unit: half a turn, which is −I."]],"notes":["The matrix must be square."],"keywords":"exponential differential"},{"group":"Matrix functions","title":"Matrix sine and cosine","syntax":"sinm(A),  cosm(A)","ins":"sinm()","back":1,"desc":"Matrix sine and cosine","about":"Matrix sine and cosine use the same power series as sin and cos, with matrix powers in place of numbers. They are not sin(A) and cos(A), which work entry by entry.","examples":["sinm([0, 1; 1, 0])","cosm([0, 1; 1, 0])"],"more":[],"notes":["As with numbers, sinm(A)² + cosm(A)² is the identity."],"keywords":"trig sine cosine"},{"group":"Matrix functions","title":"Matrix square root","syntax":"sqrtm(A)  or  A^0.5","ins":"sqrtm()","back":1,"desc":"Principal matrix square root","about":"The matrix square root is a matrix that gives A when multiplied by itself. sqrtm(A) returns the principal one. It is not the square root of each entry.","examples":["sqrtm([5, 4; 4, 5])","sqrtm([5, 4; 4, 5])²"],"more":[],"notes":["A^0.5 means the same thing.","A needs to have no zero or negative eigenvalues."],"keywords":"root square"},{"group":"Trig & scalar","title":"Sine, cosine, tangent","syntax":"sin, cos, tan","ins":"sin()","back":1,"desc":"On a matrix, these apply to every entry","about":"The three basic trigonometric functions. An angle is read in radians or degrees according to the RAD/DEG setting; add ° to a number to make it degrees whatever the setting. Results stay exact where they can, such as 1/2.","examples":["sin(30°)","tan(45°)","cos([0°, 60°; 90°, 180°])"],"more":[],"notes":["On a matrix they apply to every entry. For the true matrix sine and cosine use sinm and cosm."],"keywords":"trigonometry sine cosine tangent"},{"group":"Trig & scalar","title":"Secant, cosecant, cotangent","syntax":"sec, csc, cot","ins":"sec()","back":1,"desc":"Reciprocal trig functions","about":"The reciprocal functions: sec x = 1 / cos x, csc x = 1 / sin x and cot x = 1 / tan x.","examples":["sec(60°)","csc(30°)","cot(45°)"],"more":[],"notes":[],"keywords":"trigonometry reciprocal secant cosecant cotangent"},{"group":"Trig & scalar","title":"Inverse trig","syntax":"asin, acos, atan","ins":"asin()","back":1,"desc":"Inverse trig — answers follow the RAD/DEG setting","about":"The inverse functions give back the angle: asin(1/2) is the angle whose sine is 1/2. The answer is in radians or degrees, following the RAD/DEG setting.","examples":["asin(1/2)","acos(0)","atan(1)"],"more":[],"notes":["asin and acos take values from −1 to 1."],"keywords":"arcsin arccos arctan inverse trigonometry angle"},{"group":"Trig & scalar","title":"Hyperbolic functions","syntax":"sinh, cosh, tanh","ins":"sinh()","back":1,"desc":"Hyperbolic functions","about":"The hyperbolic functions are built from eˣ: sinh x = (eˣ − e⁻ˣ) / 2, cosh x = (eˣ + e⁻ˣ) / 2 and tanh x = sinh x / cosh x. They don’t use the angle setting.","examples":["sinh(1)","cosh(0)","tanh(1)"],"more":[],"notes":[],"keywords":"hyperbolic"},{"group":"Trig & scalar","title":"Degrees","syntax":"sin(30°)","ins":"°","back":0,"desc":"Mark any angle in degrees, whatever the setting","about":"Put ° after a number to say it is in degrees, whatever the RAD/DEG setting is. It is handy for one-off angles and inside matrix entries, such as a rotation by 30°.","examples":["sin(30°)","cos(60°) + sin(30°)"],"more":[],"notes":[],"keywords":"degree angle radians","sample":"Trig inside matrices"},{"group":"Trig & scalar","title":"Logarithms and exponential","syntax":"ln, log, exp","ins":"ln()","back":1,"desc":"Natural log, log base 10, eˣ","about":"ln is the natural logarithm (base e), log is the logarithm base 10, and exp(x) is e raised to the power x. The constant e can also be typed on its own.","examples":["ln(e²)","log(1000)","exp(1)"],"more":[],"notes":["Logarithms need a positive number."],"keywords":"logarithm natural exponential euler"},{"group":"Trig & scalar","title":"Roots and factorial","syntax":"√x,  ∛x,  n!","ins":"√","back":0,"desc":"Roots and factorial","about":"√ is the square root and ∛ the cube root; each applies to the number or bracket that follows it. n! multiplies the whole numbers from 1 up to n. Square roots stay exact where they can: √8 is shown as 2√2.","examples":["√8","∛27","5!"],"more":[],"notes":["A number in front multiplies: 2√3."],"keywords":"sqrt cbrt root factorial surd"},{"group":"Trig & scalar","title":"Rounding and remainders","syntax":"abs, round, floor, ceil, mod","ins":"abs()","back":1,"desc":"Rounding and remainders","about":"abs removes the sign. round goes to the nearest whole number, floor always goes down and ceil always goes up. mod(a, b) is the remainder when a is divided by b.","examples":["abs(−7)","round(2.6)","mod(17, 5)"],"more":[],"notes":[],"keywords":"absolute modulo remainder round floor ceiling"}],"samples":{"Basics":"Basics — add, multiply, transpose","Measures":"Determinant, trace, rank & norms","Build":"Building matrices","Cofactors":"Minors, cofactors & adjugate","Systems":"Linear systems","Decompose":"Decompositions — LU, QR, Cholesky, SVD","Eigen":"Eigenvalues & eigenvectors","Matrix functions":"Matrix functions — expm, sinm, sqrtm","Trig & scalar":"Numbers, fractions & exact results"}};
  const LIB = LIBDATA.ops;
  const LIB_GROUPS = ['All', ...new Set(LIB.map((x) => x.group))];
  function renderLibrary() {
    return `${subHead('Operations')}
      <div class="od-scroll sub-scroll">
        <label class="field-label" for="libQ">Search operations</label>
        <div class="search-box">${icon('search')}<input id="libQ" type="search" value="${esc(ui.libQuery)}" placeholder="inverse, eigen, sin…" autocomplete="off" data-act="lib-q"></div>
        <div class="od-rail chips" role="group" aria-label="Filter by group">${LIB_GROUPS.map((g) => `<button type="button" class="chip" data-act="lib-chip" data-g="${esc(g)}" aria-pressed="${ui.libGroup === g}">${esc(g)}</button>`).join('')}</div>
        <div id="libList"></div>
      </div>`;
  }
  function renderLibList() {
    const list = $('#libList', host()); if (!list) return;
    const q = ui.libQuery.trim().toLowerCase(), tokens = q.split(/\s+/).filter(Boolean);
    const items = LIB.map((x, i) => Object.assign({ i }, x)).filter((x) => (ui.libGroup === 'All' || x.group === ui.libGroup)
      && tokens.every((t) => `${x.title} ${x.syntax} ${x.desc} ${x.keywords} ${x.group}`.toLowerCase().includes(t)));
    if (!items.length) {
      list.innerHTML = `<div class="empty">${icon('search')}<span class="empty-title">No operations match “${esc(ui.libQuery)}”</span><p>Try a shorter word like “inv”, “eig” or “trig”, or clear the filter.</p><button type="button" class="btn btn--fit" data-act="lib-clear">Clear search</button></div>`;
      return;
    }
    const groups = [...new Set(items.map((x) => x.group))];
    list.innerHTML = groups.map((g) => `<section class="group"><h2 class="group-title">${esc(g)}</h2><ul class="list card">${items.filter((x) => x.group === g).map((x) => `<li><button type="button" class="lib-row" data-act="op-open" data-i="${x.i}"><span class="od-field"><span class="lib-syn">${esc(x.syntax)}</span><span class="lib-desc">${esc(x.desc)}</span></span><span class="row-chev">${icon('chev')}</span></button></li>`).join('')}</ul></section>`).join('');
  }
  /* One example: the matrices it uses drawn properly, the expression with
     their names, the answer, and the same thing typed in one line. */
  function libExamples(op) {
    const env = { vars: {}, angle: state.settings.angle };
    return op.examples.map((inline) => {
      const given = [], used = new Set((inline.match(/[A-Z]/g) || []));
      let named = inline;
      if (!op.inlineOnly) {
        let out = '', depth = 0, start = -1;
        for (let i = 0; i < inline.length; i++) {
          const c = inline[i];
          if (c === '[') { if (depth === 0) start = i; depth++; }
          else if (c === ']') {
            depth--;
            if (depth === 0 && start >= 0) {
              const lit = inline.slice(start, i + 1), r = E.evaluate(lit, { vars: {}, angle: env.angle });
              const letter = 'ABCDEFGHJKLMNPQRSTUVWXYZ'.split('').find((L) => !used.has(L));
              if (r.ok && E.isMat(r.value) && letter) { used.add(letter); given.push([letter, r.value]); out += letter; } else out += lit;
              start = -1; continue;
            }
          }
          if (depth === 0) out += c;
        }
        named = out;
      }
      const res = E.evaluate(inline, env);
      if (res.ok && res.assign && (E.isMat(res.value) || E.isNum(res.value))) env.vars[res.assign] = res.value;
      return { inline, named, given, res };
    });
  }
  function renderOp() {
    const op = LIB[ui.params.i]; if (!op) return `${subHead('Operations')}<div class="od-scroll sub-scroll"></div>`;
    const ex = libExamples(op), sampleName = op.sample || LIBDATA.samples[op.group];
    const sample = state.workspaces.find((w) => w.name === sampleName);
    const paras = (t) => t.split('\n\n').map((p) => `<p class="op-p">${esc(p)}</p>`).join('');
    const insLabel = op.ins.replace(/\(\)$/, '( )').trim();
    const exHTML = ex.map((e) => `<div class="op-ex">
        ${e.given.length ? `<div class="op-given">${e.given.map(([L, M]) => `<span class="op-giv"><i class="math">${L}</i><span class="res-eq">=</span><span class="res-scroll">${matrixHTML(M)}</span></span>`).join('')}</div>` : ''}
        <div class="res-scroll"><span class="op-named math">${esc(e.named)}</span></div>
        ${e.res.ok ? `<div class="res-row"><span class="res-eq">=</span><div class="res-scroll">${valueHTML(e.res.value)}</div></div>` : errorHTML(e.res.error, e.res.hint)}
        ${e.named !== e.inline ? `<span class="op-cap">Typed in one line</span><span class="op-inline math">${esc(e.inline)}</span>` : ''}
      </div>`).join('');
    return `${subHead('Operations')}
      <div class="od-scroll sub-scroll op-page">
        <h2 class="group-title">${esc(op.group)}</h2>
        <p class="op-title" role="heading" aria-level="2">${esc(op.title)}</p>
        <div class="card op-syntax"><span class="op-cap">How to write it</span><span class="op-syn math">${esc(op.syntax)}</span></div>
        <div class="op-about">${paras(op.about)}${op.more.map(([h, t]) => `<p class="op-h" role="heading" aria-level="3">${esc(h)}</p>${paras(t)}`).join('')}</div>
        <h2 class="group-title">${ex.length === 1 ? 'Example' : 'Examples'}</h2>
        <div class="card op-exs">${exHTML}</div>
        ${op.notes.length ? `<h2 class="group-title op-gap">Good to know</h2><ul class="op-notes">${op.notes.map((n) => `<li>${esc(n)}</li>`).join('')}</ul>` : ''}
        ${sample ? `<h2 class="group-title op-gap">More to explore</h2><div class="card"><button type="button" class="row-btn" data-act="ws-open" data-id="${sample.id}">${icon('folder')}<span class="od-field"><span class="row-title">${esc(sample.name)}</span><span class="row-sub">Sample workspace on this topic</span></span><span class="row-chev">${icon('chev')}</span></button></div>` : ''}
      </div>
      <footer class="op-foot">
        <button type="button" class="btn" data-act="op-insert">Insert ${esc(insLabel)}</button>
        <button type="button" class="btn btn--primary" data-act="op-try">${icon('plus')}Try it out</button>
      </footer>`;
  }
  function insertFromOutside(text, back = 0) {
    closeScreen();
    let l = lineById(ui.activeLineId);
    if (!l) l = addLine(null);
    const inp = document.getElementById('in-' + l.id);
    if (!inp) return;
    inp.focus();
    insertInto(inp, text, back);
    toast(`Inserted ${text.replace(/\(\)$/, '( )').trim()}`);
  }

  /* ---------- steps: the working, one operation at a time ---------- */
  const STEP_HEAVY = 50; // above this much working, show the loader row first
  function mathHTML(t) {
    return esc(t).replace(/(^|[^A-Za-z&;#])([A-Za-zλσ])(?![A-Za-z(])/g, '$1<i>$2</i>');
  }
  function solutionFor(id) {
    const l = lineById(id), res = l && cache.lines.get(id);
    return l && res && res.ok ? E.explain(l.text, cache.env) : null;
  }
  function workHTML(work) {
    let opN = 0;
    const one = (w) => {
      if (w.k === 'text') return `<p class="wk-text">${mathHTML(w.text)}</p>`;
      if (w.k === 'math') return `<p class="wk-math">${mathHTML(w.text)}</p>`;
      if (w.k === 'matrix') return `<div class="wk-mat">${w.label ? `<p class="wk-cap">${mathHTML(w.label)}</p>` : ''}<div class="res-scroll">${matrixHTML(w.mat, { aug: w.aug })}</div></div>`;
      opN++;
      return `<div class="wk-ops"><div class="wk-ops-head"><span class="wk-num" aria-hidden="true">${opN}</span><p>${w.ops.map(mathHTML).join('<br>')}</p></div><div class="res-scroll">${matrixHTML(w.mat, { aug: w.aug })}</div></div>`;
    };
    // working that belongs to a minor sits one level in, with a guide line
    const group = (list, depth) => {
      let out = '', i = 0;
      while (i < list.length) {
        if ((list[i].indent || 0) > depth) {
          const run = []; while (i < list.length && (list[i].indent || 0) > depth) run.push(list[i++]);
          out += `<div class="wk-ind">${group(run, depth + 1)}</div>`;
        } else out += one(list[i++]);
      }
      return out;
    };
    return group(work, 0);
  }
  function stepCardHTML(sol, i) {
    const st = sol.steps[i], last = i === sol.steps.length - 1, open = ui.st.open.has(i);
    const mi = Math.min(ui.st.method[i] || 0, Math.max(0, st.methods.length - 1)), m = st.methods[mi];
    const loading = open && m && ui.st.loading.has(`${i}:${mi}`);
    const valRow = E.isNum(st.value) ? `<p class="st-val"><span class="res-eq">=</span> <span class="res-value">${numHTML(st.value)}</span></p>`
      : `<div class="res-row st-val"><span class="res-eq">=</span><div class="res-scroll">${valueHTML(st.value)}</div></div>`;
    let work = '';
    if (st.methods.length) {
      work = `<button type="button" class="st-toggle" data-act="st-toggle" data-i="${i}" aria-expanded="${open}"><span>${open ? 'Hide the working' : 'Show the working'}</span>${icon(open ? 'up' : 'down')}</button>`;
      if (open) {
        work += `<div class="st-work">
          ${st.methods.length > 1 ? `<div class="st-methods"><div class="seg seg--hug" role="group" aria-label="Method">${st.methods.map((x, k) => `<button type="button" data-act="st-method" data-i="${i}" data-m="${k}" aria-pressed="${k === mi}">${esc(x.name)}</button>`).join('')}</div></div>` : ''}
          ${loading ? `<p class="st-loading" role="status"><span class="spinner" aria-hidden="true"></span>Working out the full solution…</p>` : `<div class="wk-list">${workHTML(m.work)}</div>`}
        </div>`;
      }
    }
    return `<li class="st-card${last ? ' is-answer' : ''}" data-step="${i}">
      <div class="st-head"><span class="st-num" aria-hidden="true">${i + 1}</span><h3 class="st-title">${esc(st.title)}</h3>${last ? '<span class="st-tag">Answer</span>' : ''}</div>
      <div class="st-body"><p class="st-expr">${mathHTML(st.expr)}</p>${valRow}${st.note ? `<p class="st-note">${esc(st.note)}</p>` : ''}</div>
      ${work}
    </li>`;
  }
  function renderSteps() {
    const p = ui.params || {}, w = ws(), idx = w.lines.findIndex((l) => l.id === p.id), line = w.lines[idx];
    const title = idx < 0 ? 'Steps' : `Steps · Expression ${idx + 1}`;
    const sol = line ? solutionFor(line.id) : null;
    if (!sol || !sol.steps.length) {
      return `${subHead(title)}<div class="od-scroll sub-scroll">
        ${sol ? `<div class="st-hero"><p class="st-hero-expr">${mathHTML(sol.expr)}</p><div class="res-row st-hero-val"><span class="res-eq">=</span><div class="res-scroll">${valueHTML(sol.value)}</div></div></div>` : ''}
        <div class="empty">${icon('steps')}<span class="empty-title">Nothing to work out</span><p>This is a value on its own. Combine it with something, like A·B or det(A), to see the working.</p></div></div>`;
    }
    const key = `${line.id}|${line.text}|${state.settings.angle}`;
    if (ui.st.key !== key) {
      const keep = ui.st.keepOpen; ui.st = { key, open: new Set(sol.steps.length === 1 ? [0] : keep || []), method: {}, loading: new Set(), ready: new Set() };
    }
    const copy = `<button type="button" class="icon-btn" data-act="steps-copy" aria-label="Copy the steps">${icon('copy')}</button>`;
    return `${subHead(title, copy)}
      <div class="od-scroll sub-scroll steps-page">
        <div class="st-hero"><p class="st-hero-expr">${mathHTML(sol.expr)}</p>
          ${E.isNum(sol.value) ? `<p class="st-hero-val"><span class="res-eq">=</span> <span class="res-value">${numHTML(sol.value)}</span></p>` : `<div class="res-row st-hero-val"><span class="res-eq">=</span><div class="res-scroll">${valueHTML(sol.value)}</div></div>`}
        </div>
        ${sol.steps.length > 1 ? `<h2 class="group-title">${sol.steps.length} steps</h2>` : ''}
        <ol class="st-list">${sol.steps.map((_, i) => stepCardHTML(sol, i)).join('')}</ol>
      </div>`;
  }
  function rerenderSteps(focusSel) {
    const sc = $('.od-scroll', host()), top = sc ? sc.scrollTop : 0;
    renderSub();
    const sc2 = $('.od-scroll', host()); if (sc2) sc2.scrollTop = top;
    if (focusSel) { const f = $(focusSel, host()); if (f) f.focus({ preventScroll: true }); }
  }
  function openWorking(i, mi) {
    const sol = solutionFor(ui.params.id); if (!sol) return;
    const m = sol.steps[i] && sol.steps[i].methods[mi], k = `${i}:${mi}`;
    if (m && m.weight >= STEP_HEAVY && !ui.st.ready.has(k) && !document.documentElement.classList.contains('is-shot')) {
      ui.st.loading.add(k);
      setTimeout(() => { ui.st.loading.delete(k); ui.st.ready.add(k); if (ui.screen === 'steps') rerenderSteps(); }, 650);
    } else ui.st.ready.add(k);
  }
  function stepsCopyText(sol) {
    const s = state.settings;
    if (latex()) {
      const rows = sol.steps.map((st) => `${st.tex} &= ${E.texValue(st.value, s.display, s.precision)}`);
      return `\\begin{align*}\n${rows.join(' \\\\\n')}\n\\end{align*}`;
    }
    const val = (v) => (E.isNum(v) ? numText(v) : E.isMat(v) ? matText(v) : resultSummary(v));
    return [`${sol.expr} = ${val(sol.value)}`, ''].concat(sol.steps.map((st, i) => `${i + 1}. ${st.title}: ${st.expr} = ${val(st.value)}`)).join('\n');
  }

  /* inspector */
  function inspectTarget() {
    const p = ui.params;
    if (!p) return { title: 'Inspector', value: null, error: '', none: true };
    if (p.kind === 'matrix') {
      const m = ws().matrices.find((x) => x.id === p.id), r = m && cache.mats.get(m.id);
      return { title: m ? `${p.auto ? 'Inspector · ' : ''}Matrix ${m.name}` : 'Matrix', value: r && r.ok ? r.value : null, error: r && !r.ok ? `Row ${r.bad.i + 1}, column ${r.bad.j + 1}: ${r.bad.error}` : (!m ? 'This matrix no longer exists.' : ''), m };
    }
    const idx = ws().lines.findIndex((l) => l.id === p.id), res = cache.lines.get(p.id);
    let v = res && res.ok ? res.value : null, label = '';
    if (v && v.type === 'multi') { const part = v.parts[p.part || 0]; v = part ? part.value : null; label = part ? ` · ${part.label}` : ''; }
    const title = `${p.auto ? 'Inspector · ' : ''}Expression ${idx + 1}${label}`;
    if (!E.isMat(v)) return { title, value: null, noMatrix: true, line: idx < 0 ? null : ws().lines[idx], res, v };
    return { title, value: v, error: '' };
  }
  function renderInspector() {
    const t = inspectTarget();
    if (t.none) return `${subHead('Inspector')}<div class="od-scroll sub-scroll"><div class="empty">${icon('eye')}<span class="empty-title">Nothing to inspect yet</span><p>Write an expression that gives a matrix, or create a matrix. Its properties, eigenvalues and steps appear here.</p></div></div>`;
    if (t.noMatrix) return noMatrixHTML(t);
    if (!t.value) return `${subHead(t.title)}<div class="od-scroll sub-scroll"><div class="empty">${icon('alert')}<span class="empty-title">Nothing to inspect</span><p>${esc(t.error)}</p></div></div>`;
    const A = t.value, sq = A.rows === A.cols, safe = (f) => { try { return f(); } catch (e) { return null; } };
    const d = sq ? safe(() => E.det(A)) : null, tr = sq ? E.traceOf(A) : null, rk = E.rank(A);
    const stat = (val, cap) => `<div class="stat od-stat"><span class="stat-val">${val}</span><span class="stat-cap">${cap}</span></div>`;
    const props = E.properties(A).filter((p) => p.key !== 'square' || !sq);
    const eig = sq ? safe(() => E.eigenvalues(A)) : null, cp = sq ? safe(() => E.charpoly(A)) : null;
    const condV = safe(() => E.cond(A));
    const stepKinds = sq ? [['det', 'Determinant'], ['inverse', 'Inverse'], ['rref', 'RREF']] : [['rref', 'RREF']];
    if (!stepKinds.some(([k]) => k === ui.inspStep)) ui.inspStep = stepKinds[0][0];
    const decKinds = sq ? [['lu', 'LU'], ['qr', 'QR'], ['svd', 'SVD'], ['chol', 'Cholesky']] : [['qr', 'QR'], ['svd', 'SVD']];
    if (!decKinds.some(([k]) => k === ui.inspDec)) ui.inspDec = decKinds[0][0];
    const actions = t.m
      ? `<button type="button" class="btn" data-act="insp-edit">${icon('edit')}Edit entries</button><button type="button" class="btn btn--primary" data-act="insp-use">${icon('plus')}Use in a new line</button>`
      : `<button type="button" class="btn" data-act="insp-copy">${icon('copy')}Copy</button><button type="button" class="btn btn--primary" data-act="insp-save">${icon('save')}Save as matrix</button>`;
    return `${subHead(t.title)}
      <div class="od-scroll sub-scroll">
        <div class="insp-hero"><div class="res-scroll">${matrixHTML(A)}</div><span class="insp-dims">${A.rows} rows × ${A.cols} columns</span></div>
        <div class="od-grid stats">
          ${stat(`${A.rows}×${A.cols}`, sq ? 'Square' : 'Rectangular')}
          ${stat(d == null ? '—' : numHTML(d), sq ? 'Determinant' : 'Determinant · square only')}
          ${stat(tr == null ? '—' : numHTML(tr), sq ? 'Trace' : 'Trace · square only')}
          ${stat(String(rk), rk === Math.min(A.rows, A.cols) ? 'Rank · full' : 'Rank · deficient')}
        </div>
        <section class="group"><h2 class="group-title">Properties</h2>
          <div class="od-grid props">${props.map((p) => `<div class="prop ${p.value ? 'is-yes' : 'is-no'}">${icon(p.value ? 'check' : 'minus')}<span class="label">${esc(p.label)}</span><span class="sr-only">${p.value ? ': yes' : ': no'}</span></div>`).join('')}</div>
        </section>
        ${sq ? `<section class="group"><h2 class="group-title">Eigenvalues</h2>
          ${eig ? `<div class="eig-list">${eig.map((z, i) => `<span class="eig-chip"><i>λ</i><sub>${i + 1}</sub> = ${complexHTML(z)}</span>`).join('')}</div>` : '<p class="step-note">Couldn’t compute eigenvalues for this matrix.</p>'}
          ${cp ? `<p class="step-note">Characteristic polynomial</p><p class="poly">p(<i>λ</i>) = ${polyHTML(cp)}</p>` : ''}
        </section>` : ''}
        <section class="group"><h2 class="group-title">Norms</h2>
          <div class="card">
            <div class="kv"><span class="k">Frobenius ‖A‖<sub>F</sub></span><span class="v">${numHTML(E.frob(A))}</span></div>
            <div class="kv"><span class="k">Spectral ‖A‖<sub>2</sub></span><span class="v">${numHTML(E.norm2(A))}</span></div>
            <div class="kv"><span class="k">1-norm (max column sum)</span><span class="v">${numHTML(E.norm1(A))}</span></div>
            <div class="kv"><span class="k">∞-norm (max row sum)</span><span class="v">${numHTML(E.normInf(A))}</span></div>
            <div class="kv"><span class="k">Condition number</span><span class="v">${condV == null ? '—' : condV === Infinity ? '∞ · singular' : numHTML(condV)}</span></div>
          </div>
        </section>
        <section class="group"><h2 class="group-title" id="stepsH">Step by step</h2>
          <div class="seg" role="group" aria-labelledby="stepsH">${stepKinds.map(([k, l]) => `<button type="button" data-act="insp-step" data-k="${k}" aria-pressed="${ui.inspStep === k}">${l}</button>`).join('')}</div>
          <div id="inspSteps">${stepsHTML(ui.inspStep, A)}</div>
        </section>
        <section class="group"><h2 class="group-title" id="decH">Decompose</h2>
          <div class="seg" role="group" aria-labelledby="decH">${decKinds.map(([k, l]) => `<button type="button" data-act="insp-dec" data-k="${k}" aria-pressed="${ui.inspDec === k}">${l}</button>`).join('')}</div>
          <div id="inspDec">${decompHTML(ui.inspDec, A)}</div>
        </section>
        <div class="btn-row">${actions}</div>
      </div>`;
  }
  /* An expression with no matrix result: says what it gives instead, and
     lists the matrices it uses so they are one tap away. */
  function noMatrixHTML(t) {
    const { line, res, v } = t;
    let head, body;
    if (!line) { head = 'Nothing to inspect'; body = 'This expression no longer exists.'; }
    else if (!res || res.empty || !line.text.trim()) { head = 'Nothing to inspect yet'; body = 'Finish this expression to see what it gives.'; }
    else if (!res.ok) { head = 'Nothing to inspect yet'; body = 'This expression has an error. Once it gives a matrix, its properties and steps appear here.'; }
    else {
      const what = E.isNum(v) ? 'a number' : v && v.type === 'list' ? 'a list of numbers' : v && v.type === 'poly' ? 'a polynomial' : 'no matrix';
      head = 'No matrix to inspect'; body = `This expression gives ${what}. Properties, eigenvalues and steps are shown for matrix results.`;
    }
    const names = new Set();
    ((line && line.text) || '').replace(/[A-Za-z_][A-Za-z0-9_]*/g, (id) => { (/^[A-Z]{2,}$/.test(id) ? id.split('') : [id]).forEach((n) => names.add(n)); return id; });
    const used = ws().matrices.filter((m) => names.has(m.name) && (cache.mats.get(m.id) || {}).ok);
    const canSteps = line && res && res.ok && E.hasSteps(line.text, cache.env);
    return `${subHead(t.title)}<div class="od-scroll sub-scroll">
      <div class="empty">${icon('eye')}<span class="empty-title">${esc(head)}</span><p>${esc(body)}</p>
        ${canSteps ? `<button type="button" class="text-btn" data-act="steps-line" data-line="${line.id}">${icon('steps')}See the steps</button>` : ''}</div>
      ${used.length ? `<section class="group"><h2 class="group-title">Matrices in this expression</h2><ul class="list card">${used.map((m) => `<li><button type="button" class="row-btn" data-act="insp-matrix" data-id="${m.id}" aria-label="Inspect matrix ${esc(m.name)}"><span class="nm-name math">${esc(m.name)}</span><span class="nm-sub od-fill">${m.rows}×${m.cols} · inspect</span><span class="row-chev">${icon('chev')}</span></button></li>`).join('')}</ul></section>` : ''}
    </div>`;
  }
  function stepsHTML(kind, A) {
    let r; try { r = E.steps[kind](A); } catch (e) { return errorHTML(e.message, e.hint); }
    const start = kind === 'inverse' ? 'Start with [A | I]' : 'Start with A';
    const items = [`<li class="step"><div class="step-op"><p>${start}</p></div><div class="res-scroll">${matrixHTML(r.start, { aug: r.aug })}</div></li>`];
    r.steps.forEach((s) => items.push(`<li class="step"><div class="step-op"><p>${s.ops.map(esc).join('<br>')}</p></div><div class="res-scroll">${matrixHTML(s.m, { aug: r.aug })}</div></li>`));
    if (!r.steps.length) items.push('<li class="step"><div class="step-op"><p>Already in the target form — no row operations needed.</p></div></li>');
    return `<ol class="steps">${items.join('')}</ol><div class="step-summary">${esc(r.summary)}</div>${r.note ? `<p class="step-note">${esc(r.note)}</p>` : ''}`;
  }
  function decompHTML(kind, A) {
    try {
      let parts, rel;
      if (kind === 'lu') { const r = E.lu(A); parts = [['P', r.P], ['L', r.L], ['U', r.U]]; rel = 'PA = LU'; }
      else if (kind === 'qr') { const r = E.qr(A); parts = [['Q', r.Q], ['R', r.R]]; rel = 'A = QR'; }
      else if (kind === 'svd') { const r = E.svd(A); parts = [['U', r.U], ['Σ', r.S], ['Vᵀ', r.Vt]]; rel = 'A = UΣVᵀ'; }
      else { parts = [['L', E.cholesky(A)]]; rel = 'A = LLᵀ'; }
      return `<p class="step-note">${rel}</p><div class="decomp">${parts.map(([l, M]) => `<div class="res-row"><span class="res-part-label">${l}</span><span class="res-eq">=</span><div class="res-scroll">${matrixHTML(M)}</div></div>`).join('')}</div>`;
    } catch (e) { return `<div style="margin-top:12px">${errorHTML(e.message, e.hint)}</div>`; }
  }

  /* workspaces */
  function renderWorkspaces() {
    const fmtDate = (t) => new Date(t).toLocaleDateString(undefined, { day: 'numeric', month: 'short' });
    return `${subHead('Workspaces')}
      <div class="od-scroll sub-scroll">
        <section class="group"><label class="field-label" for="wsRename">Name of this workspace</label>
          <div class="search-box">${icon('edit')}<input id="wsRename" data-act="ws-rename" value="${esc(ws().name)}" autocomplete="off" maxlength="60"></div>
        </section>
        <section class="group"><h2 class="group-title">All workspaces</h2>
          <ul class="list card">${state.workspaces.map((w) => `<li style="display:flex;align-items:center">
            <button type="button" class="row-btn" data-act="ws-open" data-id="${w.id}" ${w.id === state.currentId ? 'aria-current="true"' : ''}>
              <span class="od-field"><span class="row-title od-truncate">${esc(w.name)}</span><span class="row-sub">${w.matrices.length} matri${w.matrices.length === 1 ? 'x' : 'ces'} · ${w.lines.filter((l) => l.text.trim()).length} lines · ${fmtDate(w.updated)}</span></span>
              ${w.id === state.currentId ? '<span class="pill">Open</span>' : `<span class="row-chev">${icon('chev')}</span>`}
            </button>
            <button type="button" class="icon-btn icon-btn--sm" style="margin-right:4px" data-act="ws-delete" data-id="${w.id}" aria-label="Delete ${esc(w.name)}">${icon('trash')}</button>
          </li>`).join('')}</ul>
        </section>
        <div class="btn-row"><button type="button" class="btn btn--primary" data-act="ws-new">${icon('plus')}New workspace</button></div>
        <div class="btn-row btn-row--start"><button type="button" class="btn btn--fit" data-act="ws-restore">${icon('folder')}Restore samples</button></div>
      </div>`;
  }
  function restoreSamples() {
    const have = new Set(state.workspaces.map((w) => w.name));
    const missing = SAMPLES.filter((x) => !have.has(x[0]));
    missing.forEach((x, k) => state.workspaces.push(sampleWorkspace(x, k)));
    persist();
    return missing.length;
  }
  function switchWorkspace(id) {
    state.currentId = id;
    ui.activeLineId = (ws().lines[0] || {}).id || null;
    persist(); refreshAll();
    ui.returnFocus = null; ui.wsScroll = 0;
    closeScreen();
  }

  /* history */
  function renderHistory() {
    const ago = (t) => { const m = Math.round((Date.now() - t) / 6e4); if (m < 1) return 'just now'; if (m < 60) return `${m} min ago`; const h = Math.round(m / 60); if (h < 24) return `${h} h ago`; return `${Math.round(h / 24)} d ago`; };
    const clearBtn = state.history.length ? '<button type="button" class="text-btn" data-act="hist-clear">Clear</button>' : '<span class="od-spacer" style="width:44px;height:44px"></span>';
    const body = state.history.length
      ? `<p class="help-p">Press Enter on a line to keep it here. Tap an entry to add it as a new line.</p><ul class="list card">${state.history.map((h, i) => `<li><button type="button" class="row-btn" data-act="hist-insert" data-i="${i}"><span class="od-field"><span class="row-title math" style="font-size:18px;font-weight:400">${esc(h.text)}</span><span class="row-sub">= ${esc(h.summary)} · ${ago(h.ts)}</span></span><span class="row-chev">${icon('plus')}</span></button></li>`).join('')}</ul>`
      : `<div class="empty">${icon('clock')}<span class="empty-title">No history yet</span><p>Press Enter on any expression and it will be saved here for quick reuse.</p></div>`;
    return `${subHead('History', clearBtn)}<div class="od-scroll sub-scroll">${body}</div>`;
  }

  /* settings */
  function renderSettings() {
    const s = state.settings;
    const seg = (k, opts, label) => `<div class="seg" role="radiogroup" aria-label="${esc(label)}">${opts.map(([v, l]) => `<button type="button" role="radio" aria-checked="${s[k] === v}" data-act="set" data-k="${k}" data-v="${v}">${l}</button>`).join('')}</div>`;
    const stepper = (k, min, max, label) => `<div class="stepper" role="group" aria-label="${esc(label)}"><button type="button" data-act="set-step" data-k="${k}" data-d="-1" aria-label="Decrease ${esc(label)}" ${s[k] <= min ? 'disabled' : ''}>−</button><output aria-live="polite">${s[k]}</output><button type="button" data-act="set-step" data-k="${k}" data-d="1" aria-label="Increase ${esc(label)}" ${s[k] >= max ? 'disabled' : ''}>+</button></div>`;
    return `${subHead('Settings')}
      <div class="od-scroll sub-scroll">
        <section class="group"><h2 class="group-title">Appearance</h2><div class="card">
          <div class="set-row"><span class="od-field"><span class="row-title">Theme</span></span>${seg('theme', [['system', 'System'], ['light', 'Light'], ['dark', 'Dark']], 'Theme')}</div>
        </div></section>
        <section class="group"><h2 class="group-title">Results</h2><div class="card">
          <div class="set-row"><span class="od-field"><span class="row-title">Angle unit</span><span class="row-sub">Used by sin, cos, tan and their inverses. Add ° to any number to force degrees.</span></span>${seg('angle', [['rad', 'Radians'], ['deg', 'Degrees']], 'Angle unit')}</div>
          <div class="set-row"><span class="od-field"><span class="row-title">Number format</span><span class="row-sub">Exact shows fractions, square roots and π where it can.</span></span>${seg('display', [['exact', 'Exact'], ['decimal', 'Decimal']], 'Number format')}</div>
          <div class="set-row"><div class="set-head"><span class="od-field"><span class="row-title">Decimal places</span><span class="row-sub">For values that aren’t exact.</span></span>${stepper('precision', 2, 10, 'decimal places')}</div></div>
        </div></section>
        <section class="group"><h2 class="group-title">Copying</h2><div class="card">
          <div class="set-row"><span class="od-field"><span class="row-title">Copy as</span><span class="row-sub">For the copy button under a result and on the Steps screen. LaTeX pastes straight into a paper or notes.</span></span>${seg('copyAs', [['plain', 'Plain text'], ['latex', 'LaTeX']], 'Copy as')}</div>
        </div></section>
        <section class="group"><h2 class="group-title">New matrices</h2><div class="card">
          <div class="set-row"><div class="set-head"><span class="od-field"><span class="row-title">Rows</span></span>${stepper('defRows', 1, 8, 'default rows')}</div></div>
          <div class="set-row"><div class="set-head"><span class="od-field"><span class="row-title">Columns</span></span>${stepper('defCols', 1, 8, 'default columns')}</div></div>
          <div class="set-row"><span class="od-field"><span class="row-title">Start with</span></span>${seg('defFill', [['zero', 'Zeros'], ['identity', 'Identity']], 'New matrices start with')}</div>
        </div></section>
        <section class="group"><h2 class="group-title">About</h2><div class="card card-pad">
          <p class="help-p" style="margin:0">Matscape 2.0 — design prototype for iOS and Android. Made by ByteMechanics. Everything is calculated on your device; nothing is sent anywhere.</p>
        </div></section>
      </div>`;
  }
  function applySetting(k, v) {
    state.settings[k] = v;
    if (k === 'theme') applyTheme();
    evaluateAll(); renderRail(); updateResults(); renderKeypad(); persist();
    const focusSel = host().querySelector(`[data-act="set"][data-k="${k}"][data-v="${v}"]`) ? `[data-act="set"][data-k="${k}"][data-v="${v}"]` : null;
    const scroll = $('.od-scroll', host()).scrollTop;
    renderSub(); $('.od-scroll', host()).scrollTop = scroll;
    return focusSel;
  }

  /* help */
  function renderHelp() {
    const tries = [
      ['[1, 2; 3, 4]⁻¹', 'Inline matrix and inverse'],
      ['det([2, 1; 1, 3] − 2I)', 'Bare I takes the size it needs'],
      ['eig([0, −1; 1, 0])', 'Complex eigenvalues'],
      ['sin(30°)·I(2)', 'Trig with degrees'],
      ['expm([0, −π; π, 0])', 'Matrix exponential'],
      ['solve([2, 1; 1, 3], [3; 5])', 'Solve a linear system'],
    ];
    return `${subHead('Help & tips')}
      <div class="od-scroll sub-scroll">
        <section class="group"><h2 class="group-title">How it works</h2>
          <p class="help-p">Keep matrices at the top and write expressions underneath — every line recalculates as you type. Tap a matrix card to edit its entries; entries can be expressions too, like sin(π/6) or 2√3.</p>
          <p class="help-p">Press Enter to move to a new line. Name a result with “=” (for example M = A·B) and use M in later lines.</p>
          <p class="help-p">Tap Steps under any result to see how it was reached, one operation at a time, often by more than one method. Tap Inspect on a matrix result for its properties, eigenvalues, norms and decompositions.</p>
          <p class="help-p">Writing a paper or notes? In Settings, set Copy as to LaTeX. Results then copy as bmatrix and fractions, and a whole solution as an align block.</p>
          <div class="btn-row btn-row--start"><button type="button" class="btn btn--fit" data-act="tour-again">${icon('help')}Take the tour again</button></div>
        </section>
        <section class="group"><h2 class="group-title">Try these</h2>
          <ul class="list card">${tries.map(([t, c]) => `<li><button type="button" class="try" data-act="try" data-ins="${esc(t)}"><span class="od-field" style="flex:1 1 0"><code>${esc(t)}</code><span class="row-sub">${esc(c)}</span></span><span class="try-cap">Add</span></button></li>`).join('')}</ul>
        </section>
        <section class="group"><h2 class="group-title">Keyboard shortcuts</h2>
          <div class="card card-pad"><p class="help-p" style="margin:0">On a hardware keyboard you can type directly: * for ·, ' for transpose, ^-1 for the inverse. Enter adds a line, Backspace on an empty line removes it, ↑ and ↓ move between lines.</p></div>
        </section>
      </div>`;
  }


  /* ---------- first-launch tour (9 pages, as in the app) ---------- */
  const mini = (rows) => matrixHTML(E.mat(rows));
  const TOUR = [
    ['Welcome to Matscape', 'A matrix calculator that works like a page of notes. Keep your matrices at the top, write expressions underneath, and every answer updates as you type.',
      ['This short tour shows where everything is. It takes about a minute.', 'You can open it again any time from Help & tips in the menu.'],
      () => `<div class="tf-welcome"><span class="wordmark">Mat<i>scape</i></span><span class="tf-cap">Matrix calculator</span></div>`],
    ['Matrices live at the top', 'Each card is a matrix with a one-letter name. Tap a card to edit it, or tap New to add one.',
      ['In the editor you can change the size, rename, duplicate or delete the matrix, and fill it with zeros, an identity, random numbers and more.', 'An entry can be an expression, such as 1/2, √3 or sin(30°).', 'Drag a card by the dots in its corner to change the order.'],
      () => `<div class="tf-row">${[['A', [[4, 1], [2, 3]]], ['B', [[1, 0], [0, 1]]]].map(([n, r]) => `<div class="mx-item"><span class="mx-card"><span class="mx-card-name">${n}</span><span class="mx-card-dims">2×2</span><span class="mx-card-prev">${previewHTML(E.mat(r))}</span></span><span class="grip grip--card">${gripIcon()}</span></div>`).join('')}<span class="mx-card mx-card--new">${icon('plus')}<span>New matrix</span></span></div>`],
    ['Write expressions underneath', 'Tap a line and type with the keypad — det(A), A⁻¹, AB + 2C. The answer appears under the line and recalculates whenever a matrix changes.',
      ['Enter starts a new line. ✕ removes one.', 'Drag the numbered strip on the left to move a line up or down.', 'If something can’t be worked out, the line says why and how to fix it.'],
      () => `<ol class="lines tf-lines"><li class="line is-active"><div class="line-gutter"><span class="line-num">1</span><span class="grip grip--line">${gripIcon()}</span></div><div class="line-body"><span class="tf-in math">det(A)</span><div class="res"><div class="res-row"><span class="res-eq">=</span><span class="res-value">10</span></div></div></div></li><li class="line"><div class="line-gutter"><span class="line-num">2</span><span class="grip grip--line">${gripIcon()}</span></div><div class="line-body"><span class="tf-in math">A⁻¹</span><div class="res"><div class="res-row"><span class="res-eq">=</span>${mini([[0.3, -0.1], [-0.2, 0.4]])}</div></div></div></li></ol>`],
    ['A keypad made for matrices', 'The keypad has four pages: 123 for numbers and brackets, Matrix for determinant, inverse and transpose, f(x) for trig and logs, and More for everything else.',
      ['Your matrix names sit in a row above the keys, one tap away.', 'RAD / DEG on the f(x) page switches the angle unit.', 'The arrow at the top right hides the keypad to give results more room.'],
      () => `<div class="tf-kp"><div class="kp-tabs"><span class="kp-tab">123</span><span class="kp-tab" aria-selected="true">Matrix</span><span class="kp-tab">f(x)</span><span class="kp-tab">More</span></div><div class="tf-keys"><span class="key key--fn">det</span><span class="key key--fn">tr</span><span class="key key--fn is-math"><i>A</i><sup>T</sup></span><span class="key key--fn is-math"><i>A</i><sup>−1</sup></span><span class="key key--fn">rref</span></div></div>`],
    ['Exact answers you can reuse', 'Results stay exact where they can — fractions, square roots and multiples of π instead of long decimals.',
      ['Name a result with “=”, for example M = A·B, then use M in any other line.', 'Under a matrix result, Save keeps it as a new matrix card and Copy puts it on the clipboard.', 'Prefer decimals? Change the number format in Settings.'],
      () => `<div class="tf-exact">${[['1/3 + 1/6', 0.5], ['sin(π/4)', Math.SQRT1_2], ['√8', 2 * Math.SQRT2], ['acos(0)', Math.PI / 2]].map(([t, v]) => `<p><span class="math">${esc(t)}</span><span class="res-eq">=</span><span class="res-value">${numHTML(v)}</span></p>`).join('')}</div>`],
    ['See the working, and look inside', 'Tap Steps under any result to see how it was reached, one operation at a time. Tap Inspect under a matrix result to see everything about that matrix on one page.',
      ['Properties: square, symmetric, invertible, rank, determinant, trace.', 'Eigenvalues, norms and the condition number.', 'Steps opens to show the working, often by more than one method: cofactors or row reduction, Gauss–Jordan or the adjugate, elimination or Cramer’s rule.', 'The LU, QR, Cholesky and SVD decompositions.'],
      () => `<div class="tf-inspect">${['Symmetric', 'Invertible', 'Positive definite'].map((l) => `<span class="prop is-yes">${icon('check')}<span>${l}</span></span>`).join('')}<span class="text-btn">${icon('steps')}Steps</span><span class="text-btn">${icon('eye')}Inspect</span></div>`],
    ['Every operation, explained', 'The book at the top right opens the operations library: everything Matscape can calculate, grouped by topic and searchable.',
      ['Each operation has its own page with what it means, how to write it, and worked examples.', 'Try it out puts the examples in your workspace so you can change them.'],
      () => `<div class="card tf-panel"><div class="tf-lib"><span class="od-field"><span class="lib-syn">A⁻¹</span><span class="lib-desc">Inverse of a square, non-singular matrix</span></span><span class="row-chev">${icon('chev')}</span></div><div class="tf-lib"><span class="od-field"><span class="lib-syn">det(A)</span><span class="lib-desc">Determinant of a square matrix</span></span><span class="row-chev">${icon('chev')}</span></div></div>`],
    ['Sample workspaces to learn from', 'A workspace is one page of matrices and expressions. Matscape comes with a sample workspace for every topic, from basic arithmetic to eigenvalues and decompositions.',
      ['Open the menu and choose Workspaces to switch between them.', 'Change anything you like — or start your own with New workspace.', 'Deleted a sample? Restore samples brings it back.'],
      () => `<div class="card tf-panel">${SAMPLES.slice(0, 3).map((x) => `<div class="tf-ws">${icon('folder')}<span class="od-truncate">${esc(x[0])}</span></div>`).join('')}<div class="tf-ws tf-more">+ ${SAMPLES.length - 3} more</div></div>`],
    ['The rest is in the menu', 'History, settings and help are behind the menu button at the top left. On a tablet they are always visible in the sidebar.',
      ['History keeps the expressions you entered. Tap one to use it again.', 'Settings has the theme, radians or degrees, exact or decimal results, and the size of new matrices.', 'Help & tips has examples to try, and this tour.'],
      () => `<div class="card tf-panel tf-menu">${[['clock', 'History'], ['sliders', 'Settings'], ['help', 'Help & tips']].map(([ic, l]) => `<div class="tf-ws">${icon(ic)}<span>${l}</span></div>`).join('')}</div>`],
  ];
  function tourHTML() {
    const i = ui.tour.i, [title, body, points, fig] = TOUR[i], last = i === TOUR.length - 1;
    return `<div class="tour-top"><span class="tour-count">${i + 1} of ${TOUR.length}</span>${last ? '<span class="od-spacer" style="width:44px;height:44px"></span>' : '<button type="button" class="text-btn" data-act="tour-close">Skip</button>'}</div>
      <div class="tour-page od-scroll"><div class="tour-inner">
        <div class="tour-fig" aria-hidden="true">${fig()}</div>
        <h2 class="tour-title" id="tourT" tabindex="-1">${esc(title)}</h2>
        <p class="tour-body">${esc(body)}</p>
        <ul class="tour-points">${points.map((x) => `<li>${icon('check')}<span>${esc(x)}</span></li>`).join('')}</ul>
      </div></div>
      <div class="tour-dots" aria-hidden="true">${TOUR.map((_, k) => `<span class="${k === i ? 'is-on' : ''}"></span>`).join('')}</div>
      <div class="tour-actions">${i > 0 ? '<button type="button" class="btn" data-act="tour-back">Back</button>' : ''}<button type="button" class="btn btn--primary" data-act="${last ? 'tour-close' : 'tour-next'}">${last ? 'Get started' : 'Next'}</button></div>`;
  }
  function openTour() {
    ui.tour = { i: 0 };
    const layer = openLayer(`<div class="tour" role="dialog" aria-modal="true" aria-labelledby="tourT"></div>`, { focus: '#tourT', onClose: () => { ui.tour = null; state.toured = true; persist(); } });
    ui.tour.layer = layer; $('.tour', layer).innerHTML = tourHTML();
  }
  function tourGo(i) {
    if (!ui.tour) return;
    const dir = i > ui.tour.i ? 1 : -1;
    ui.tour.i = Math.max(0, Math.min(TOUR.length - 1, i));
    const el = $('.tour', ui.tour.layer); el.innerHTML = tourHTML();
    const pg = $('.tour-inner', el); pg.classList.add(dir > 0 ? 'is-next' : 'is-prev');
    const f = $('#tourT', el); if (f) f.focus({ preventScroll: true });
  }
  function closeTour() { if (ui.tour) closeLayer(ui.tour.layer); }

  /* ---------- drag to reorder: matrix cards, chips, strip tiles, expressions ---------- */
  function listFor(kind) { return kind === 'line' ? ws().lines : ws().matrices; }
  function applyOrder(kind, ids) {
    const arr = listFor(kind), by = new Map(arr.map((x) => [x.id, x]));
    const next = ids.map((id) => by.get(id)).filter(Boolean);
    arr.splice(0, arr.length, ...next);
    ws().updated = Date.now(); evaluateAll();
    if (kind === 'line') renderLines(); else { renderRail(); updateResults(); }
    persist();
  }
  function moveBy(kind, id, d) {
    const arr = listFor(kind), i = arr.findIndex((x) => x.id === id), j = i + d;
    if (i < 0 || j < 0 || j >= arr.length) return;
    const ids = arr.map((x) => x.id); ids.splice(j, 0, ids.splice(i, 1)[0]);
    applyOrder(kind, ids);
    const g = visibleEl(`.grip[data-drag="${kind}"][data-id="${id}"]`); if (g) g.focus();
    toast(kind === 'line' ? `Moved to line ${j + 1}` : `Moved to position ${j + 1}`);
  }
  function itemSel(kind) { return kind === 'line' ? '.line' : '.mx-item:not(.mx-item--new)'; }
  function startDrag(e, grip, kind) {
    const item = grip.closest(kind === 'line' ? '.line' : '.mx-item'); if (!item) return;
    e.preventDefault();
    const r = item.getBoundingClientRect();
    ui.drag = { kind, item, list: item.parentElement, gx: e.clientX - r.left, gy: e.clientY - r.top, moved: false, pid: e.pointerId, sx: e.clientX, sy: e.clientY };
    try { grip.setPointerCapture(e.pointerId); } catch (err) { /* noop */ }
  }
  function moveDrag(e) {
    const d = ui.drag; if (!d || e.pointerId !== d.pid) return;
    if (!d.moved && Math.hypot(e.clientX - d.sx, e.clientY - d.sy) < 4) return;
    if (!d.moved) { d.moved = true; d.item.classList.add('is-dragging'); }
    const sibs = $$(itemSel(d.kind), d.list).filter((x) => x !== d.item);
    const over = sibs.find((x) => { const b = x.getBoundingClientRect(); return e.clientX >= b.left && e.clientX <= b.right && e.clientY >= b.top && e.clientY <= b.bottom; });
    if (over) {
      const b = over.getBoundingClientRect(), all = $$(itemSel(d.kind), d.list);
      const after = all.indexOf(over) > all.indexOf(d.item);
      const horiz = b.width < d.list.getBoundingClientRect().width * 0.8;
      const past = horiz ? e.clientX > b.left + b.width / 2 : e.clientY > b.top + b.height / 2;
      if (after && past) over.after(d.item); else if (!after && !past) over.before(d.item);
    }
    d.item.style.transform = '';
    const r = d.item.getBoundingClientRect();
    d.item.style.transform = `translate(${e.clientX - d.gx - r.left}px, ${e.clientY - d.gy - r.top}px)`;
  }
  function endDrag(e) {
    const d = ui.drag; if (!d || (e && e.pointerId !== d.pid)) return;
    ui.drag = null;
    d.item.classList.remove('is-dragging'); d.item.style.transform = '';
    if (!d.moved) return;
    const ids = $$(itemSel(d.kind), d.list).map((x) => (d.kind === 'line' ? x.dataset.line : x.dataset.id));
    applyOrder(d.kind, ids);
  }
  [appEl, overlayRoot].forEach((root) => {
    root.addEventListener('pointerdown', (e) => { const g = e.target.closest('[data-drag]'); if (g && e.button === 0) startDrag(e, g, g.dataset.drag); });
    root.addEventListener('pointermove', moveDrag);
    root.addEventListener('pointerup', endDrag);
    root.addEventListener('pointercancel', endDrag);
    root.addEventListener('keydown', (e) => {
      const g = e.target.closest && e.target.closest('[data-drag]'); if (!g) return;
      const d = { ArrowUp: -1, ArrowLeft: -1, ArrowDown: 1, ArrowRight: 1 }[e.key];
      if (d) { e.preventDefault(); moveBy(g.dataset.drag, g.dataset.id, d); }
    });
  });

  /* ---------- events ---------- */
  function onMouseDown(e) {
    if (e.target.closest('.key, .name-key, .kp-tab, .cell')) e.preventDefault();
  }
  appEl.addEventListener('mousedown', onMouseDown);
  overlayRoot.addEventListener('mousedown', onMouseDown);

  function onClick(e) {
    const t = e.target.closest('[data-act]'); if (!t) return;
    const act = t.dataset.act;
    switch (act) {
      case 'key': handleKey(t); break;
      case 'kp-tab': ui.kpTab = t.dataset.tab; renderKeypad(); { const tb = document.getElementById('tab-' + ui.kpTab); if (document.activeElement === t || e.detail === 0) tb.focus(); } break;
      case 'kp-toggle': ui.kpCollapsed = !ui.kpCollapsed; renderKeypad(); $(ui.kpCollapsed ? '.kp-show' : '.kp-hide', keypadEl).focus(); break;
      case 'open-drawer': openDrawer(); break;
      case 'nav': { const to = t.dataset.to; closeLayer(); openScreen(to, {}, $('[data-act="open-drawer"]', appEl)); break; }
      case 'go': openScreen(t.dataset.to, {}, t); break;
      case 'back':
        if (ui.screen === 'op') { ui.screen = 'library'; ui.params = {}; renderSub(); const r = $(`[data-act="op-open"][data-i="${ui.libLast}"]`, host()); if (r) { r.scrollIntoView({ block: 'center' }); r.focus(); } else { const h = $('h1', host()); if (h) h.focus(); } }
        else closeScreen();
        break;
      case 'close-layer': closeLayer(); break;
      case 'new-matrix': newMatrix(t); break;
      case 'edit-matrix': openEditor(t.dataset.id, t); break;
      case 'add-line': { const l = addLine(ws().lines.length ? ws().lines[ws().lines.length - 1].id : null); focusLine(l.id); break; }
      case 'delete-line': deleteLine(t.dataset.line); break;
      case 'inspect-line': case 'inspect-part': {
        const id = t.dataset.line, part = act === 'inspect-part' ? +t.dataset.part : 0;
        if (hasDetail()) {
          // Tablets: the side inspector follows the active expression, so Inspect
          // makes this expression the active one — nothing opens on top.
          ui.autoPart[id] = part; ui.screen = null; markNav(); setActive(id); renderDetail(false);
          const h = $('h1', paneDetail); if (h) h.focus();
        } else openScreen('inspect', { kind: 'line', id, part }, t);
        break;
      }
      case 'steps-line': {
        const id = t.dataset.line;
        if (ui.screen === 'steps' && ui.params && ui.params.id === id) break;
        ui.st = { key: null };
        if (ui.screen === 'inspect' || (hasDetail() && !ui.screen)) { ui.screen = 'steps'; ui.params = { id }; renderSub(); markNav(); const h = $('h1', host()); if (h) h.focus(); }
        else openScreen('steps', { id }, t);
        break;
      }
      case 'st-toggle': {
        const i = +t.dataset.i;
        if (ui.st.open.has(i)) ui.st.open.delete(i); else { ui.st.open.add(i); openWorking(i, ui.st.method[i] || 0); }
        rerenderSteps(`[data-act="st-toggle"][data-i="${i}"]`);
        break;
      }
      case 'st-method': {
        const i = +t.dataset.i, m = +t.dataset.m;
        ui.st.method[i] = m; openWorking(i, m);
        rerenderSteps(`[data-act="st-method"][data-i="${i}"][data-m="${m}"]`);
        break;
      }
      case 'steps-copy': { const sol = solutionFor(ui.params && ui.params.id); if (sol) copyText(stepsCopyText(sol)); break; }
      case 'insp-matrix': { const id = t.dataset.id; ui.screen = 'inspect'; ui.params = { kind: 'matrix', id }; renderSub(); markNav(); { const h = $('h1', host()); if (h) h.focus(); } break; }
      case 'save-line': { const r = cache.lines.get(t.dataset.line); if (r && r.ok && E.isMat(r.value)) saveValueAsMatrix(r.value); break; }
      case 'copy-line': { const r = cache.lines.get(t.dataset.line); if (r && r.ok) copyText(lineValueText(r)); break; }
      /* editor */
      case 'ed-close': closeLayer(ui.editor && ui.editor.layer); break;
      case 'ed-dim': resizeEditor(t.dataset.k, +t.dataset.d); break;
      case 'ed-preset': presetEditor(t.dataset.p); break;
      case 'ed-key': edKey(t); break;
      case 'ed-cell': selectCell(+t.dataset.i, +t.dataset.j); break;
      case 'ed-strip': ui.editor.strip = t.dataset.k; renderEdStrip(); $(`[data-act="ed-strip"][data-k="${t.dataset.k}"]`, ui.editor.layer).focus(); break;
      case 'ed-dup': {
        const m = edMatrix(); if (!m) break;
        const copy = createMatrix(m.cells.map((r) => r.slice()));
        if (copy) { closeLayer(ui.editor.layer); toast(`Duplicated ${m.name} as ${copy.name}`); }
        break;
      }
      case 'ed-delete': {
        const m = edMatrix(); if (!m) break;
        confirmDialog({ title: `Delete matrix ${m.name}?`, body: `Lines that use ${m.name} will show an error until you create it again.`, ok: 'Delete' }, () => {
          const w = ws(); w.matrices = w.matrices.filter((x) => x.id !== m.id);
          const edLayer = ui.editor && ui.editor.layer;
          evaluateAll(); renderRail(); updateResults(); persist();
          if (edLayer) { const entry = ui.layers.find((l) => l.el === edLayer); if (entry) entry.returnFocus = visibleEl('.mx-card--new'); closeLayer(edLayer); }
          toast(`Deleted matrix ${m.name}`);
        });
        break;
      }
      case 'ed-inspect': {
        const m = edMatrix(); if (!m) break;
        const card = visibleEl(`.mx-card[data-id="${m.id}"]`);
        closeLayer(ui.editor.layer);
        openScreen('inspect', { kind: 'matrix', id: m.id }, card);
        break;
      }
      case 'alert-cancel': closeLayer(t.closest('.layer')); break;
      case 'alert-ok': { const layer = t.closest('.layer'), fnOk = layer._onOk; closeLayer(layer); if (fnOk) fnOk(); break; }
      /* library */
      case 'lib-chip': ui.libGroup = t.dataset.g; $$('[data-act="lib-chip"]', host()).forEach((c) => c.setAttribute('aria-pressed', String(c.dataset.g === ui.libGroup))); renderLibList(); break;
      case 'lib-clear': ui.libQuery = ''; ui.libGroup = 'All'; renderSub(); $('#libQ', host()).focus(); break;
      case 'op-open': { ui.libLast = +t.dataset.i; ui.screen = 'op'; ui.params = { i: +t.dataset.i }; renderSub(); const h = $('h1', host()); if (h) h.focus(); break; }
      case 'op-insert': { const x = LIB[ui.params.i]; if (x) insertFromOutside(x.ins, x.back); break; }
      case 'op-try': {
        const x = LIB[ui.params.i]; if (!x) break;
        closeScreen();
        let after = ui.activeLineId;
        const w = ws(), cur = lineById(after);
        x.examples.forEach((ex, k) => {
          if (k === 0 && cur && !cur.text.trim()) { cur.text = ex; return; }
          const idx = after ? w.lines.findIndex((l) => l.id === after) : w.lines.length - 1;
          const l = { id: uid(), text: ex }; w.lines.splice(idx + 1, 0, l); after = l.id;
        });
        w.updated = Date.now(); evaluateAll(); renderLines(); persist();
        if (after) focusLine(after);
        toast(x.examples.length === 1 ? 'Example added to your workspace' : `${x.examples.length} examples added to your workspace`);
        break;
      }
      case 'ws-restore': { const n = restoreSamples(); renderSub(); const b = $('[data-act="ws-restore"]', host()); if (b) b.focus(); toast(n === 0 ? 'All the samples are already here' : `Restored ${n} sample workspace${n === 1 ? '' : 's'}`); break; }
      case 'tour-again': openTour(); break;
      case 'tour-next': tourGo(ui.tour.i + 1); break;
      case 'tour-back': tourGo(ui.tour.i - 1); break;
      case 'tour-close': closeTour(); break;
      /* inspector */
      case 'insp-step': ui.inspStep = t.dataset.k; $$('[data-act="insp-step"]', host()).forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.k === ui.inspStep))); $('#inspSteps', host()).innerHTML = stepsHTML(ui.inspStep, inspectTarget().value); break;
      case 'insp-dec': ui.inspDec = t.dataset.k; $$('[data-act="insp-dec"]', host()).forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.k === ui.inspDec))); $('#inspDec', host()).innerHTML = decompHTML(ui.inspDec, inspectTarget().value); break;
      case 'insp-save': { const v = inspectTarget().value; if (v) saveValueAsMatrix(v); break; }
      case 'insp-copy': { const v = inspectTarget().value; if (v) copyText(latex() ? E.texValue(v, state.settings.display, state.settings.precision) : matText(v)); break; }
      case 'insp-use': { const m = inspectTarget().m; if (!m) break; closeScreen(); const l = addLine(ws().lines.length ? ws().lines[ws().lines.length - 1].id : null, m.name); focusLine(l.id); break; }
      case 'insp-edit': { const m = inspectTarget().m; if (!m) break; const opener = ui.returnFocus; closeScreen(); openEditor(m.id, opener && opener.isConnected && opener.offsetParent !== null ? opener : visibleEl(`.mx-card[data-id="${m.id}"]`)); break; }
      /* workspaces */
      case 'ws-open': if (t.dataset.id === state.currentId) closeScreen(); else { switchWorkspace(t.dataset.id); toast(`Opened ${ws().name}`); } break;
      case 'ws-new': {
        const s = state.settings, w = { id: uid(), name: `Untitled workspace ${state.workspaces.length + 1}`, updated: Date.now(), matrices: [{ id: uid(), name: 'A', rows: s.defRows, cols: s.defCols, cells: fillCells(s.defRows, s.defCols, s.defFill) }], lines: lines(['']) };
        state.workspaces.unshift(w); switchWorkspace(w.id); toast('New workspace created');
        break;
      }
      case 'ws-delete': {
        const w = state.workspaces.find((x) => x.id === t.dataset.id); if (!w) break;
        if (state.workspaces.length === 1) { toast('Keep at least one workspace'); break; }
        confirmDialog({ title: `Delete “${w.name}”?`, body: `Its ${w.matrices.length} matrices and ${w.lines.length} lines will be removed. This can’t be undone.`, ok: 'Delete' }, () => {
          state.workspaces = state.workspaces.filter((x) => x.id !== w.id);
          if (state.currentId === w.id) { state.currentId = state.workspaces[0].id; ui.activeLineId = (ws().lines[0] || {}).id || null; refreshAll(); }
          persist(); renderSub(); const h = $('h1', host()); if (h) h.focus();
          toast(`Deleted “${w.name}”`);
        });
        break;
      }
      /* history */
      case 'hist-insert': {
        const h = state.history[+t.dataset.i]; if (!h) break;
        closeScreen();
        const last = ws().lines[ws().lines.length - 1];
        const l = last && !last.text.trim() ? (last.text = h.text, evaluateAll(), renderLines(), last) : addLine(last ? last.id : null, h.text);
        focusLine(l.id); toast('Added from history');
        break;
      }
      case 'hist-clear': confirmDialog({ title: 'Clear history?', body: 'Saved expressions will be removed from this list. Your workspaces stay as they are.', ok: 'Clear' }, () => { state.history = []; persist(); renderSub(); $('h1', host()).focus(); }); break;
      /* settings */
      case 'set': { const sel = applySetting(t.dataset.k, t.dataset.v); if (sel) $(sel, host()).focus(); break; }
      case 'set-step': {
        const k = t.dataset.k, d = +t.dataset.d, lim = { precision: [2, 10], defRows: [1, 8], defCols: [1, 8] }[k];
        state.settings[k] = Math.max(lim[0], Math.min(lim[1], state.settings[k] + d));
        applySetting(k, state.settings[k]);
        const b = $(`[data-act="set-step"][data-k="${k}"][data-d="${d}"]`, host());
        (b && !b.disabled ? b : $(`[data-act="set-step"][data-k="${k}"]:not([disabled])`, host())).focus();
        break;
      }
      case 'try': {
        closeScreen();
        const l = lineById(ui.activeLineId), target = l && !l.text.trim() ? l : addLine(ui.activeLineId);
        target.text = t.dataset.ins; evaluateAll(); renderLines(); focusLine(target.id); persist(); toast('Example added');
        break;
      }
      default: break;
    }
  }
  appEl.addEventListener('click', onClick);
  overlayRoot.addEventListener('click', onClick);

  appEl.addEventListener('input', (e) => {
    const t = e.target;
    if (t.classList.contains('line-input')) onLineChanged(t);
    else if (t.dataset.act === 'lib-q') { ui.libQuery = t.value; renderLibList(); }
    else if (t.dataset.act === 'ws-rename') { ws().name = t.value.trim() || 'Untitled workspace'; renderHeader(); persist(); }
  });
  appEl.addEventListener('focusin', (e) => {
    const t = e.target;
    if (t.classList.contains('line-input')) { setActive(t.dataset.line); if (ui.kpCollapsed) { ui.kpCollapsed = false; renderKeypad(); } }
  });
  appEl.addEventListener('keydown', (e) => {
    const t = e.target;
    if (t.classList.contains('line-input')) {
      const w = ws(), idx = w.lines.findIndex((l) => l.id === t.dataset.line);
      if (e.key === 'Enter') { e.preventDefault(); commitLine(t.dataset.line); }
      else if (e.key === 'Backspace' && !t.value && w.lines.length > 1) { e.preventDefault(); deleteLine(t.dataset.line); }
      else if (e.key === 'ArrowUp' && idx > 0) { e.preventDefault(); focusLine(w.lines[idx - 1].id); }
      else if (e.key === 'ArrowDown' && idx < w.lines.length - 1) { e.preventDefault(); focusLine(w.lines[idx + 1].id); }
      else if (e.key === "'" ) { e.preventDefault(); insertInto(t, 'ᵀ'); }
      else if (e.key === '*') { e.preventDefault(); insertInto(t, '·'); }
    } else if (t.getAttribute('role') === 'tab' && (e.key === 'ArrowRight' || e.key === 'ArrowLeft')) {
      const keys = Object.keys(KEYPAD).filter((k) => !(ui.xl && k === 'num')), i = keys.indexOf(ui.kpTab);
      ui.kpTab = keys[(i + (e.key === 'ArrowRight' ? 1 : keys.length - 1)) % keys.length];
      renderKeypad(); document.getElementById('tab-' + ui.kpTab).focus(); e.preventDefault();
    }
  });
  wsScroll.addEventListener('scroll', () => { $('#wsBar').classList.toggle('is-raised', wsScroll.scrollTop > 4); }, { passive: true });

  overlayRoot.addEventListener('input', (e) => {
    const t = e.target;
    if (t.id === 'edEntry' && ui.editor) {
      const m = edMatrix(); if (!m) return;
      const [i, j] = ui.editor.cell;
      m.cells[i][j] = t.value;
      edCommit(); renderEdGrid(); renderEdDims(); updateEdPreview();
    }
  });
  overlayRoot.addEventListener('change', (e) => {
    const t = e.target;
    if (t.dataset.act === 'ed-name') {
      const m = edMatrix(); if (!m) return;
      const old = m.name; m.name = t.value;
      edAfterChange('#edName');
      const usedOld = ws().lines.some((l) => new RegExp(`(^|[^A-Za-z])${old}([^A-Za-z]|$)`).test(l.text));
      toast(usedOld ? `Renamed to ${m.name} — update lines that use ${old}` : `Renamed to ${m.name}`);
    }
  });
  overlayRoot.addEventListener('keydown', (e) => {
    const t = e.target;
    if (t.id === 'edEntry' && ui.editor) {
      const m = edMatrix(), [i, j] = ui.editor.cell;
      if (e.key === 'Enter') { e.preventDefault(); edNext(); return; }
      if (e.key === 'ArrowUp' && i > 0) { e.preventDefault(); selectCell(i - 1, j); return; }
      if (e.key === 'ArrowDown' && i < m.rows - 1) { e.preventDefault(); selectCell(i + 1, j); return; }
      if (e.key === '*') { e.preventDefault(); insertInto(t, '·'); return; }
    }
    if (e.key === 'Tab') {
      const top = ui.layers[ui.layers.length - 1]; if (!top) return;
      const f = $$('button:not([disabled]), input, select', top.el).filter((x) => !x.closest('[hidden]'));
      if (!f.length) return;
      if (e.shiftKey && document.activeElement === f[0]) { e.preventDefault(); f[f.length - 1].focus(); }
      else if (!e.shiftKey && document.activeElement === f[f.length - 1]) { e.preventDefault(); f[0].focus(); }
    }
  });
  document.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape') return;
    if (ui.layers.length) { e.preventDefault(); closeLayer(); }
    else if (ui.screen) { e.preventDefault(); closeScreen(); }
  });

  /* ---------- adaptive layout ----------
     Layout follows the space the app actually has, plus the fold posture.
     In the real app posture comes from the OS (hinge / folding feature APIs);
     in this prototype a device board passes it as ?posture=book|tabletop|glance. */
  const query = new URLSearchParams(location.search);
  const forcedPosture = query.get('posture');
  function computeLayout() {
    if (forcedPosture === 'glance' || forcedPosture === 'book' || forcedPosture === 'tabletop') return forcedPosture;
    const w = appEl.clientWidth, h = appEl.clientHeight;
    // A phone on its side: results on the left, keypad on the right.
    if (h < 500 && w >= 560) return 'landscape';
    if (w >= 1000) return 'expanded';
    if (w >= 700) return 'medium';
    return 'compact';
  }
  function applyLayout() {
    const l = computeLayout(), changed = l !== ui.layout, wasDetail = hasDetail(ui.layout);
    if (changed) {
      ui.layout = l;
      appEl.dataset.layout = l; overlayRoot.dataset.layout = l;
      if (ui.screen && wasDetail !== hasDetail(l)) {
        ui.screen = null; markNav();
        subScreen.hidden = true; subScreen.innerHTML = ''; wsScreen.hidden = false; appEl.classList.remove('has-sub');
      }
      if (!hasDetail(l)) paneDetail.innerHTML = '';
      if (l === 'tabletop' && ui.screen) appEl.classList.add('has-sub');
      if (l === 'tabletop' || l === 'landscape') ui.kpCollapsed = false;
      if (hasDetail(l)) renderDetail(false);
      if (l === 'glance') renderGlance();
    }
    const xl = l === 'expanded' && wsScreen.clientWidth >= 700;
    if (changed || xl !== !!ui.xl) { ui.xl = xl; renderKeypad(); }
  }
  ui.layout = null;
  /* A strip down one side that the system keeps for its camera and status
     items (iPhone Duo outer screen): ?strip=left|right. The matrices live in it. */
  const STRIP = query.get('strip');
  if (STRIP === 'left' || STRIP === 'right') { appEl.dataset.strip = STRIP; overlayRoot.dataset.strip = STRIP; }
  if (DEMO.has('shot')) document.documentElement.classList.add('is-shot');
  if (DEMO.get('kp') && KEYPAD[DEMO.get('kp')]) ui.kpTab = DEMO.get('kp');
  if (DEMO.get('active') && ws().lines[+DEMO.get('active')]) ui.activeLineId = ws().lines[+DEMO.get('active')].id;
  refreshAll();
  applyLayout();
  if (DEMO.get('theme') === 'dark' || DEMO.get('theme') === 'light') document.documentElement.dataset.theme = DEMO.get('theme');
  (function applyDemo() {
    const demo = DEMO.get('demo'); if (!demo) return;
    const m = ws().matrices.find((x) => x.name === (DEMO.get('m') || 'A')) || ws().matrices[0];
    if (demo === 'inspect' || demo === 'steps') {
      if (demo === 'steps') ui.inspStep = DEMO.get('step') || 'inverse';
      openScreen('inspect', { kind: 'matrix', id: m.id });
      if (demo === 'steps') {
        const sc = $('.od-scroll', host()), h = $('#stepsH', host());
        if (sc && h) sc.scrollTop = h.getBoundingClientRect().top - sc.getBoundingClientRect().top + sc.scrollTop - 12;
      }
    } else if (demo === 'solve') {
      const line = ws().lines[+(DEMO.get('line') || 0)];
      if (line) {
        openScreen('steps', { id: line.id });
        const open = (DEMO.get('open') || '').split(',').filter(Boolean).map(Number);
        open.forEach((i) => ui.st.open.add(i));
        if (DEMO.get('method')) { const [i, k] = DEMO.get('method').split(':').map(Number); ui.st.method[i] = k; }
        renderSub();
        const at = DEMO.get('scroll');
        if (at) { const card = $(`[data-step="${at}"]`, host()), sc = $('.od-scroll', host()); if (card && sc) sc.scrollTop = card.getBoundingClientRect().top - sc.getBoundingClientRect().top + sc.scrollTop - 8; }
      }
    } else if (demo === 'tour') {
      openTour(); if (DEMO.get('page')) tourGo(+DEMO.get('page'));
    } else if (demo === 'op') {
      const i = LIB.findIndex((x) => x.title === (DEMO.get('op') || 'Inverse'));
      openScreen('library', {}); ui.screen = 'op'; ui.params = { i: Math.max(0, i) }; renderSub();
    } else if (demo === 'editor') {
      openEditor(m.id, null);
    } else if (['library', 'settings', 'history', 'workspaces', 'help'].includes(demo)) {
      openScreen(demo, {});
    }
    if (document.activeElement && document.activeElement !== document.body) document.activeElement.blur();
  })();
  const embedded = (() => { try { return window.self !== window.top; } catch (e) { return true; } })();
  if (DEMO.get('tour') === '1' || (!state.toured && !FRESH && !DEMO.get('demo') && !embedded && DEMO.get('tour') !== '0')) openTour();
  if (window.ResizeObserver) new ResizeObserver(() => applyLayout()).observe(appEl);
  else window.addEventListener('resize', applyLayout);

  /* The design pages' Dark mode switch (app/board-theme.js) sets the theme
     here, the same as Settings → Theme. */
  window.addEventListener('message', (e) => {
    const d = e.data;
    if (!d || d.type !== 'matscape-theme' || !['light', 'dark', 'system'].includes(d.theme)) return;
    state.settings.theme = d.theme; applyTheme(); persist();
    if (ui.screen === 'settings') applySetting('theme', d.theme);
  });

  /* Keep several open copies in step (e.g. every device on the board). */
  window.addEventListener('storage', (e) => {
    if (e.key !== KEY || !e.newValue || ui.layers.length) return;
    const a = document.activeElement;
    if (a && (a.tagName === 'INPUT' || a.tagName === 'SELECT')) return;
    try {
      const next = JSON.parse(e.newValue);
      if (!next || !Array.isArray(next.workspaces)) return;
      state = next; state.settings = Object.assign({}, DEFAULT_SETTINGS, state.settings || {});
      if (!state.workspaces.some((w) => w.id === state.currentId)) state.currentId = state.workspaces[0].id;
      if (!lineById(ui.activeLineId)) ui.activeLineId = (ws().lines[0] || {}).id || null;
      applyTheme(); refreshAll();
      if (ui.screen && !hasDetail()) renderSub();
    } catch (err) { /* ignore malformed state */ }
  });
})();
