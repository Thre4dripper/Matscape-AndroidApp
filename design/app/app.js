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
  };
  const icon = (n) => `<svg class="od-icon" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="${ICONS[n]}"/></svg>`;

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
  function seedWorkspaces() {
    const now = Date.now();
    return [
      {
        id: uid(), name: 'Rotations & eigenvalues', updated: now,
        matrices: [
          mx('A', [[4, 1, 2], [1, 3, 0], [2, 0, 5]]),
          mx('B', [[1, 2, 3], [4, 5, 6]]),
          mx('C', [[2, 0, 1], [1, 3, 2], [1, 1, 2]]),
          mx('R', [['cos(π/4)', '−sin(π/4)'], ['sin(π/4)', 'cos(π/4)']]),
        ],
        lines: lines(['det(A)', 'C⁻¹', 'BA', 'R²', 'eig(A)', 'sin(Bπ/6)', 'M = BBᵀ', 'A + B']),
      },
      {
        id: uid(), name: 'Linear systems — HW 4', updated: now - 864e5 * 2,
        matrices: [
          mx('A', [[2, 1, -1], [-3, -1, 2], [-2, 1, 2]]),
          mx('B', [[8], [-11], [-3]]),
        ],
        lines: lines(['solve(A, B)', 'rref(aug(A, B))', 'lu(A)', 'N = [1, 2; 2, 4]', 'null(N)', 'rank(N)']),
      },
      {
        id: uid(), name: 'Trig inside matrices', updated: now - 864e5 * 6,
        matrices: [
          mx('T', [['cos(30°)', '−sin(30°)', '0'], ['sin(30°)', 'cos(30°)', '0'], ['0', '0', '1']]),
          mx('S', [[0, -1], [1, 0]]),
        ],
        lines: lines(['TᵀT', 'det(T)', 'expm(π/2·S)', 'sinm(S)', 'svd(T)']),
      },
    ];
  }
  const DEFAULT_SETTINGS = { theme: 'system', angle: 'rad', display: 'exact', precision: 4, defRows: 3, defCols: 3, defFill: 'zero' };
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
    cache = { mats, lines: out };
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
  function resultHTML(line) {
    const res = cache.lines.get(line.id);
    if (!line.text.trim() || !res) return '';
    if (res.empty) return `<p class="res-hint">Finish the expression after “=”.</p>`;
    if (!res.ok) return errorHTML(res.error, res.hint);
    const v = res.value, id = line.id;
    const notes = (res.warnings || []).map((w) => `<p class="res-note">${icon('info')}<span>${esc(w)}</span></p>`).join('');
    let body = '';
    if (E.isNum(v)) {
      body = `<div class="res-row"><span class="res-eq">=</span><div class="res-scroll"><span class="res-value">${numHTML(v)}</span></div><button type="button" class="icon-btn icon-btn--sm" data-act="copy-line" data-line="${id}" aria-label="Copy result">${icon('copy')}</button></div>`;
    } else if (E.isMat(v)) {
      body = `<div class="res-row"><span class="res-eq">=</span><div class="res-scroll">${matrixHTML(v)}</div></div>
        <div class="res-meta"><span class="dims">${v.rows}×${v.cols}${res.assign ? ` · saved as ${esc(res.assign)}` : ''}</span>
          <button type="button" class="text-btn" data-act="inspect-line" data-line="${id}">${icon('eye')}Inspect</button>
          <button type="button" class="text-btn" data-act="save-line" data-line="${id}">${icon('save')}Save as matrix</button>
          <button type="button" class="icon-btn icon-btn--sm" data-act="copy-line" data-line="${id}" aria-label="Copy matrix">${icon('copy')}</button>
        </div>`;
    } else if (v.type === 'list') {
      body = `<div class="res-row"><div class="res-scroll"><div class="res-list res-value">${v.items.map((z, i) => `<span><i>λ</i><span class="sub">${i + 1}</span> = ${complexHTML(z)}</span>`).join('')}</div></div><button type="button" class="icon-btn icon-btn--sm" data-act="copy-line" data-line="${id}" aria-label="Copy eigenvalues">${icon('copy')}</button></div>`;
    } else if (v.type === 'multi') {
      body = `${v.relation ? `<span class="res-relation">${esc(v.relation)} · tap a matrix to inspect it</span>` : '<span class="res-relation">Tap a matrix to inspect it</span>'}
        <div class="res-scroll"><div class="res-parts">${v.parts.map((p, i) => `<button type="button" class="res-part" data-act="inspect-part" data-line="${id}" data-part="${i}"><span class="res-part-label">${esc(p.label)}</span><span class="res-eq">=</span>${matrixHTML(p.value)}</button>`).join('')}</div></div>`;
    } else if (v.type === 'poly') {
      body = `<div class="res-row"><span class="res-eq">=</span><div class="res-scroll"><span class="res-value">${polyHTML(v.coeffs)}</span></div></div><span class="res-relation">p(λ) = det(λI − A)</span>`;
    } else if (v.type === 'text') {
      body = `<p class="res-hint">${esc(v.text)}</p>`;
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
    <section class="glance" id="glance" aria-label="Matscape at a glance"></section>`;
  const wsScreen = $('[data-screen="workspace"]', appEl), subScreen = $('#subScreen'), wsScroll = $('#wsScroll');
  const paneDetail = $('#paneDetail'), mxListEl = $('#mxList'), glanceEl = $('#glance');
  const linesEl = $('#lines'), railEl = $('#mxRail'), namesEl = $('#namesRail'), kpGrid = $('#kpGrid'), kpTabs = $('#kpTabs'), keypadEl = $('#keypad');

  function renderHeader() { $('#wsName').textContent = ws().name; $('#sideWsName').textContent = ws().name; }
  function renderRail() {
    const w = ws();
    railEl.innerHTML = w.matrices.map((m) => {
      const r = cache.mats.get(m.id);
      const body = r && r.ok
        ? `<span class="mx-card-prev">${previewHTML(r.value)}</span>`
        : `<span class="tag-bad">${icon('alert')}Fix entry</span>`;
      return `<button type="button" class="mx-card${r && r.ok ? '' : ' is-invalid'}" data-act="edit-matrix" data-id="${m.id}" aria-label="Matrix ${m.name}, ${m.rows} by ${m.cols}${r && r.ok ? '' : ', has an entry to fix'}. Edit">
        <span class="mx-card-name">${esc(m.name)}</span><span class="mx-card-dims">${m.rows}×${m.cols}</span>${body}</button>`;
    }).join('') + `<button type="button" class="mx-card mx-card--new" data-act="new-matrix">${icon('plus')}<span>New matrix</span></button>`;
    mxListEl.innerHTML = railEl.innerHTML;
    namesEl.innerHTML = w.matrices.map((m) => `<button type="button" class="name-key" data-act="key" data-ins="${esc(m.name)}" aria-label="Insert matrix ${esc(m.name)}">${esc(m.name)}</button>`).join('')
      + `<button type="button" class="name-key name-key--new" data-act="new-matrix" aria-label="New matrix">${icon('plus')}New</button>`;
  }
  function lineHTML(l, i) {
    return `<li class="line${l.id === ui.activeLineId ? ' is-active' : ''}" data-line="${l.id}">
      <div class="line-gutter" aria-hidden="true">${i + 1}</div>
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
    if (hasDetail() && (!ui.screen || ui.screen === 'inspect')) renderDetail(true);
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
    keypadEl.classList.toggle('is-collapsed', ui.kpCollapsed && ui.layout !== 'tabletop');
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
  function lineValueText(res) {
    const v = res.value;
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
    const act = cache.lines.get(ui.activeLineId);
    if (isMatLike(act)) return { kind: 'line', id: ui.activeLineId, part: 0, auto: true };
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
    const r = { library: renderLibrary, inspect: renderInspector, workspaces: renderWorkspaces, history: renderHistory, settings: renderSettings, help: renderHelp }[name];
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
  const LIB = [
    ['Basics', 'A + B,  A − B', '+', 0, 'Add or subtract matrices of the same size'],
    ['Basics', 'kA', '·', 0, 'Scale every entry by a number', 'scalar multiply'],
    ['Basics', 'AB  or  A·B', '·', 0, 'Matrix product — columns of A must match rows of B', 'multiply product'],
    ['Basics', 'A / B', '/', 0, 'Right division, worked out as A·B⁻¹', 'divide division'],
    ['Basics', 'Aᵀ', 'ᵀ', 0, 'Transpose — rows become columns', 'transpose'],
    ['Basics', 'A⁻¹', '⁻¹', 0, 'Inverse of a square, non-singular matrix', 'inverse'],
    ['Basics', 'Aⁿ', '^', 0, 'Whole-number powers; negative powers use the inverse', 'power exponent'],
    ['Basics', 'A ∘ B', '∘', 0, 'Entrywise (Hadamard) product', 'hadamard elementwise'],
    ['Basics', '[1, 2; 3, 4]', '[]', 1, 'Write a matrix inline — “,” between entries, “;” between rows', 'literal inline'],
    ['Basics', 'k = 3', 'k = ', 0, 'Name a value and reuse it in other lines', 'variable assign name'],
    ['Measures', 'det(A)  or  |A|', 'det()', 1, 'Determinant of a square matrix', 'determinant'],
    ['Measures', 'tr(A)', 'tr()', 1, 'Trace — sum of the diagonal', 'trace'],
    ['Measures', 'rank(A)', 'rank()', 1, 'Number of independent rows or columns'],
    ['Measures', 'norm(A)', 'norm()', 1, 'Frobenius norm', 'magnitude'],
    ['Measures', 'norm1(A),  norminf(A)', 'norm1()', 1, 'Largest column sum, largest row sum'],
    ['Measures', 'norm2(A)', 'norm2()', 1, 'Spectral norm — the largest singular value'],
    ['Measures', 'cond(A)', 'cond()', 1, 'Condition number — how sensitive A is to rounding', 'condition'],
    ['Build', 'I(n)', 'I()', 1, 'n×n identity. Bare I adapts to its neighbour: A − 2I', 'identity'],
    ['Build', 'zeros(m, n),  ones(m, n)', 'zeros()', 1, 'Matrix of zeros or ones'],
    ['Build', 'diag(v)', 'diag()', 1, 'Diagonal matrix from a vector, or the diagonal of a matrix'],
    ['Build', 'aug(A, B)', 'aug()', 1, 'Place B to the right of A', 'augment concatenate'],
    ['Build', 'sub(A, i, j)', 'sub()', 1, 'Submatrix without row i and column j', 'submatrix'],
    ['Build', 'row(A, i),  column(A, j)', 'row()', 1, 'Pull out one row or one column'],
    ['Build', 'kron(A, B)', 'kron()', 1, 'Kronecker product', 'tensor'],
    ['Cofactors', 'minors(A)', 'minors()', 1, 'Matrix of minors'],
    ['Cofactors', 'cof(A)', 'cof()', 1, 'Cofactor matrix', 'cofactor'],
    ['Cofactors', 'adj(A)', 'adj()', 1, 'Adjugate (classical adjoint)', 'adjoint adjugate'],
    ['Systems', 'rref(A)', 'rref()', 1, 'Reduced row echelon form — with steps in Inspect', 'echelon gauss jordan'],
    ['Systems', 'solve(A, b)', 'solve()', 1, 'Solve Ax = b, including systems with free variables', 'equation linear system'],
    ['Systems', 'null(A)', 'null()', 1, 'Basis for the null space (kernel)', 'kernel nullspace'],
    ['Systems', 'colsp(A)', 'colsp()', 1, 'Basis for the column space (range)', 'range column space'],
    ['Systems', 'pinv(A)', 'pinv()', 1, 'Moore–Penrose pseudo-inverse', 'pseudo inverse least squares'],
    ['Systems', 'dot(u, v),  cross(u, v)', 'dot()', 1, 'Dot product; cross product of 3-vectors', 'vector'],
    ['Decompose', 'lu(A)', 'lu()', 1, 'PA = LU with partial pivoting', 'lu decomposition factorization'],
    ['Decompose', 'qr(A)', 'qr()', 1, 'A = QR, Q orthogonal and R upper triangular', 'qr decomposition'],
    ['Decompose', 'chol(A)', 'chol()', 1, 'A = LLᵀ for symmetric positive definite A', 'cholesky'],
    ['Decompose', 'svd(A)', 'svd()', 1, 'A = UΣVᵀ, singular value decomposition', 'singular'],
    ['Eigen', 'eig(A)', 'eig()', 1, 'Eigenvalues, including complex ones', 'eigenvalue spectrum'],
    ['Eigen', 'eigvec(A)', 'eigvec()', 1, 'Eigenvectors grouped by eigenvalue', 'eigenvector'],
    ['Eigen', 'charpoly(A)', 'charpoly()', 1, 'Characteristic polynomial det(λI − A)', 'characteristic polynomial'],
    ['Matrix functions', 'expm(A)', 'expm()', 1, 'Matrix exponential eᴬ', 'exponential'],
    ['Matrix functions', 'sinm(A),  cosm(A)', 'sinm()', 1, 'Matrix sine and cosine', 'trig'],
    ['Matrix functions', 'sqrtm(A)  or  A^0.5', 'sqrtm()', 1, 'Principal matrix square root', 'root'],
    ['Trig & scalar', 'sin, cos, tan', 'sin()', 1, 'On a matrix, these apply to every entry', 'trigonometry'],
    ['Trig & scalar', 'sec, csc, cot', 'sec()', 1, 'Reciprocal trig functions', 'trigonometry'],
    ['Trig & scalar', 'asin, acos, atan', 'asin()', 1, 'Inverse trig — answers follow the RAD/DEG setting', 'arcsin arccos arctan inverse trigonometry'],
    ['Trig & scalar', 'sinh, cosh, tanh', 'sinh()', 1, 'Hyperbolic functions', 'hyperbolic'],
    ['Trig & scalar', 'sin(30°)', '°', 0, 'Mark any angle in degrees, whatever the setting', 'degree angle'],
    ['Trig & scalar', 'ln, log, exp', 'ln()', 1, 'Natural log, log base 10, eˣ', 'logarithm'],
    ['Trig & scalar', '√x,  ∛x,  n!', '√', 0, 'Roots and factorial', 'sqrt root factorial'],
    ['Trig & scalar', 'abs, round, floor, ceil, mod', 'abs()', 1, 'Rounding and remainders', 'absolute modulo'],
  ].map(([g, s, ins, back, d, kw]) => ({ g, s, ins, back, d, kw: kw || '' }));
  const LIB_GROUPS = ['All', ...new Set(LIB.map((x) => x.g))];
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
    const items = LIB.map((x, i) => Object.assign({ i }, x)).filter((x) => (ui.libGroup === 'All' || x.g === ui.libGroup)
      && tokens.every((t) => `${x.s} ${x.d} ${x.kw} ${x.g}`.toLowerCase().includes(t)));
    if (!items.length) {
      list.innerHTML = `<div class="empty">${icon('search')}<span class="empty-title">No operations match “${esc(ui.libQuery)}”</span><p>Try a shorter word like “inv”, “eig” or “trig”, or clear the filter.</p><button type="button" class="btn btn--fit" data-act="lib-clear">Clear search</button></div>`;
      return;
    }
    const groups = [...new Set(items.map((x) => x.g))];
    list.innerHTML = groups.map((g) => `<section class="group"><h2 class="group-title">${esc(g)}</h2><ul class="list card">${items.filter((x) => x.g === g).map((x) => `<li><button type="button" class="lib-row" data-act="lib-insert" data-i="${x.i}"><span class="lib-syn">${esc(x.s)}</span><span class="lib-desc">${esc(x.d)}</span></button></li>`).join('')}</ul></section>`).join('');
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
    return { title: `${p.auto ? 'Inspector · ' : ''}Line ${idx + 1}${label}`, value: E.isMat(v) ? v : null, error: E.isMat(v) ? '' : 'This line no longer gives a matrix.' };
  }
  function renderInspector() {
    const t = inspectTarget();
    if (t.none) return `${subHead('Inspector')}<div class="od-scroll sub-scroll"><div class="empty">${icon('eye')}<span class="empty-title">Nothing to inspect yet</span><p>Write an expression that gives a matrix, or create a matrix. Its properties, eigenvalues and steps appear here.</p></div></div>`;
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
      </div>`;
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
          <p class="help-p">Tap Inspect on any matrix result for its properties, eigenvalues, norms, step-by-step row reduction and decompositions.</p>
        </section>
        <section class="group"><h2 class="group-title">Try these</h2>
          <ul class="list card">${tries.map(([t, c]) => `<li><button type="button" class="try" data-act="try" data-ins="${esc(t)}"><span class="od-field" style="flex:1 1 0"><code>${esc(t)}</code><span class="row-sub">${esc(c)}</span></span><span class="try-cap">Add</span></button></li>`).join('')}</ul>
        </section>
        <section class="group"><h2 class="group-title">Keyboard shortcuts</h2>
          <div class="card card-pad"><p class="help-p" style="margin:0">On a hardware keyboard you can type directly: * for ·, ' for transpose, ^-1 for the inverse. Enter adds a line, Backspace on an empty line removes it, ↑ and ↓ move between lines.</p></div>
        </section>
      </div>`;
  }

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
      case 'back': closeScreen(); break;
      case 'close-layer': closeLayer(); break;
      case 'new-matrix': newMatrix(t); break;
      case 'edit-matrix': openEditor(t.dataset.id, t); break;
      case 'add-line': { const l = addLine(ws().lines.length ? ws().lines[ws().lines.length - 1].id : null); focusLine(l.id); break; }
      case 'delete-line': deleteLine(t.dataset.line); break;
      case 'inspect-line': openScreen('inspect', { kind: 'line', id: t.dataset.line }, t); break;
      case 'inspect-part': openScreen('inspect', { kind: 'line', id: t.dataset.line, part: +t.dataset.part }, t); break;
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
      case 'lib-insert': { const x = LIB[+t.dataset.i]; insertFromOutside(x.ins, x.back); break; }
      /* inspector */
      case 'insp-step': ui.inspStep = t.dataset.k; $$('[data-act="insp-step"]', host()).forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.k === ui.inspStep))); $('#inspSteps', host()).innerHTML = stepsHTML(ui.inspStep, inspectTarget().value); break;
      case 'insp-dec': ui.inspDec = t.dataset.k; $$('[data-act="insp-dec"]', host()).forEach((b) => b.setAttribute('aria-pressed', String(b.dataset.k === ui.inspDec))); $('#inspDec', host()).innerHTML = decompHTML(ui.inspDec, inspectTarget().value); break;
      case 'insp-save': { const v = inspectTarget().value; if (v) saveValueAsMatrix(v); break; }
      case 'insp-copy': { const v = inspectTarget().value; if (v) copyText(matText(v)); break; }
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
    const w = appEl.clientWidth;
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
      if (l === 'tabletop') ui.kpCollapsed = false;
      if (hasDetail(l)) renderDetail(false);
      if (l === 'glance') renderGlance();
    }
    const xl = l === 'expanded' && wsScreen.clientWidth >= 700;
    if (changed || xl !== !!ui.xl) { ui.xl = xl; renderKeypad(); }
  }
  ui.layout = null;
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
    } else if (demo === 'editor') {
      openEditor(m.id, null);
    } else if (['library', 'settings', 'history', 'workspaces', 'help'].includes(demo)) {
      openScreen(demo, {});
    }
    if (document.activeElement && document.activeElement !== document.body) document.activeElement.blur();
  })();
  if (window.ResizeObserver) new ResizeObserver(() => applyLayout()).observe(appEl);
  else window.addEventListener('resize', applyLayout);

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
