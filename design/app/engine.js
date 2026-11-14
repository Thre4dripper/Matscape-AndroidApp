/* Matscape 2 — math engine (prototype).
   Real-valued matrices, scalar math, trig, decompositions, eigen-analysis
   step-by-step row reduction, and full step-by-step solutions of whole
   expressions (explain). Complex numbers appear only as outputs
   (eigenvalues). Exposed as window.MatEngine. */
(function (global) {
  'use strict';

  class MathError extends Error {
    constructor(message, hint) { super(message); this.hint = hint || ''; }
  }
  class UnknownName extends MathError {
    constructor(name) {
      const single = /^[A-Z]$/.test(name);
      super(`Unknown name “${name}”`, single
        ? `Create matrix ${name} with the + button, or define it in a line like ${name} = [1, 2; 3, 4].`
        : `Define it first in its own line, like ${name} = 2.`);
      this.unknown = name;
    }
  }

  /* ---------- matrix basics ---------- */
  const mat = (data) => ({ type: 'matrix', rows: data.length, cols: data[0].length, data });
  const zeros = (r, c) => mat(Array.from({ length: r }, () => new Array(c).fill(0)));
  const eye = (n) => { const I = zeros(n, n); for (let i = 0; i < n; i++) I.data[i][i] = 1; return I; };
  const copyData = (A) => A.data.map((r) => r.slice());
  const isMat = (v) => !!v && v.type === 'matrix';
  const isNum = (v) => typeof v === 'number';
  const isEye = (v) => !!v && v.type === 'eye';
  const dims = (A) => `${A.rows}×${A.cols}`;
  const desc = (A) => (A.label ? `${A.label} (${dims(A)})` : `a ${dims(A)} matrix`);
  const mapM = (A, f) => mat(A.data.map((r, i) => r.map((x, j) => f(x, i, j))));
  const transpose = (A) => { const R = zeros(A.cols, A.rows); for (let i = 0; i < A.rows; i++) for (let j = 0; j < A.cols; j++) R.data[j][i] = A.data[i][j]; return R; };
  const addM = (A, B, s = 1) => mapM(A, (x, i, j) => x + s * B.data[i][j]);
  const scaleM = (A, k) => mapM(A, (x) => x * k);
  const mulM = (A, B) => {
    const R = zeros(A.rows, B.cols);
    for (let i = 0; i < A.rows; i++) for (let k = 0; k < A.cols; k++) {
      const a = A.data[i][k]; if (a === 0) continue;
      for (let j = 0; j < B.cols; j++) R.data[i][j] += a * B.data[k][j];
    }
    return R;
  };
  const traceOf = (A) => { let s = 0; for (let i = 0; i < Math.min(A.rows, A.cols); i++) s += A.data[i][i]; return s; };
  const maxAbs = (A) => A.data.reduce((m, r) => r.reduce((mm, x) => Math.max(mm, Math.abs(x)), m), 0);
  const tolFor = (A, k = 1e-10) => k * Math.max(1, maxAbs(A));
  const cleanNum = (x, s = 1) => (Math.abs(x) < 1e-11 * Math.max(1, s) ? 0 : x);
  const cleanM = (A) => { const s = maxAbs(A); return mapM(A, (x) => cleanNum(x, s)); };
  const approxEq = (A, B, t) => A.rows === B.rows && A.cols === B.cols && A.data.every((r, i) => r.every((x, j) => Math.abs(x - B.data[i][j]) <= t));
  const col = (A, j) => A.data.map((r) => r[j]);
  const fromCols = (cols) => mat(cols[0].map((_, i) => cols.map((c) => c[i])));
  const vnorm = (v) => Math.sqrt(v.reduce((s, x) => s + x * x, 0));

  function needSquare(A, what) {
    if (A.rows !== A.cols) throw new MathError(`${what} needs a square matrix`, `${A.label || 'This matrix'} is ${dims(A)}.`);
  }
  function asMat(v, fname) {
    if (isNum(v)) return mat([[v]]);
    if (isMat(v)) return v;
    if (isEye(v)) throw new MathError('I needs a size here', 'Write I(3) for the 3×3 identity.');
    throw new MathError(`${fname}(…) needs a matrix`);
  }
  function asNum(v, fname) {
    if (isNum(v)) return v;
    if (isMat(v) && v.rows === 1 && v.cols === 1) return v.data[0][0];
    throw new MathError(`${fname} needs a number here`, isMat(v) ? `Got ${desc(v)}.` : '');
  }
  function asInt(v, fname, min = 1) {
    const n = asNum(v, fname);
    if (!Number.isInteger(Math.round(n)) || Math.abs(n - Math.round(n)) > 1e-9 || Math.round(n) < min) throw new MathError(`${fname} needs a whole number${min > 0 ? ' of at least ' + min : ''}`);
    return Math.round(n);
  }

  /* ---------- number description (exact display) ---------- */
  function fraction(x, maxDen) {
    let h1 = 1, h0 = 0, k1 = 0, k0 = 1, b = x;
    const ok = () => k1 > 0 && Math.abs(x - h1 / k1) < 1e-9 * Math.max(1, Math.abs(x));
    for (let i = 0; i < 24; i++) {
      const a = Math.floor(b);
      const h2 = a * h1 + h0, k2 = a * k1 + k0;
      if (k2 > maxDen) break;
      h0 = h1; h1 = h2; k0 = k1; k1 = k2;
      if (ok()) return [h1, k1];
      const fr = b - a; if (fr < 1e-12) break;
      b = 1 / fr;
    }
    return ok() ? [h1, k1] : null;
  }
  function decimalText(ax, p) {
    if (ax !== 0 && (ax >= 1e9 || ax < 1e-4)) {
      const [m, e] = ax.toExponential(Math.max(1, p - 1)).split('e');
      return { mant: String(parseFloat(m)), exp: parseInt(e, 10) };
    }
    return { text: String(parseFloat(ax.toFixed(p))) };
  }
  function describe(x, mode = 'exact', precision = 4) {
    if (!isFinite(x)) return { kind: 'special', text: isNaN(x) ? 'undefined' : x > 0 ? '∞' : '−∞' };
    if (Math.abs(x) < 1e-11) x = 0;
    const neg = x < 0, ax = Math.abs(x);
    if (mode === 'exact') {
      const r = Math.round(ax);
      if (Math.abs(ax - r) < 1e-9 * Math.max(1, ax)) return { kind: 'int', neg: neg && r !== 0, n: r };
      if (ax < 1e7) {
        const f = fraction(ax, 200); if (f) return { kind: 'frac', neg, n: f[0], d: f[1] };
        for (const k of [2, 3, 5, 6, 7, 10]) {
          const s = fraction(ax / Math.sqrt(k), 60);
          if (s && s[0] <= 60) return { kind: 'surd', neg, n: s[0], d: s[1], k };
        }
        const fp = fraction(ax / Math.PI, 12);
        if (fp && fp[0] <= 24) return { kind: 'pi', neg, n: fp[0], d: fp[1] };
      }
    }
    const d = decimalText(ax, precision);
    if (d.text === '0') return { kind: 'int', neg: false, n: 0 };
    return Object.assign({ kind: 'dec', neg }, d);
  }
  function plain(x, mode = 'exact', precision = 4) {
    const d = describe(x, mode, precision);
    const s = d.neg ? '−' : '';
    switch (d.kind) {
      case 'special': return d.text;
      case 'int': return s + d.n;
      case 'frac': return `${s}${d.n}/${d.d}`;
      case 'surd': return `${s}${d.n === 1 ? '' : d.n}√${d.k}${d.d === 1 ? '' : '/' + d.d}`;
      case 'pi': return `${s}${d.n === 1 ? '' : d.n}π${d.d === 1 ? '' : '/' + d.d}`;
      default: return s + (d.text != null ? d.text : `${d.mant}×10^${d.exp}`);
    }
  }
  const coefTxt = (f) => (Math.abs(f - 1) < 1e-12 ? '' : (/[/√π]/.test(plain(f)) ? `(${plain(f)})` : plain(f)));
  const divTxt = (f) => { const p = plain(f); return f < 0 || /[/√π]/.test(p) ? `(${p})` : p; };

  /* ---------- core linear algebra ---------- */
  function lu(A) {
    needSquare(A, 'LU decomposition');
    const n = A.rows, U = copyData(A), L = eye(n).data, perm = [...Array(n).keys()];
    const tol = tolFor(A, 1e-12); let swaps = 0, singular = false;
    for (let k = 0; k < n; k++) {
      let p = k; for (let i = k + 1; i < n; i++) if (Math.abs(U[i][k]) > Math.abs(U[p][k])) p = i;
      if (Math.abs(U[p][k]) <= tol) { singular = true; for (let i = k; i < n; i++) U[i][k] = 0; continue; }
      if (p !== k) {
        [U[p], U[k]] = [U[k], U[p]]; [perm[p], perm[k]] = [perm[k], perm[p]];
        for (let j = 0; j < k; j++) { const t = L[p][j]; L[p][j] = L[k][j]; L[k][j] = t; }
        swaps++;
      }
      for (let i = k + 1; i < n; i++) {
        const f = U[i][k] / U[k][k]; L[i][k] = f; U[i][k] = 0;
        for (let j = k + 1; j < n; j++) U[i][j] -= f * U[k][j];
      }
    }
    const P = zeros(n, n); perm.forEach((pi, i) => { P.data[i][pi] = 1; });
    return { L: mat(L), U: mat(U), P, swaps, singular };
  }
  function det(A) {
    needSquare(A, 'The determinant');
    const n = A.rows, a = A.data;
    if (n === 1) return a[0][0];
    if (n === 2) return a[0][0] * a[1][1] - a[0][1] * a[1][0];
    const { U, swaps, singular } = lu(A);
    if (singular) return 0;
    let d = swaps % 2 ? -1 : 1; for (let i = 0; i < n; i++) d *= U.data[i][i];
    return d;
  }
  function inverse(A) {
    needSquare(A, 'The inverse');
    const n = A.rows, I = eye(n).data, M = A.data.map((r, i) => [...r, ...I[i]]), tol = tolFor(A);
    for (let c = 0; c < n; c++) {
      let p = c; for (let i = c + 1; i < n; i++) if (Math.abs(M[i][c]) > Math.abs(M[p][c])) p = i;
      if (Math.abs(M[p][c]) <= tol) throw new MathError(`${A.label || 'This matrix'} is singular, so it has no inverse`, `Its determinant is 0. Try pinv(${A.label || 'A'}) for the pseudo-inverse.`);
      [M[p], M[c]] = [M[c], M[p]];
      const pv = M[c][c]; for (let j = 0; j < 2 * n; j++) M[c][j] /= pv;
      for (let i = 0; i < n; i++) if (i !== c) { const f = M[i][c]; if (f) for (let j = 0; j < 2 * n; j++) M[i][j] -= f * M[c][j]; }
    }
    return mat(M.map((r) => r.slice(n)));
  }
  function rrefCore(A, opts = {}) {
    const R = copyData(A), m = A.rows, n = A.cols, lim = opts.augAt != null ? opts.augAt : n;
    const tol = opts.tol != null ? opts.tol : tolFor(A, 1e-10);
    const hand = !!opts.hand, upperOnly = !!opts.upperOnly;
    const steps = [], pivots = []; let r = 0, swaps = 0;
    const snap = () => mat(R.map((row) => row.map((x) => (Math.abs(x) <= tol ? 0 : x))));
    for (let c = 0; c < lim && r < m; c++) {
      let p = r;
      if (hand) { while (p < m && Math.abs(R[p][c]) <= tol) p++; if (p === m) p = r; }
      else for (let i = r + 1; i < m; i++) if (Math.abs(R[i][c]) > Math.abs(R[p][c])) p = i;
      if (Math.abs(R[p][c]) <= tol) { for (let i = r; i < m; i++) R[i][c] = 0; continue; }
      if (p !== r) { [R[p], R[r]] = [R[r], R[p]]; swaps++; steps.push({ ops: [`R${r + 1} ↔ R${p + 1}`], m: snap() }); }
      if (!upperOnly) {
        const pv = R[r][c];
        if (Math.abs(pv - 1) > tol) {
          for (let j = 0; j < n; j++) R[r][j] /= pv; R[r][c] = 1;
          steps.push({ ops: [`R${r + 1} → R${r + 1} ÷ ${divTxt(pv)}`], m: snap() });
        }
      }
      const ops = [];
      for (let i = upperOnly ? r + 1 : 0; i < m; i++) {
        if (i === r) continue;
        const f = R[i][c] / R[r][c];
        if (Math.abs(R[i][c]) <= tol) { R[i][c] = 0; continue; }
        for (let j = 0; j < n; j++) R[i][j] -= f * R[r][j];
        R[i][c] = 0;
        ops.push(f > 0 ? `R${i + 1} → R${i + 1} − ${coefTxt(f)}R${r + 1}` : `R${i + 1} → R${i + 1} + ${coefTxt(-f)}R${r + 1}`);
      }
      if (ops.length) steps.push({ ops, m: snap() });
      pivots.push(c); r++;
    }
    return { R: snap(), pivots, steps, swaps };
  }
  const rref = (A) => rrefCore(A).R;
  const rank = (A) => rrefCore(A).pivots.length;
  function nullspace(A, tol) {
    const { R, pivots } = rrefCore(A, tol != null ? { tol } : {});
    const free = [...Array(A.cols).keys()].filter((c) => !pivots.includes(c));
    if (!free.length) return null;
    const B = zeros(A.cols, free.length);
    free.forEach((f, k) => { B.data[f][k] = 1; pivots.forEach((pc, row) => { B.data[pc][k] = -R.data[row][f]; }); });
    return B;
  }
  function colspace(A) {
    const { pivots } = rrefCore(A);
    if (!pivots.length) return null;
    return fromCols(pivots.map((j) => col(A, j)));
  }
  function minorOf(A, r, c) {
    const rows = A.data.filter((_, i) => i !== r).map((row) => row.filter((_, j) => j !== c));
    return rows.length ? det(mat(rows)) : 1;
  }
  function minorsM(A) { needSquare(A, 'The minor matrix'); if (A.rows < 2) throw new MathError('Minors need at least a 2×2 matrix'); return mapM(A, (_, i, j) => minorOf(A, i, j)); }
  function cofactorM(A) { needSquare(A, 'The cofactor matrix'); if (A.rows < 2) throw new MathError('Cofactors need at least a 2×2 matrix'); return mapM(A, (_, i, j) => ((i + j) % 2 ? -1 : 1) * minorOf(A, i, j)); }
  function adjugate(A) { needSquare(A, 'The adjugate'); if (A.rows === 1) return mat([[1]]); return transpose(cofactorM(A)); }

  function qr(A) {
    const m = A.rows, n = A.cols, R = copyData(A), Q = eye(m).data;
    for (let k = 0; k < Math.min(m - 1, n); k++) {
      const x = []; for (let i = k; i < m; i++) x.push(R[i][k]);
      const nx = vnorm(x); if (nx < 1e-14) continue;
      const alpha = -(x[0] >= 0 ? 1 : -1) * nx;
      const v = x.slice(); v[0] -= alpha; const nv = vnorm(v); if (nv < 1e-14) continue;
      for (let i = 0; i < v.length; i++) v[i] /= nv;
      for (let j = 0; j < n; j++) { let s = 0; for (let i = 0; i < v.length; i++) s += v[i] * R[k + i][j]; for (let i = 0; i < v.length; i++) R[k + i][j] -= 2 * v[i] * s; }
      for (let i = 0; i < m; i++) { let s = 0; for (let t = 0; t < v.length; t++) s += Q[i][k + t] * v[t]; for (let t = 0; t < v.length; t++) Q[i][k + t] -= 2 * s * v[t]; }
    }
    for (let k = 0; k < Math.min(m, n); k++) if (R[k][k] < 0) { for (let j = 0; j < n; j++) R[k][j] = -R[k][j]; for (let i = 0; i < m; i++) Q[i][k] = -Q[i][k]; }
    for (let i = 0; i < m; i++) for (let j = 0; j < Math.min(i, n); j++) R[i][j] = 0;
    return { Q: cleanM(mat(Q)), R: cleanM(mat(R)) };
  }
  const isSymmetric = (A) => A.rows === A.cols && approxEq(A, transpose(A), tolFor(A, 1e-9));
  function cholesky(A) {
    needSquare(A, 'Cholesky');
    if (!isSymmetric(A)) throw new MathError('Cholesky needs a symmetric matrix', `${A.label || 'This matrix'} isn’t symmetric. Try lu(…) or qr(…) instead.`);
    const n = A.rows, L = zeros(n, n).data, tol = tolFor(A, 1e-12);
    for (let i = 0; i < n; i++) for (let j = 0; j <= i; j++) {
      let s = A.data[i][j]; for (let k = 0; k < j; k++) s -= L[i][k] * L[j][k];
      if (i === j) { if (s <= tol) throw new MathError('Cholesky needs a positive definite matrix', 'At least one eigenvalue is zero or negative.'); L[i][i] = Math.sqrt(s); }
      else L[i][j] = s / L[j][j];
    }
    return mat(L);
  }

  /* symmetric eigen (Jacobi) */
  function jacobi(S) {
    const n = S.rows, A = copyData(S), V = eye(n).data;
    for (let sweep = 0; sweep < 100; sweep++) {
      let off = 0; for (let p = 0; p < n; p++) for (let q = p + 1; q < n; q++) off += A[p][q] * A[p][q];
      if (off < 1e-26) break;
      for (let p = 0; p < n; p++) for (let q = p + 1; q < n; q++) {
        if (Math.abs(A[p][q]) < 1e-300) continue;
        const theta = (A[q][q] - A[p][p]) / (2 * A[p][q]);
        const t = (theta >= 0 ? 1 : -1) / (Math.abs(theta) + Math.sqrt(theta * theta + 1));
        const c = 1 / Math.sqrt(t * t + 1), s = t * c;
        for (let k = 0; k < n; k++) { const a = A[k][p], b = A[k][q]; A[k][p] = c * a - s * b; A[k][q] = s * a + c * b; }
        for (let k = 0; k < n; k++) { const a = A[p][k], b = A[q][k]; A[p][k] = c * a - s * b; A[q][k] = s * a + c * b; }
        for (let k = 0; k < n; k++) { const a = V[k][p], b = V[k][q]; V[k][p] = c * a - s * b; V[k][q] = s * a + c * b; }
      }
    }
    const order = [...Array(n).keys()].sort((a, b) => A[b][b] - A[a][a]);
    const values = order.map((i) => A[i][i]);
    const vecs = order.map((i) => {
      const v = V.map((r) => r[i]);
      let big = 0; v.forEach((x, k) => { if (Math.abs(x) > Math.abs(v[big]) + 1e-12) big = k; });
      return v[big] < 0 ? v.map((x) => -x) : v;
    });
    return { values, vectors: fromCols(vecs) };
  }

  /* characteristic polynomial (Faddeev–LeVerrier): [1, c_{n-1}, …, c_0] */
  function charpoly(A) {
    needSquare(A, 'The characteristic polynomial');
    const n = A.rows, I = eye(n), coeffs = [1]; let Mk = zeros(n, n), cPrev = 1;
    for (let k = 1; k <= n; k++) { Mk = addM(mulM(A, Mk), scaleM(I, cPrev)); cPrev = -traceOf(mulM(A, Mk)) / k; coeffs.push(cPrev); }
    return coeffs;
  }
  /* complex helpers */
  const C = (re, im = 0) => ({ re, im });
  const cadd = (a, b) => C(a.re + b.re, a.im + b.im);
  const csub = (a, b) => C(a.re - b.re, a.im - b.im);
  const cmul = (a, b) => C(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re);
  const cdiv = (a, b) => { const d = b.re * b.re + b.im * b.im || 1e-300; return C((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d); };
  const cabs = (a) => Math.hypot(a.re, a.im);
  const polyEval = (cf, z) => cf.reduce((acc, c) => cadd(cmul(acc, z), C(c)), C(0));
  function polyRoots(cf) {
    const n = cf.length - 1; if (n < 1) return [];
    const bound = 1 + Math.max(...cf.slice(1).map(Math.abs));
    let z = C(1); const seed = C(0.4, 0.9), roots = [];
    for (let k = 0; k < n; k++) { roots.push(C(z.re * bound * 0.5, z.im * bound * 0.5)); z = cmul(z, seed); }
    for (let it = 0; it < 2000; it++) {
      let maxD = 0;
      for (let i = 0; i < n; i++) {
        let den = C(1); for (let j = 0; j < n; j++) if (j !== i) den = cmul(den, csub(roots[i], roots[j]));
        const d = cdiv(polyEval(cf, roots[i]), den); roots[i] = csub(roots[i], d); maxD = Math.max(maxD, cabs(d));
      }
      if (maxD < 1e-15 * bound) break;
    }
    const scale = Math.max(1, ...cf.map(Math.abs));
    return roots.map((r) => {
      if (Math.abs(r.im) < 1e-7 * (1 + Math.abs(r.re))) r = C(r.re, 0);
      const snapTo = (x) => { const f = fraction(Math.abs(x), 12); return f ? Math.sign(x) * f[0] / f[1] : null; };
      const re = snapTo(r.re), im = r.im ? snapTo(r.im) : 0;
      if (re != null && im != null && Math.abs(re - r.re) < 1e-6 && Math.abs(im - r.im) < 1e-6 && cabs(polyEval(cf, C(re, im))) < 1e-8 * scale) return C(re, im);
      return r;
    });
  }
  function isTriangular(A) {
    const t = tolFor(A, 1e-12); let up = true, low = true;
    for (let i = 0; i < A.rows; i++) for (let j = 0; j < A.cols; j++) { if (i > j && Math.abs(A.data[i][j]) > t) up = false; if (i < j && Math.abs(A.data[i][j]) > t) low = false; }
    return { up, low };
  }
  function eigenvalues(A) {
    needSquare(A, 'Eigenvalues');
    if (isSymmetric(A)) return jacobi(A).values.map((x) => cleanNum(x, maxAbs(A)));
    const tri = isTriangular(A);
    if (tri.up || tri.low) return A.data.map((r, i) => r[i]).sort((a, b) => b - a);
    const roots = polyRoots(charpoly(A));
    roots.sort((a, b) => (Math.abs(a.im) > 0) - (Math.abs(b.im) > 0) || b.re - a.re || b.im - a.im);
    return roots.map((r) => (r.im === 0 ? r.re : { type: 'complex', re: r.re, im: r.im }));
  }
  function gaussSolve(A, b) {
    const n = A.rows, M = A.data.map((r, i) => [...r, b[i]]);
    for (let c = 0; c < n; c++) {
      let p = c; for (let i = c + 1; i < n; i++) if (Math.abs(M[i][c]) > Math.abs(M[p][c])) p = i;
      [M[p], M[c]] = [M[c], M[p]]; if (Math.abs(M[c][c]) < 1e-300) M[c][c] = 1e-300;
      for (let i = c + 1; i < n; i++) { const f = M[i][c] / M[c][c]; for (let j = c; j <= n; j++) M[i][j] -= f * M[c][j]; }
    }
    const x = new Array(n).fill(0);
    for (let i = n - 1; i >= 0; i--) { let s = M[i][n]; for (let j = i + 1; j < n; j++) s -= M[i][j] * x[j]; x[i] = s / M[i][i]; }
    return x;
  }
  function eigenvectors(A) {
    needSquare(A, 'Eigenvectors');
    const scale = Math.max(1, maxAbs(A)), n = A.rows, parts = [], notes = [];
    if (isSymmetric(A)) {
      const { values, vectors } = jacobi(A); const groups = [];
      values.forEach((v, i) => { const g = groups.find((gr) => Math.abs(gr.l - v) < 1e-8 * scale); if (g) g.idx.push(i); else groups.push({ l: v, idx: [i] }); });
      groups.forEach((g) => parts.push({ label: `λ = ${plain(cleanNum(g.l, scale))}`, value: cleanM(fromCols(g.idx.map((i) => col(vectors, i)))) }));
      return { parts, notes: ['Unit-length eigenvectors (A is symmetric, so they’re orthogonal).'] };
    }
    const vals = eigenvalues(A), seen = [];
    let complexCount = 0;
    vals.forEach((l) => {
      if (!isNum(l)) { complexCount++; return; }
      if (seen.some((s) => Math.abs(s - l) < 1e-7 * scale)) return; seen.push(l);
      const Ash = addM(A, eye(n), -l);
      let N = nullspace(Ash, 1e-7 * scale);
      if (!N) {
        let x = new Array(n).fill(1); const Bm = addM(Ash, eye(n), -1e-9 * scale);
        for (let k = 0; k < 30; k++) { x = gaussSolve(Bm, x); const nx = vnorm(x) || 1; x = x.map((v) => v / nx); }
        N = fromCols([x]);
      }
      parts.push({ label: `λ = ${plain(l)}`, value: cleanM(N) });
    });
    if (complexCount) notes.push(`${complexCount} complex eigenvalue${complexCount > 1 ? 's' : ''} — their eigenvectors are complex and aren’t shown.`);
    if (!parts.length) throw new MathError('No real eigenvalues', 'All eigenvalues are complex. Use eig(…) to see them.');
    return { parts, notes };
  }
  function svd(A) {
    const m = A.rows, n = A.cols, { values, vectors } = jacobi(mulM(transpose(A), A)), r = Math.min(m, n);
    const sig = values.slice(0, r).map((v) => Math.sqrt(Math.max(v, 0)));
    const tol = 1e-10 * Math.max(1, sig[0] || 0);
    const Vc = [...Array(r).keys()].map((k) => col(vectors, k));
    const Uc = new Array(r).fill(null);
    for (let k = 0; k < r; k++) if (sig[k] > tol) { const u = mulM(A, fromCols([Vc[k]])).data.map((x) => x[0] / sig[k]); Uc[k] = u; }
    for (let k = 0; k < r; k++) {
      if (Uc[k]) continue;
      for (let e = 0; e < m; e++) {
        let v = new Array(m).fill(0); v[e] = 1;
        Uc.forEach((u) => { if (!u) return; const d = u.reduce((s, x, i) => s + x * v[i], 0); v = v.map((x, i) => x - d * u[i]); });
        const nv = vnorm(v); if (nv > 1e-6) { Uc[k] = v.map((x) => x / nv); break; }
      }
    }
    const S = zeros(r, r); sig.forEach((s, i) => { S.data[i][i] = s; });
    return { U: cleanM(fromCols(Uc)), S: cleanM(S), Vt: cleanM(transpose(fromCols(Vc))), sigma: sig };
  }
  function pinv(A) {
    const { U, S, Vt, sigma } = svd(A), tol = 1e-10 * Math.max(1, sigma[0] || 0);
    const Sp = mapM(S, (x, i, j) => (i === j && x > tol ? 1 / x : 0));
    return cleanM(mulM(mulM(transpose(Vt), Sp), transpose(U)));
  }
  const frob = (A) => Math.sqrt(A.data.reduce((s, r) => s + r.reduce((t, x) => t + x * x, 0), 0));
  const norm1 = (A) => Math.max(...[...Array(A.cols).keys()].map((j) => A.data.reduce((s, r) => s + Math.abs(r[j]), 0)));
  const normInf = (A) => Math.max(...A.data.map((r) => r.reduce((s, x) => s + Math.abs(x), 0)));
  const norm2 = (A) => svd(A).sigma[0] || 0;
  function cond(A) { const s = svd(A).sigma; const mn = s[s.length - 1]; return mn < 1e-12 * Math.max(1, s[0]) ? Infinity : s[0] / mn; }

  function matPow(A, k) {
    needSquare(A, 'Matrix powers');
    if (k < 0) { A = inverse(A); k = -k; }
    let R = eye(A.rows), B = A;
    while (k > 0) { if (k & 1) R = mulM(R, B); B = mulM(B, B); k >>= 1; }
    return R;
  }
  function expm(A) {
    needSquare(A, 'expm');
    const s = Math.max(0, Math.ceil(Math.log2(Math.max(normInf(A), 1e-16))) + 1);
    const X = scaleM(A, 1 / Math.pow(2, s)); let T = eye(A.rows), E = eye(A.rows);
    for (let k = 1; k <= 20; k++) { T = scaleM(mulM(T, X), 1 / k); E = addM(E, T); }
    for (let i = 0; i < s; i++) E = mulM(E, E);
    return E;
  }
  function sincosm(A) {
    needSquare(A, 'Matrix trig');
    const n = A.rows, I = eye(n), s = Math.max(0, Math.ceil(Math.log2(Math.max(normInf(A), 1e-16))) + 2);
    const X = scaleM(A, 1 / Math.pow(2, s)), X2 = mulM(X, X);
    let S = zeros(n, n), Cc = zeros(n, n), termS = X, termC = I;
    for (let k = 0; k < 14; k++) {
      S = addM(S, termS); Cc = addM(Cc, termC);
      termS = scaleM(mulM(termS, X2), -1 / ((2 * k + 2) * (2 * k + 3)));
      termC = scaleM(mulM(termC, X2), -1 / ((2 * k + 1) * (2 * k + 2)));
    }
    for (let i = 0; i < s; i++) { const S2 = scaleM(mulM(S, Cc), 2); Cc = addM(scaleM(mulM(Cc, Cc), 2), I, -1); S = S2; }
    return { sin: S, cos: Cc };
  }
  function sqrtm(A) {
    needSquare(A, 'sqrtm');
    let Y = A, Z = eye(A.rows);
    try {
      for (let k = 0; k < 60; k++) {
        const Yn = scaleM(addM(Y, inverse(Z)), 0.5), Zn = scaleM(addM(Z, inverse(Y)), 0.5);
        const diff = maxAbs(addM(Yn, Y, -1)); Y = Yn; Z = Zn; if (diff < 1e-13) break;
      }
    } catch (e) { throw new MathError('This matrix has no real square root', 'sqrtm needs a matrix with no zero or negative eigenvalues.'); }
    if (!approxEq(mulM(Y, Y), A, tolFor(A, 1e-6))) throw new MathError('This matrix has no real square root', 'sqrtm needs a matrix with no negative eigenvalues.');
    return Y;
  }
  function kron(A, B) {
    const R = zeros(A.rows * B.rows, A.cols * B.cols);
    for (let i = 0; i < A.rows; i++) for (let j = 0; j < A.cols; j++) for (let k = 0; k < B.rows; k++) for (let l = 0; l < B.cols; l++) R.data[i * B.rows + k][j * B.cols + l] = A.data[i][j] * B.data[k][l];
    return R;
  }
  const vecOf = (v, fname) => {
    const A = asMat(v, fname);
    if (A.rows !== 1 && A.cols !== 1) throw new MathError(`${fname}(…) needs vectors`, `${desc(A)} is not a single row or column.`);
    return A.rows === 1 ? A.data[0].slice() : A.data.map((r) => r[0]);
  };
  function solve(A, b, ctx) {
    if (A.rows !== b.rows) throw new MathError(`Can’t solve: ${desc(A)} and ${desc(b)} have different numbers of rows`);
    if (A.rows === A.cols && Math.abs(det(A)) > tolFor(A, 1e-10)) return mulM(inverse(A), b);
    const aug = mat(A.data.map((r, i) => [...r, ...b.data[i]]));
    const { R, pivots } = rrefCore(aug);
    if (pivots.some((p) => p >= A.cols)) throw new MathError('This system has no solution', 'The equations contradict each other. Try pinv(A)·b for a least-squares fit.');
    const X = zeros(A.cols, b.cols);
    pivots.forEach((pc, row) => { for (let j = 0; j < b.cols; j++) X.data[pc][j] = R.data[row][A.cols + j]; });
    ctx.warnings.push('Infinitely many solutions — showing the one with every free variable set to 0. Add null(A) for the rest.');
    return X;
  }

  /* properties for the inspector */
  function properties(A) {
    const sq = A.rows === A.cols, t = tolFor(A, 1e-9), out = [];
    const add = (key, label, value, note) => out.push({ key, label, value, note });
    add('square', 'Square', sq);
    if (!sq) return out;
    const T = transpose(A), I = eye(A.rows), A2 = mulM(A, A), tri = isTriangular(A);
    const sym = approxEq(A, T, t);
    let invertible = false; try { invertible = Math.abs(det(A)) > t; } catch (e) { /* noop */ }
    add('symmetric', 'Symmetric', sym);
    add('skew', 'Skew-symmetric', approxEq(A, scaleM(T, -1), t));
    add('diagonal', 'Diagonal', tri.up && tri.low);
    add('upper', 'Upper triangular', tri.up);
    add('lower', 'Lower triangular', tri.low);
    add('identity', 'Identity', approxEq(A, I, t));
    add('invertible', 'Invertible', invertible);
    add('orthogonal', 'Orthogonal', approxEq(mulM(T, A), I, 1e-9));
    add('idempotent', 'Idempotent', approxEq(A2, A, t));
    add('involutory', 'Involutory', approxEq(A2, I, t));
    add('nilpotent', 'Nilpotent', maxAbs(matPow(A, A.rows)) <= t * 10);
    let pd = false; if (sym) { try { pd = Math.min(...jacobi(A).values) > t; } catch (e) { /* noop */ } }
    add('posdef', 'Positive definite', pd);
    return out;
  }

  /* step-by-step */
  const steps = {
    rref(A) { const r = rrefCore(A, { hand: true }); return { start: A, steps: r.steps, result: r.R, summary: `Rank ${r.pivots.length}` }; },
    det(A) {
      needSquare(A, 'The determinant');
      const r = rrefCore(A, { hand: true, upperOnly: true });
      const n = A.rows, U = r.R, sign = r.swaps % 2 ? -1 : 1;
      let d = sign; const diag = []; for (let i = 0; i < n; i++) { d *= U.data[i][i]; diag.push(/[−/]/.test(plain(U.data[i][i])) ? `(${plain(U.data[i][i])})` : plain(U.data[i][i])); }
      const lead = r.swaps ? `${sign < 0 ? '−' : ''}` : '';
      const summary = `det = ${lead}${diag.join(' · ')} = ${plain(cleanNum(d))}`;
      const note = r.swaps ? `${r.swaps} row swap${r.swaps > 1 ? 's' : ''} flip the sign ${r.swaps % 2 ? 'once' : 'back'}. Adding multiples of rows doesn’t change det.` : 'Adding multiples of one row to another doesn’t change the determinant.';
      return { start: A, steps: r.steps, result: U, summary, note };
    },
    inverse(A) {
      needSquare(A, 'The inverse');
      const n = A.rows, aug = mat(A.data.map((row, i) => [...row, ...eye(n).data[i]]));
      const r = rrefCore(aug, { hand: true, augAt: n });
      const ok = r.pivots.length === n;
      return { start: aug, aug: n, steps: r.steps, result: r.R, summary: ok ? 'The right half is now the inverse.' : 'The left half can’t become I — this matrix is singular, so there’s no inverse.' };
    },
  };

  /* ---------- tokenizer & parser ---------- */
  const SUP = { 'ᵀ': 'T', '²': 'sq', '³': 'cube', '°': 'deg', '!': 'fact', "'": 'T' };
  function tokenize(src) {
    const toks = []; let i = 0;
    while (i < src.length) {
      const ch = src[i];
      if (/\s/.test(ch)) { i++; continue; }
      const num = /^(\d+\.?\d*|\.\d+)/.exec(src.slice(i));
      if (num) { i += num[0].length; if (src[i] === '.') throw new MathError('Check the decimal point', `“${num[0]}.” has more than one decimal point.`); toks.push({ t: 'num', v: parseFloat(num[0]) }); continue; }
      const id = /^([A-Za-z_][A-Za-z0-9_]*|[α-ωΑ-Ω])/.exec(src.slice(i));
      if (id && id[0] !== 'π') {
        // Runs of capitals are separate matrices multiplied together: BBᵀ = B·Bᵀ
        if (/^[A-Z]{2,}$/.test(id[0])) [...id[0]].forEach((c) => toks.push({ t: 'id', v: c }));
        else toks.push({ t: 'id', v: id[0] });
        i += id[0].length; continue;
      }
      if (src.startsWith('⁻¹', i)) { toks.push({ t: 'post', v: 'inv' }); i += 2; continue; }
      if (ch === 'π') { toks.push({ t: 'id', v: 'π' }); i++; continue; }
      if (SUP[ch]) { toks.push({ t: 'post', v: SUP[ch] }); i++; continue; }
      if ('+'.includes(ch)) { toks.push({ t: 'op', v: '+' }); i++; continue; }
      if ('-−–'.includes(ch)) { toks.push({ t: 'op', v: '-' }); i++; continue; }
      if ('*·×⋅'.includes(ch)) { toks.push({ t: 'op', v: '*' }); i++; continue; }
      if ('/÷'.includes(ch)) { toks.push({ t: 'op', v: '/' }); i++; continue; }
      if (ch === '^') { toks.push({ t: 'op', v: '^' }); i++; continue; }
      if (ch === '∘') { toks.push({ t: 'op', v: '∘' }); i++; continue; }
      if ('()[],;|√∛'.includes(ch)) { toks.push({ t: ch }); i++; continue; }
      if (ch === '=') throw new MathError('Use “=” only to name a value', 'Write it at the start, like k = 3 or M = A·B.');
      throw new MathError(`“${ch}” isn’t something Matscape understands`);
    }
    toks.push({ t: 'end' });
    return toks;
  }

  function parse(src, funcs, vars) {
    const toks = tokenize(src); let i = 0;
    const peek = () => toks[i], next = () => toks[i++];
    const expect = (t, msg) => { if (peek().t !== t) throw new MathError(msg || `Expected “${t}”`); return next(); };
    const startsFactor = (tk) => ['num', 'id', '(', '[', '√', '∛'].includes(tk.t);
    function expr() {
      let a = term();
      while (peek().t === 'op' && (peek().v === '+' || peek().v === '-')) { const op = next().v; a = { k: 'bin', op, a, b: term() }; }
      return a;
    }
    function term() {
      let a = unary();
      for (;;) {
        const tk = peek();
        if (tk.t === 'op' && (tk.v === '*' || tk.v === '/' || tk.v === '∘')) { next(); a = { k: 'bin', op: tk.v, a, b: unary() }; }
        else if (startsFactor(tk)) a = { k: 'bin', op: '*', a, b: power() };
        else return a;
      }
    }
    function unary() {
      const tk = peek();
      if (tk.t === 'op' && tk.v === '-') { next(); return { k: 'neg', a: unary() }; }
      if (tk.t === 'op' && tk.v === '+') { next(); return unary(); }
      return power();
    }
    function power() {
      const base = postfix();
      if (peek().t === 'op' && peek().v === '^') { next(); return { k: 'pow', a: base, b: unary() }; }
      return base;
    }
    function postfix() {
      let n = primary();
      while (peek().t === 'post') n = { k: 'post', op: next().v, a: n };
      return n;
    }
    function primary() {
      const tk = next();
      switch (tk.t) {
        case 'num': return { k: 'num', v: tk.v };
        case '(': { if (peek().t === ')') throw new MathError('Empty brackets', 'Put something between ( and ).'); const e = expr(); expect(')', 'A bracket is missing its “)”'); return e; }
        case '[': {
          const rows = [[]];
          if (peek().t === ']') throw new MathError('Empty matrix', 'Write entries like [1, 2; 3, 4].');
          for (;;) {
            rows[rows.length - 1].push(expr());
            const sep = next();
            if (sep.t === ',') continue;
            if (sep.t === ';') { rows.push([]); continue; }
            if (sep.t === ']') break;
            throw new MathError('Matrix brackets aren’t closed', 'Separate entries with “,”, rows with “;”, and finish with “]”.');
          }
          return { k: 'lit', rows };
        }
        case '|': { const e = expr(); expect('|', 'The closing “|” is missing'); return { k: 'bars', a: e }; }
        case '√': return { k: 'call', f: 'sqrt', args: [postfix()] };
        case '∛': return { k: 'call', f: 'cbrt', args: [postfix()] };
        case 'id': {
          const isVar = Object.prototype.hasOwnProperty.call(vars, tk.v);
          const f = !isVar && funcs[tk.v];
          if (f && (tk.v === 'I' || tk.v === 'eye') && peek().t !== '(') return { k: 'id', v: 'I' };
          if (f) {
            if (peek().t === '(') {
              next(); const args = [];
              if (peek().t !== ')') { for (;;) { args.push(expr()); if (peek().t === ',') { next(); continue; } break; } }
              expect(')', `${tk.v}( is missing its “)”`);
              return { k: 'call', f: tk.v, args };
            }
            if (f.min === 1) return { k: 'call', f: tk.v, args: [postfix()] };
            throw new MathError(`${tk.v} needs brackets`, `Write ${tk.v}(…)`);
          }
          return { k: 'id', v: tk.v };
        }
        case 'end': throw new MathError('This expression ends too early', 'Something is missing after the last operator.');
        case ')': throw new MathError('There’s an extra “)”');
        case ']': throw new MathError('There’s an extra “]”');
        case 'op': throw new MathError(`“${tk.v === '*' ? '×' : tk.v}” is missing something before it`);
        case 'post': throw new MathError('A power or transpose sign has nothing before it');
        default: throw new MathError(`Unexpected “${tk.t}”`);
      }
    }
    const tree = expr();
    if (peek().t !== 'end') {
      const t = peek();
      throw new MathError(t.t === ')' ? 'There’s an extra “)”' : t.t === ',' ? 'Commas only go inside function brackets or [ ]' : 'Something here doesn’t fit', '');
    }
    return tree;
  }

  /* ---------- evaluation ---------- */
  const elementwise = (v, f) => (isMat(v) ? mapM(v, f) : f(v));
  function arithAdd(a, b, sign) {
    const verb = sign > 0 ? 'add' : 'subtract';
    if (isNum(a) && isNum(b)) return a + sign * b;
    if (isMat(a) && isMat(b)) {
      if (a.rows !== b.rows || a.cols !== b.cols) throw new MathError(`Can’t ${verb} ${desc(a)} and ${desc(b)}`, 'Both matrices need the same size.');
      return addM(a, b, sign);
    }
    if (isMat(a) && isEye(b)) { needSquare(a, `Adding I`); return addM(a, scaleM(eye(a.rows), b.s), sign); }
    if (isEye(a) && isMat(b)) { needSquare(b, `Adding I`); return addM(scaleM(eye(b.rows), a.s), b, sign); }
    if (isEye(a) && isEye(b)) return { type: 'eye', s: a.s + sign * b.s };
    throw new MathError(`Can’t ${verb} a number and a matrix`, 'To shift the diagonal, use the identity: A − 2I.');
  }
  function arithMul(a, b) {
    if (isNum(a) && isNum(b)) return a * b;
    if (isNum(a) && isMat(b)) return scaleM(b, a);
    if (isMat(a) && isNum(b)) return scaleM(a, b);
    if (isMat(a) && isMat(b)) {
      if (a.cols !== b.rows) throw new MathError(`Can’t multiply ${desc(a)} by ${desc(b)}`, `The left matrix’s columns (${a.cols}) must match the right matrix’s rows (${b.rows}).`);
      return mulM(a, b);
    }
    if (isEye(a) && isEye(b)) return { type: 'eye', s: a.s * b.s };
    if (isEye(a)) return isNum(b) ? { type: 'eye', s: a.s * b } : scaleM(b, a.s);
    if (isEye(b)) return isNum(a) ? { type: 'eye', s: a * b.s } : scaleM(a, b.s);
    throw new MathError('Can’t multiply these');
  }
  function arithDiv(a, b, ctx) {
    if (isNum(b)) { if (b === 0) throw new MathError('Division by zero'); return isNum(a) ? a / b : isMat(a) ? scaleM(a, 1 / b) : { type: 'eye', s: a.s / b }; }
    if (isMat(b)) {
      const inv = inverse(b);
      if (isMat(a)) ctx.warnings.push(`Matrix division is worked out as ${a.label || 'left'}·${b.label || 'right'}⁻¹.`);
      return arithMul(a, inv);
    }
    throw new MathError('Can’t divide by I without a size');
  }
  function hadamard(a, b) {
    if (isMat(a) && isMat(b)) {
      if (a.rows !== b.rows || a.cols !== b.cols) throw new MathError(`The entrywise product needs equal sizes`, `${desc(a)} vs ${desc(b)}.`);
      return mapM(a, (x, i, j) => x * b.data[i][j]);
    }
    return arithMul(a, b);
  }
  function factorial(n) {
    if (n < 0 || Math.abs(n - Math.round(n)) > 1e-9) throw new MathError('Factorial needs a whole number ≥ 0');
    n = Math.round(n); if (n > 170) return Infinity; let r = 1; for (let k = 2; k <= n; k++) r *= k; return r;
  }

  function makeFuncs() {
    const F = {};
    const def = (names, min, max, fn) => names.split(' ').forEach((n) => { F[n] = { min, max, fn }; });
    const toRad = (x, ctx) => (ctx.angle === 'deg' ? (x * Math.PI) / 180 : x);
    const fromRad = (x, ctx) => (ctx.angle === 'deg' ? (x * 180) / Math.PI : x);
    const sc = (name, f, matHint) => def(name, 1, 1, ([v], ctx) => {
      if (isMat(v) && matHint) ctx.warnings.push(matHint);
      if (!isNum(v) && !isMat(v)) throw new MathError(`${name.split(' ')[0]} needs a number or matrix`);
      return elementwise(v, (x) => f(x, ctx));
    });
    const guard = (cond, msg) => { if (cond) throw new MathError(msg); };
    sc('sin', (x, c) => Math.sin(toRad(x, c)), 'sin is applied to each entry. Use sinm(A) for the true matrix sine.');
    sc('cos', (x, c) => Math.cos(toRad(x, c)), 'cos is applied to each entry. Use cosm(A) for the true matrix cosine.');
    sc('tan', (x, c) => { const r = toRad(x, c); guard(Math.abs(Math.cos(r)) < 1e-12, 'tan is undefined at this angle'); return Math.tan(r); });
    sc('sec', (x, c) => { const r = toRad(x, c); guard(Math.abs(Math.cos(r)) < 1e-12, 'sec is undefined at this angle'); return 1 / Math.cos(r); });
    sc('csc', (x, c) => { const r = toRad(x, c); guard(Math.abs(Math.sin(r)) < 1e-12, 'csc is undefined at this angle'); return 1 / Math.sin(r); });
    sc('cot', (x, c) => { const r = toRad(x, c); guard(Math.abs(Math.sin(r)) < 1e-12, 'cot is undefined at this angle'); return Math.cos(r) / Math.sin(r); });
    sc('asin arcsin', (x, c) => { guard(Math.abs(x) > 1 + 1e-12, 'sin⁻¹ only takes values from −1 to 1'); return fromRad(Math.asin(Math.max(-1, Math.min(1, x))), c); });
    sc('acos arccos', (x, c) => { guard(Math.abs(x) > 1 + 1e-12, 'cos⁻¹ only takes values from −1 to 1'); return fromRad(Math.acos(Math.max(-1, Math.min(1, x))), c); });
    sc('atan arctan', (x, c) => fromRad(Math.atan(x), c));
    sc('sinh', Math.sinh); sc('cosh', Math.cosh); sc('tanh', Math.tanh);
    sc('ln', (x) => { guard(x <= 0, 'ln needs a positive number'); return Math.log(x); });
    sc('log', (x) => { guard(x <= 0, 'log needs a positive number'); return Math.log10(x); });
    sc('exp', Math.exp, 'exp is applied to each entry. Use expm(A) for the matrix exponential.');
    sc('sqrt', (x) => { guard(x < -1e-15, '√ of a negative number isn’t real'); return Math.sqrt(Math.max(0, x)); }, '√ is applied to each entry. Use sqrtm(A) for the matrix square root.');
    sc('cbrt', Math.cbrt);
    sc('abs', Math.abs); sc('round', Math.round); sc('floor', Math.floor); sc('ceil', Math.ceil);
    def('mod', 2, 2, ([a, b]) => { const x = asNum(a, 'mod'), m = asNum(b, 'mod'); if (m === 0) throw new MathError('mod by zero'); return ((x % m) + m) % m; });

    const m1 = (names, fn) => def(names, 1, 1, ([v], ctx) => fn(asMat(v, names.split(' ')[0]), ctx));
    m1('det', (A) => det(A));
    m1('tr trace', (A) => { needSquare(A, 'The trace'); return traceOf(A); });
    m1('rank', (A) => rank(A));
    m1('inv', (A) => inverse(A));
    m1('transpose', (A) => transpose(A));
    m1('adj adjoint', (A) => adjugate(A));
    m1('cof cofactors', (A) => cofactorM(A));
    m1('minors', (A) => minorsM(A));
    m1('rref', (A) => rref(A));
    m1('null nullspace', (A) => nullspace(A) || { type: 'text', text: 'Only the zero vector — the columns are independent.' });
    m1('colsp colspace', (A) => colspace(A) || { type: 'text', text: 'Only the zero vector.' });
    m1('eig eigvals', (A) => ({ type: 'list', sym: 'λ', items: eigenvalues(A) }));
    m1('eigvec eigvecs', (A, ctx) => { const r = eigenvectors(A); r.notes.forEach((n) => ctx.warnings.push(n)); return { type: 'multi', parts: r.parts }; });
    m1('charpoly', (A) => ({ type: 'poly', coeffs: charpoly(A) }));
    m1('lu', (A, ctx) => { const r = lu(A); if (r.singular) ctx.warnings.push('This matrix is singular, so U has a zero on its diagonal.'); return { type: 'multi', relation: 'PA = LU', parts: [{ label: 'P', value: r.P }, { label: 'L', value: cleanM(r.L) }, { label: 'U', value: cleanM(r.U) }] }; });
    m1('qr', (A) => { const r = qr(A); return { type: 'multi', relation: 'A = QR', parts: [{ label: 'Q', value: r.Q }, { label: 'R', value: r.R }] }; });
    m1('chol cholesky', (A) => ({ type: 'multi', relation: 'A = LLᵀ', parts: [{ label: 'L', value: cleanM(cholesky(A)) }] }));
    m1('svd', (A) => { const r = svd(A); return { type: 'multi', relation: 'A = UΣVᵀ', parts: [{ label: 'U', value: r.U }, { label: 'Σ', value: r.S }, { label: 'Vᵀ', value: r.Vt }] }; });
    m1('pinv', (A) => pinv(A));
    m1('norm', (A) => frob(A)); m1('norm1', (A) => norm1(A)); m1('norm2', (A) => norm2(A)); m1('norminf', (A) => normInf(A));
    m1('cond', (A) => cond(A));
    m1('expm', (A) => expm(A));
    m1('sinm', (A) => sincosm(A).sin);
    m1('cosm', (A) => sincosm(A).cos);
    m1('sqrtm', (A) => sqrtm(A));
    def('I eye', 1, 1, ([n]) => eye(asInt(n, 'I(n)')));
    def('zeros', 1, 2, ([r, c]) => zeros(asInt(r, 'zeros'), asInt(c != null ? c : r, 'zeros')));
    def('ones', 1, 2, ([r, c]) => mapM(zeros(asInt(r, 'ones'), asInt(c != null ? c : r, 'ones')), () => 1));
    def('diag', 1, 1, ([v]) => {
      const A = asMat(v, 'diag');
      if (A.rows === 1 || A.cols === 1) { const d = A.rows === 1 ? A.data[0] : A.data.map((r) => r[0]); const D = zeros(d.length, d.length); d.forEach((x, i) => { D.data[i][i] = x; }); return D; }
      needSquare(A, 'diag'); return mat(A.data.map((r, i) => [r[i]]));
    });
    def('aug', 2, 2, ([a, b]) => { const A = asMat(a, 'aug'), B = asMat(b, 'aug'); if (A.rows !== B.rows) throw new MathError('aug needs matching rows', `${desc(A)} vs ${desc(B)}.`); return mat(A.data.map((r, i) => [...r, ...B.data[i]])); });
    def('sub', 3, 3, ([a, r, c]) => { const A = asMat(a, 'sub'), i = asInt(r, 'sub'), j = asInt(c, 'sub'); if (i > A.rows || j > A.cols) throw new MathError('That row or column doesn’t exist', `${desc(A)}.`); if (A.rows < 2 || A.cols < 2) throw new MathError('sub needs at least a 2×2 matrix'); return mat(A.data.filter((_, k) => k !== i - 1).map((row) => row.filter((_, l) => l !== j - 1))); });
    def('row', 2, 2, ([a, r]) => { const A = asMat(a, 'row'), i = asInt(r, 'row'); if (i > A.rows) throw new MathError(`Row ${i} doesn’t exist`, `${desc(A)}.`); return mat([A.data[i - 1].slice()]); });
    def('column', 2, 2, ([a, c]) => { const A = asMat(a, 'column'), j = asInt(c, 'column'); if (j > A.cols) throw new MathError(`Column ${j} doesn’t exist`, `${desc(A)}.`); return mat(A.data.map((r) => [r[j - 1]])); });
    def('dot', 2, 2, ([a, b]) => { const u = vecOf(a, 'dot'), v = vecOf(b, 'dot'); if (u.length !== v.length) throw new MathError('dot needs vectors of the same length'); return u.reduce((s, x, i) => s + x * v[i], 0); });
    def('cross', 2, 2, ([a, b]) => { const u = vecOf(a, 'cross'), v = vecOf(b, 'cross'); if (u.length !== 3 || v.length !== 3) throw new MathError('cross needs two 3-vectors'); const w = [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]]; return isMat(a) && a.rows === 1 ? mat([w]) : mat(w.map((x) => [x])); });
    def('kron', 2, 2, ([a, b]) => kron(asMat(a, 'kron'), asMat(b, 'kron')));
    def('hadamard', 2, 2, ([a, b]) => hadamard(asMat(a, 'hadamard'), asMat(b, 'hadamard')));
    def('solve', 2, 2, ([a, b], ctx) => solve(asMat(a, 'solve'), asMat(b, 'solve'), ctx));
    return F;
  }
  const FUNCS = makeFuncs();
  const CONSTS = { 'π': Math.PI, pi: Math.PI, e: Math.E };

  function evalNode(n, ctx) {
    const v = evalNode0(n, ctx);
    if (ctx.memo) ctx.memo.set(n, v);
    return v;
  }
  function evalNode0(n, ctx) {
    switch (n.k) {
      case 'num': return n.v;
      case 'id': return lookup(n.v, ctx);
      case 'neg': { const v = evalNode(n.a, ctx); return isEye(v) ? { type: 'eye', s: -v.s } : arithMul(-1, needValue(v)); }
      case 'bin': {
        const a = needValue(evalNode(n.a, ctx), true), b = needValue(evalNode(n.b, ctx), true);
        if (n.op === '+') return arithAdd(a, b, 1);
        if (n.op === '-') return arithAdd(a, b, -1);
        if (n.op === '*') return arithMul(a, b);
        if (n.op === '/') return arithDiv(a, b, ctx);
        return hadamard(a, b);
      }
      case 'pow': {
        if (n.b.k === 'id' && n.b.v === 'T' && !Object.prototype.hasOwnProperty.call(ctx.vars, 'T')) return postOp('T', needValue(evalNode(n.a, ctx)), ctx);
        const a = needValue(evalNode(n.a, ctx)), b = needValue(evalNode(n.b, ctx));
        if (!isNum(b)) throw new MathError('Exponents must be numbers', 'For example A^3 or 2^0.5.');
        if (isNum(a)) { const r = Math.pow(a, b); if (isNaN(r)) throw new MathError('The result isn’t a real number', 'A negative number can’t take a fractional power.'); return r; }
        if (Math.abs(b - Math.round(b)) < 1e-9) return matPow(a, Math.round(b));
        if (Math.abs(b - 0.5) < 1e-12) return sqrtm(a);
        throw new MathError('Matrix powers need a whole number', 'Use sqrtm(A) for a square root.');
      }
      case 'post': return postOp(n.op, needValue(evalNode(n.a, ctx)), ctx);
      case 'lit': {
        const rows = n.rows.map((r) => r.map((e) => { const v = needValue(evalNode(e, ctx)); if (!isNum(v)) throw new MathError('Entries inside [ ] must be numbers'); return v; }));
        if (rows.some((r) => r.length !== rows[0].length)) throw new MathError('Every row needs the same number of entries', 'Separate entries with “,” and rows with “;”.');
        return mat(rows);
      }
      case 'bars': { const v = needValue(evalNode(n.a, ctx)); return isNum(v) ? Math.abs(v) : det(asMat(v, '|…|')); }
      case 'call': {
        const f = FUNCS[n.f];
        if (n.args.length < f.min || n.args.length > f.max) throw new MathError(`${n.f}(…) takes ${f.min === f.max ? f.min : f.min + '–' + f.max} input${f.max > 1 ? 's' : ''}`, `It got ${n.args.length}.`);
        const args = n.args.map((a) => needValue(evalNode(a, ctx)));
        return f.fn(args, ctx);
      }
      default: throw new MathError('Unknown expression');
    }
  }
  function needValue(v, allowEye) {
    if (isNum(v) || isMat(v)) return v;
    if (isEye(v) && allowEye !== false) return v;
    if (v && v.type === 'invalid') throw new MathError(`Matrix ${v.name} has an entry that needs fixing`, v.where);
    if (v && (v.type === 'list' || v.type === 'multi' || v.type === 'poly' || v.type === 'text')) throw new MathError('This result can’t be used inside a calculation', 'Functions like eig, lu or svd give several outputs — use them on their own line.');
    return v;
  }
  function postOp(op, v, ctx) {
    switch (op) {
      case 'T': return isMat(v) ? transpose(v) : v;
      case 'inv': return isNum(v) ? (v === 0 ? (() => { throw new MathError('Division by zero'); })() : 1 / v) : inverse(asMat(v, 'inverse'));
      case 'sq': return isNum(v) ? v * v : matPow(asMat(v), 2);
      case 'cube': return isNum(v) ? v * v * v : matPow(asMat(v), 3);
      case 'deg': return elementwise(v, (x) => (ctx.angle === 'deg' ? x : (x * Math.PI) / 180));
      case 'fact': return elementwise(v, factorial);
      default: throw new MathError('Unknown operator');
    }
  }
  function lookup(name, ctx) {
    if (Object.prototype.hasOwnProperty.call(ctx.vars, name)) return ctx.vars[name];
    if (Object.prototype.hasOwnProperty.call(CONSTS, name)) return CONSTS[name];
    if (name === 'I') return { type: 'eye', s: 1 };
    if (/^[A-Z]{2,}$/.test(name) && [...name].every((c) => Object.prototype.hasOwnProperty.call(ctx.vars, c) || c === 'I')) {
      return [...name].map((c) => lookup(c, ctx)).reduce((acc, v) => arithMul(needValue(acc), needValue(v)));
    }
    throw new UnknownName(name);
  }

  const ASSIGN = /^\s*([A-Za-z][A-Za-z0-9_]*|[α-ωΑ-Ω])\s*=(?!=)(.*)$/s;
  function splitAssignment(text) { const m = ASSIGN.exec(text); return m ? { name: m[1], body: m[2] } : null; }
  const RESERVED = new Set([...Object.keys(FUNCS), ...Object.keys(CONSTS), 'I', 'T']);

  function evaluate(text, env) {
    const ctx = { vars: env.vars || {}, angle: env.angle || 'rad', warnings: [] };
    let body = text, assign = null;
    try {
      const a = splitAssignment(text);
      if (a) {
        if (/^[A-Z]{2,}$/.test(a.name)) throw new MathError('Use one capital letter or a lowercase name', 'Capitals side by side multiply, so AB means A·B.');
        if (RESERVED.has(a.name)) throw new MathError(`“${a.name}” is a built-in name`, 'Pick another name for this value.');
        if (env.matrixNames && env.matrixNames.has(a.name)) throw new MathError(`${a.name} is already a matrix`, 'Pick another name, or edit the matrix directly.');
        assign = a.name; body = a.body;
      }
      if (!body.trim()) return { ok: false, empty: true, assign };
      const tree = parse(body, FUNCS, ctx.vars);
      let v = evalNode(tree, ctx);
      if (isEye(v)) throw new MathError('I needs a size here', 'Write I(3), or use it next to a matrix like A − 2I.');
      if (isMat(v)) v = cleanM(v);
      if (isNum(v)) v = cleanNum(v);
      return { ok: true, value: v, warnings: ctx.warnings, assign };
    } catch (e) {
      if (e instanceof MathError) return { ok: false, error: e.message, hint: e.hint, unknown: e.unknown, assign };
      return { ok: false, error: 'Something went wrong evaluating this', hint: String(e && e.message || e), assign };
    }
  }
  function evalScalar(text, angle) {
    const r = evaluate(text, { vars: {}, angle });
    if (r.empty) return { ok: false, error: 'Empty entry' };
    if (r.ok && !isNum(r.value)) return { ok: false, error: 'An entry must be a single number' };
    return r;
  }

  /* ======================================================================
     Step-by-step solutions — replays an expression one operation at a time
     and, for each operation, the working a student would write by hand.
     Mirrors the shipped app's lib/engine/steps.dart.
     ====================================================================== */
  const SUBD = '₀₁₂₃₄₅₆₇₈₉', SUPD = { 0: '⁰', 1: '¹', 2: '²', 3: '³', 4: '⁴', 5: '⁵', 6: '⁶', 7: '⁷', 8: '⁸', 9: '⁹', '-': '⁻' };
  const subI = (k) => String(k).split('').map((c) => SUBD[+c]).join('');
  const ix = (i, j) => (j == null ? subI(i + 1) : subI(i + 1) + subI(j + 1));
  const supI = (k) => String(k).split('').map((c) => SUPD[c]).join('');
  const nT = (x) => plain(cleanNum(x));
  const fT = (x) => (cleanNum(x) < 0 ? `(${nT(x)})` : nT(x));
  const tidy = (v) => (isMat(v) ? cleanM(v) : isNum(v) ? cleanNum(v) : v);

  const FN_TITLE = {
    det: 'Determinant', tr: 'Trace', trace: 'Trace', rank: 'Rank', inv: 'Inverse', transpose: 'Transpose',
    adj: 'Adjugate', adjoint: 'Adjugate', cof: 'Cofactor matrix', cofactors: 'Cofactor matrix', minors: 'Matrix of minors',
    rref: 'Reduced row echelon form', null: 'Null space', nullspace: 'Null space', colsp: 'Column space', colspace: 'Column space',
    eig: 'Eigenvalues', eigvals: 'Eigenvalues', eigvec: 'Eigenvectors', eigvecs: 'Eigenvectors', charpoly: 'Characteristic polynomial',
    lu: 'LU decomposition', qr: 'QR decomposition', chol: 'Cholesky decomposition', cholesky: 'Cholesky decomposition',
    svd: 'Singular value decomposition', pinv: 'Pseudo-inverse', norm: 'Frobenius norm', norm1: '1-norm', norm2: 'Spectral norm',
    norminf: '∞-norm', cond: 'Condition number', expm: 'Matrix exponential', sinm: 'Matrix sine', cosm: 'Matrix cosine',
    sqrtm: 'Matrix square root', dot: 'Dot product', cross: 'Cross product', kron: 'Kronecker product', hadamard: 'Entrywise product',
    solve: 'Solve the system', aug: 'Join side by side', sub: 'Remove a row and a column', row: 'Take a row', column: 'Take a column',
    diag: 'Diagonal', zeros: 'Build the matrix', ones: 'Build the matrix', I: 'Identity matrix', eye: 'Identity matrix',
  };
  const FN_NOTE = {
    transpose: 'Rows become columns.',
    pinv: 'From the SVD: A⁺ = V·Σ⁺·Uᵀ, where Σ⁺ turns each non-zero singular value σ into 1/σ.',
    norm2: 'The largest singular value.',
    expm: 'The series I + A + A²/2! + A³/3! + …, summed by scaling the matrix down, using a Padé approximation and squaring back up.',
    sinm: 'The series A − A³/3! + A⁵/5! − …', cosm: 'The series I − A²/2! + A⁴/4! − …',
    sqrtm: 'The matrix X with X·X equal to this one, found by iteration.',
    kron: 'Every entry of the left matrix is replaced by that entry times the right matrix.',
    hadamard: 'Entries in the same position are multiplied.',
    aug: 'The second matrix is written to the right of the first.',
    norm: 'The square root of the sum of every entry squared.',
    norm1: 'The largest column sum, ignoring signs.', norminf: 'The largest row sum, ignoring signs.',
    lu: 'A lower-triangular L and an upper-triangular U with PA = LU.', qr: 'An orthogonal Q and an upper-triangular R with A = QR.',
    chol: 'A lower-triangular L with A = L·Lᵀ.', svd: 'A = U·Σ·Vᵀ, with the singular values down the diagonal of Σ.',
    eigvec: 'For each eigenvalue λ, the non-zero solutions of (A − λI)v = 0.', charpoly: 'det(λI − A), written as a polynomial in λ.',
    null: 'Every x with A·x = 0.', colsp: 'Everything the columns can add up to.',
  };
  FN_NOTE.cholesky = FN_NOTE.chol; FN_NOTE.eigvecs = FN_NOTE.eigvec; FN_NOTE.nullspace = FN_NOTE.null; FN_NOTE.colspace = FN_NOTE.colsp;
  const TRIG = new Set(['sin', 'cos', 'tan', 'sec', 'csc', 'cot', 'asin', 'arcsin', 'acos', 'arccos', 'atan', 'arctan']);

  /* ---------- writing an expression back out ---------- */
  const PREC = (n) => (n.k === 'bin' ? (n.op === '+' || n.op === '-' ? 1 : 2) : n.k === 'neg' ? 3 : n.k === 'pow' || n.k === 'post' ? 4 : 5);
  const POST_MARK = { T: 'ᵀ', inv: '⁻¹', sq: '²', cube: '³', deg: '°', fact: '!' };
  function litNum(v) { return String(Number(v.toPrecision(12))); }
  function show(n, vars) {
    const inner = (x, lv) => (PREC(x) < lv ? `(${show(x, vars)})` : show(x, vars));
    switch (n.k) {
      case 'num': return litNum(n.v);
      case 'id': return n.v;
      case 'neg': return '−' + inner(n.a, 3);
      case 'bin': {
        if (n.op === '+') return `${inner(n.a, 1)} + ${inner(n.b, 2)}`;
        if (n.op === '-') return `${inner(n.a, 1)} − ${inner(n.b, 2)}`;
        if (n.op === '/') return `${inner(n.a, 2)}/${inner(n.b, 3)}`;
        if (n.op === '∘') return `${inner(n.a, 2)} ∘ ${inner(n.b, 3)}`;
        const l = inner(n.a, 2), r = inner(n.b, 2);
        return n.a.k === 'num' && /^[A-Za-zα-ωπ(√[]/.test(r) ? l + r : `${l}·${r}`;
      }
      case 'pow': {
        if (n.b.k === 'id' && n.b.v === 'T' && !(vars && Object.prototype.hasOwnProperty.call(vars, 'T'))) return inner(n.a, 5) + 'ᵀ';
        const e = n.b.k === 'num' && Number.isInteger(n.b.v) ? n.b.v : n.b.k === 'neg' && n.b.a.k === 'num' && Number.isInteger(n.b.a.v) ? -n.b.a.v : null;
        if (e != null && Math.abs(e) < 100) return inner(n.a, 5) + supI(e);
        return `${inner(n.a, 5)}^${inner(n.b, 5)}`;
      }
      case 'post': return inner(n.a, 4) + POST_MARK[n.op];
      case 'lit': return `[${n.rows.map((r) => r.map((e) => show(e, vars)).join(', ')).join('; ')}]`;
      case 'bars': return `|${show(n.a, vars)}|`;
      case 'call': {
        if ((n.f === 'sqrt' || n.f === 'cbrt') && n.args.length === 1) { const a = n.args[0]; return (n.f === 'sqrt' ? '√' : '∛') + (PREC(a) >= 5 && a.k !== 'call' ? show(a, vars) : `(${show(a, vars)})`); }
        return `${n.f}(${n.args.map((a) => show(a, vars)).join(', ')})`;
      }
      default: return '';
    }
  }
  /* LaTeX */
  function texNum(x, mode = 'exact', precision = 4) {
    const d = describe(x, mode, precision), s = d.neg ? '-' : '';
    switch (d.kind) {
      case 'special': return d.text === '∞' ? '\\infty' : d.text === '−∞' ? '-\\infty' : '\\text{undefined}';
      case 'int': return s + d.n;
      case 'frac': return `${s}\\frac{${d.n}}{${d.d}}`;
      case 'surd': { const top = `${d.n === 1 ? '' : d.n}\\sqrt{${d.k}}`; return s + (d.d === 1 ? top : `\\frac{${top}}{${d.d}}`); }
      case 'pi': { const top = `${d.n === 1 ? '' : d.n}\\pi`; return s + (d.d === 1 ? top : `\\frac{${top}}{${d.d}}`); }
      default: return s + (d.text != null ? d.text : `${d.mant} \\times 10^{${d.exp}}`);
    }
  }
  const texMat = (M, mode, p) => `\\begin{bmatrix} ${M.data.map((r) => r.map((x) => texNum(x, mode, p)).join(' & ')).join(' \\\\ ')} \\end{bmatrix}`;
  const TEX_FN = { det: '\\det', sin: '\\sin', cos: '\\cos', tan: '\\tan', sec: '\\sec', csc: '\\csc', cot: '\\cot', sinh: '\\sinh', cosh: '\\cosh', tanh: '\\tanh', ln: '\\ln', log: '\\log', exp: '\\exp', asin: '\\arcsin', acos: '\\arccos', atan: '\\arctan', arcsin: '\\arcsin', arccos: '\\arccos', arctan: '\\arctan' };
  const TEX_NAME = { 'π': '\\pi', pi: '\\pi', 'λ': '\\lambda' };
  function tex(n, vars) {
    const inner = (x, lv) => (PREC(x) < lv ? `\\left( ${tex(x, vars)} \\right)` : tex(x, vars));
    switch (n.k) {
      case 'num': return litNum(n.v);
      case 'id': return TEX_NAME[n.v] || (n.v.length > 1 ? `\\mathrm{${n.v.replace(/_/g, '\\_')}}` : n.v);
      case 'neg': return '-' + inner(n.a, 3);
      case 'bin': {
        if (n.op === '+') return `${inner(n.a, 1)} + ${inner(n.b, 2)}`;
        if (n.op === '-') return `${inner(n.a, 1)} - ${inner(n.b, 2)}`;
        if (n.op === '/') return /^(num|id|neg|bin)$/.test(n.a.k) && /^(num|id|bin)$/.test(n.b.k) && !isMatNode(n.a, vars) && !isMatNode(n.b, vars) ? `\\frac{${tex(n.a, vars)}}{${tex(n.b, vars)}}` : `${inner(n.a, 2)} / ${inner(n.b, 3)}`;
        if (n.op === '∘') return `${inner(n.a, 2)} \\circ ${inner(n.b, 3)}`;
        const l = inner(n.a, 2), r = inner(n.b, 2);
        return /^(\d|-|\\frac)/.test(r) ? `${l} \\cdot ${r}` : `${l} ${r}`;
      }
      case 'pow': {
        if (n.b.k === 'id' && n.b.v === 'T' && !(vars && Object.prototype.hasOwnProperty.call(vars, 'T'))) return `${inner(n.a, 5)}^{\\mathsf{T}}`;
        return `${inner(n.a, 5)}^{${tex(n.b, vars)}}`;
      }
      case 'post': return inner(n.a, 4) + ({ T: '^{\\mathsf{T}}', inv: '^{-1}', sq: '^{2}', cube: '^{3}', deg: '^{\\circ}', fact: '!' })[n.op];
      case 'lit': return `\\begin{bmatrix} ${n.rows.map((r) => r.map((e) => tex(e, vars)).join(' & ')).join(' \\\\ ')} \\end{bmatrix}`;
      case 'bars': return `\\left| ${tex(n.a, vars)} \\right|`;
      case 'call': {
        const a = n.args;
        if (n.f === 'sqrt' && a.length === 1) return `\\sqrt{${tex(a[0], vars)}}`;
        if (n.f === 'cbrt' && a.length === 1) return `\\sqrt[3]{${tex(a[0], vars)}}`;
        if (n.f === 'abs' && a.length === 1) return `\\left| ${tex(a[0], vars)} \\right|`;
        return `${TEX_FN[n.f] || `\\operatorname{${n.f}}`}\\left( ${a.map((x) => tex(x, vars)).join(', ')} \\right)`;
      }
      default: return '';
    }
  }
  function isMatNode(n, vars) { return n.k === 'id' && vars && isMat(vars[n.v]); }
  function texValue(v, mode = 'exact', p = 4) {
    if (isNum(v)) return texNum(v, mode, p);
    if (isMat(v)) return texMat(v, mode, p);
    if (v && v.type === 'list') return v.items.map((z, i) => `\\lambda_{${i + 1}} = ${isNum(z) ? texNum(z, mode, p) : `${texNum(z.re, mode, p)} ${z.im < 0 ? '-' : '+'} ${texNum(Math.abs(z.im), mode, p)}i`}`).join(',\; ');
    if (v && v.type === 'multi') return v.parts.map((pt) => `${pt.label.replace('Σ', '\\Sigma').replace('ᵀ', '^{\\mathsf{T}}')} = ${texMat(pt.value, mode, p)}`).join(',\\quad ');
    if (v && v.type === 'poly') { const n = v.coeffs.length - 1; return v.coeffs.map((c, k) => { const pw = n - k; if (Math.abs(c) < 1e-11) return ''; const a = Math.abs(c), co = Math.abs(a - 1) < 1e-12 && pw > 0 ? '' : texNum(a, mode, p); return `${c < 0 ? ' - ' : k ? ' + ' : ''}${co}${pw === 0 ? '' : pw === 1 ? '\\lambda' : `\\lambda^{${pw}}`}`; }).join(''); }
    return `\\text{${(v && v.text) || ''}}`;
  }
  function exprTex(text, vars = {}) {
    try { const a = splitAssignment(text), body = a ? a.body : text; const t = tex(parse(body, FUNCS, vars), vars); return a ? `${a.name} = ${t}` : t; } catch (e) { return text; }
  }

  /* ---------- the explainer ---------- */
  const W = {
    text: (text, indent = 0) => ({ k: 'text', text, indent }),
    math: (text, indent = 0) => ({ k: 'math', text, indent }),
    matrix: (mat, label, aug, indent = 0) => ({ k: 'matrix', mat, label, aug, indent }),
    ops: (ops, mat, aug, indent = 0) => ({ k: 'ops', ops, mat, aug, indent }),
  };
  const method = (name, build, weight = 0) => ({ name, weight, _w: null, get work() { if (!this._w) this._w = build(); return this._w; } });
  const fact = (k) => (k <= 1 ? 1 : k * fact(k - 1));
  const cube = (m) => m.rows * m.rows * m.cols;
  const FULL_EXPANSION = 4;
  const MINOR_LETTERS = ['M', 'N', 'P', 'Q', 'R', 'S', 'T'];
  const minorMat = (m, r, c) => mat(m.data.filter((_, i) => i !== r).map((row) => row.filter((_, j) => j !== c)));
  const det2 = (m) => `${fT(m.data[0][0])}·${fT(m.data[1][1])} − ${fT(m.data[0][1])}·${fT(m.data[1][0])}`;
  function bestRow(m) { let row = 0, best = -1; m.data.forEach((r, i) => { const z = r.filter((x) => x === 0).length; if (z > best) { best = z; row = i; } }); return [row, best]; }
  function rowsWork(r, intro) {
    const w = [];
    if (intro) w.push(W.text(intro));
    w.push(W.matrix(r.start, 'Start', r.aug));
    r.steps.forEach((s) => w.push(W.ops(s.ops, s.m, r.aug)));
    if (!r.steps.length) w.push(W.text('No row operations are needed: it is already reduced.'));
    if (r.summary) w.push(/=/.test(r.summary) ? W.math(r.summary) : W.text(r.summary));
    if (r.note) w.push(W.text(r.note));
    return w;
  }
  function expand(m, name, depth, w) {
    const size = m.rows;
    if (size === 1) { w.push(W.math(`${name} = ${nT(m.data[0][0])}`, depth)); return m.data[0][0]; }
    if (size === 2) { const d = m.data[0][0] * m.data[1][1] - m.data[0][1] * m.data[1][0]; w.push(W.math(`${name} = ${det2(m)} = ${nT(d)}`, depth)); return d; }
    const [row, zeros] = bestRow(m), most = zeros > 0 ? ', which has the most zeros' : '';
    w.push(W.text(depth === 0
      ? `Expand along row ${row + 1}${most}: each entry times the determinant of what is left when its row and column are removed, with signs + − + …`
      : `Expand ${name} along its row ${row + 1}${most}.`, depth));
    const letter = MINOR_LETTERS[Math.min(depth, MINOR_LETTERS.length - 1)];
    let terms = '', total = 0;
    for (let j = 0; j < size; j++) {
      const e = m.data[row][j]; if (e === 0) continue;
      const minor = minorMat(m, row, j), mName = `${letter}${ix(row, j)}`;
      let mv;
      if (size === 3) mv = expand(minor, mName, depth, w);
      else { w.push(W.matrix(minor, `${mName}: remove row ${row + 1} and column ${j + 1}`, null, depth)); mv = expand(minor, mName, depth + 1, w); }
      const plus = (row + j) % 2 === 0;
      terms += (terms ? (plus ? ' + ' : ' − ') : (plus ? '' : '−')) + `${fT(e)}·${fT(mv)}`;
      total += (plus ? 1 : -1) * e * mv;
    }
    if (!terms) { w.push(W.text(`Row ${row + 1} is all zeros, so ${depth === 0 ? 'the determinant' : name} is 0.`, depth)); return 0; }
    w.push(W.math(`${name} = ${terms} = ${nT(total)}`, depth));
    return total;
  }
  function cofactorWork(m) {
    const w = [];
    if (m.rows > FULL_EXPANSION) {
      const [row, zeros] = bestRow(m);
      w.push(W.text(`Expand along row ${row + 1}${zeros > 0 ? ', which has the most zeros' : ''}. Expanding every minor in turn would take ${m.rows}! ÷ 2 two-by-two determinants, far too many to write out, so each minor’s determinant is given here. Row reduction has the complete working at this size.`));
      let terms = '', total = 0;
      for (let j = 0; j < m.cols; j++) {
        const e = m.data[row][j]; if (e === 0) continue;
        const minor = minorMat(m, row, j), mv = cleanNum(det(minor));
        w.push(W.matrix(minor, `M${ix(row, j)}: remove row ${row + 1} and column ${j + 1}. Its determinant is ${nT(mv)}.`));
        const plus = (row + j) % 2 === 0;
        terms += (terms ? (plus ? ' + ' : ' − ') : (plus ? '' : '−')) + `${fT(e)}·${fT(mv)}`;
        total += (plus ? 1 : -1) * e * mv;
      }
      w.push(terms ? W.math(`det = ${terms} = ${nT(total)}`) : W.text(`Row ${row + 1} is all zeros, so the determinant is 0.`));
      return w;
    }
    expand(m, 'det', 0, w);
    return w;
  }
  function detMethods(m) {
    const size = m.rows; if (size === 1) return [];
    const cof = method('Cofactor expansion', () => cofactorWork(m), size <= FULL_EXPANSION ? fact(size) * size : cube(m));
    const rows = method('Row reduction', () => rowsWork(steps.det(m), 'Reduce to a triangle. The determinant is then the product of the diagonal.'), cube(m));
    const formula = method('Formula', () => [W.text('For a 2×2 matrix: the product of the main diagonal minus the product of the other diagonal.'), W.math(`det = ${det2(m)} = ${nT(det(m))}`)]);
    if (size === 2) return [formula, rows];
    if (size <= 4) return [cof, rows];
    return [rows, cof];
  }
  function minorLines(m, signed) {
    const size = m.rows, w = [];
    for (let i = 0; i < size; i++) for (let j = 0; j < size; j++) {
      const minor = minorMat(m, i, j), neg = signed && (i + j) % 2 === 1, name = `${signed ? 'C' : 'M'}${ix(i, j)}`;
      if (size === 2) { const e = minor.data[0][0]; w.push(W.math(!signed || !neg ? `${name} = ${nT(e)}` : `${name} = −${fT(e)}${e < 0 ? ` = ${nT(-e)}` : ''}`)); continue; }
      if (size === 3) { const mv = cleanNum(det(minor)), b = det2(minor); w.push(W.math(`${name} = ${!signed ? b : neg ? `−(${b})` : b} = ${nT(neg ? -mv : mv)}`)); continue; }
      const mName = `M${ix(i, j)}`;
      w.push(W.matrix(minor, `${mName}: remove row ${i + 1} and column ${j + 1}`));
      const mv = cleanNum(size - 1 <= 4 ? expand(minor, mName, 1, w) : det(minor));
      if (signed) w.push(W.math(`${name} = ${neg ? '−' : ''}${mName} = ${nT(neg ? -mv : mv)}`));
    }
    return w;
  }
  function inverseMethods(m) {
    const size = m.rows; if (size === 1) return [];
    const d = cleanNum(det(m)), out = [];
    if (size === 2) out.push(method('Formula', () => [
      W.text('For a 2×2 matrix: swap the diagonal entries, change the sign of the other two, and divide by the determinant.'),
      W.math(`det = ${det2(m)} = ${nT(d)}`),
      W.matrix(mat([[m.data[1][1], -m.data[0][1]], [-m.data[1][0], m.data[0][0]]]), 'Swapped and sign-changed'),
      W.matrix(cleanM(inverse(m)), `Divided by ${nT(d)}`),
    ]));
    out.push(method('Gauss–Jordan', () => rowsWork(steps.inverse(m), 'Write the matrix beside I, then row-reduce until the left half is I.'), cube(m) * 2));
    out.push(method('Adjugate', () => [
      W.text('The inverse is the adjugate divided by the determinant.'), W.math(`det = ${nT(d)}`), ...minorLines(m, true),
      W.matrix(cleanM(cofactorM(m)), 'The cofactor matrix'), W.matrix(cleanM(adjugate(m)), 'Its transpose, the adjugate'),
      W.matrix(cleanM(inverse(m)), `Divided by ${nT(d)}`),
    ], size * size * (size - 1 <= 4 ? fact(size - 1) : 1)));
    return out;
  }
  function solveMethods(A, b) {
    if (A.rows !== b.rows) return [];
    const cols = A.cols, sq = A.rows === cols, d = sq ? cleanNum(det(A)) : 0, unique = sq && Math.abs(d) > tolFor(A, 1e-10);
    const out = [method('Elimination', () => {
      const aug = mat(A.data.map((r, i) => [...r, ...b.data[i]])), r = rrefCore(aug, { hand: true, augAt: cols });
      const w = [W.text('Write A and b side by side, then row-reduce the left half.'), W.matrix(aug, 'Start', cols)];
      r.steps.forEach((s) => w.push(W.ops(s.ops, s.m, cols)));
      if (unique && b.cols === 1) for (let i = 0; i < cols; i++) w.push(W.math(`x${ix(i)} = ${nT(r.R.data[i][cols])}`));
      else w.push(W.text('Each pivot row now gives one unknown in terms of the right-hand side.'));
      return w;
    }, cube(A))];
    if (unique && b.cols === 1) {
      out.push(method('Cramer’s rule', () => {
        const w = [W.text('Each unknown is a ratio of determinants: replace one column of A with b, and divide by det(A).'), W.math(`D = det(A) = ${nT(d)}`)];
        for (let j = 0; j < cols; j++) {
          const sw = mat(A.data.map((r, i) => r.map((x, k) => (k === j ? b.data[i][0] : x)))), dj = cleanNum(det(sw));
          w.push(W.matrix(sw, `D${ix(j)}: column ${j + 1} replaced by b. Its determinant is ${nT(dj)}.`));
          w.push(W.math(`x${ix(j)} = D${ix(j)} ÷ D = ${fT(dj)} ÷ ${fT(d)} = ${nT(dj / d)}`));
        }
        return w;
      }, cube(A) * cols));
      out.push(method('Inverse', () => [
        W.text('A is square and invertible, so x = A⁻¹·b: find the inverse, then multiply it by b.'),
        W.matrix(cleanM(inverse(A)), 'A⁻¹'),
        W.matrix(cleanM(mulM(inverse(A), b)), 'x = A⁻¹·b'),
      ], cube(A) * 2));
    }
    return out;
  }
  function mulWork(l, r) {
    const w = [W.text('Go along a row of the left matrix and down a column of the right one, multiply in pairs and add.')];
    for (let i = 0; i < l.rows; i++) for (let j = 0; j < r.cols; j++) {
      let s = 0; const parts = [];
      for (let k = 0; k < l.cols; k++) { parts.push(`${fT(l.data[i][k])}·${fT(r.data[k][j])}`); s += l.data[i][k] * r.data[k][j]; }
      w.push(W.math(`c${ix(i, j)} = ${parts.join(' + ')} = ${nT(s)}`));
    }
    return w;
  }
  const entries = (v, f) => { const w = []; for (let i = 0; i < v.rows; i++) for (let j = 0; j < v.cols; j++) w.push(W.math(`c${ix(i, j)} = ${f(i, j)} = ${nT(v.data[i][j])}`)); return w; };

  function Explainer(ctx) {
    const memo = ctx.memo, vars = ctx.vars, steps = [];
    const val = (n) => memo.get(n);
    const isAtom = (x) => x.k === 'num' || x.k === 'id' || (x.k === 'lit' && x.rows.every((r) => r.every(arith))) || (x.k === 'neg' && x.a.k === 'num') || (x.k === 'post' && x.op === 'deg' && isAtom(x.a));
    function arith(x) {
      switch (x.k) {
        case 'num': return true;
        case 'id': return x.v !== 'I' && !isMat(vars[x.v]) && !(vars[x.v] && vars[x.v].type === 'invalid');
        case 'neg': case 'post': case 'bars': return arith(x.a);
        case 'bin': case 'pow': return arith(x.a) && arith(x.b);
        case 'call': return !FN_TITLE[x.f] && x.args.every(arith);
        default: return false;
      }
    }
    const kids = (x) => {
      const k = [];
      if (x.a) k.push(x.a);
      if (x.b && !(x.k === 'pow' && x.b.k === 'id' && x.b.v === 'T')) k.push(x.b);
      if (x.args) k.push(...x.args);
      if (x.rows) x.rows.forEach((r) => r.forEach((e) => { if (!arith(e)) k.push(e); }));
      return k;
    };
    function walk(x, top, inNumbers) {
      if (isAtom(x)) return;
      const v = val(x); if (v === undefined) return;
      const numbers = arith(x);
      if (numbers && !top && !inNumbers) { steps.push({ title: 'Work out the number', expr: show(x, vars), tex: tex(x, vars), value: tidy(v), methods: [] }); return; }
      kids(x).forEach((k) => walk(k, false, numbers));
      if (isEye(v)) return;
      steps.push(make(x, v));
    }
    function make(x, v) {
      const st = { title: '', expr: show(x, vars), tex: tex(x, vars), value: tidy(v), note: null, methods: [] };
      const set = (title, note, methods) => Object.assign(st, { title, note: note || null, methods: methods || [] });
      switch (x.k) {
        case 'call': {
          const name = x.f, args = x.args.map(val);
          if (!FN_TITLE[name]) {
            const onM = isMat(args[0]);
            return set(onM ? `Apply ${name} to every entry` : `Work out ${name}`, TRIG.has(name) ? `Angles are in ${ctx.angle === 'deg' ? 'degrees' : 'radians'}.` : null);
          }
          const title = FN_TITLE[name], m = args[0];
          if (name === 'solve' && isMat(args[0]) && isMat(args[1])) return set(title, 'Find x with A·x = b.', solveMethods(args[0], args[1]));
          if (name === 'dot') {
            const u = vecOf(args[0], 'dot'), w2 = vecOf(args[1], 'dot');
            return set(title, 'Multiply matching entries and add them up.', [method('Working', () => [W.math(`${u.map((a, i) => `${fT(a)}·${fT(w2[i])}`).join(' + ')} = ${nT(v)}`)])]);
          }
          if (name === 'cross') return set(title, 'A vector at right angles to both.');
          if (!isMat(m)) return set(title, FN_NOTE[name]);
          const sq = m.rows === m.cols;
          switch (name) {
            case 'det': return set(title, null, sq ? detMethods(m) : []);
            case 'inv': return set(title, null, sq ? inverseMethods(m) : []);
            case 'tr': case 'trace': {
              const d = m.data.map((r, i) => r[i]).slice(0, Math.min(m.rows, m.cols));
              return set(title, 'The sum of the diagonal entries.', [method('Working', () => [W.math(`tr = ${d.map((x2, i) => (i ? (x2 < 0 ? ` − ${nT(-x2)}` : ` + ${nT(x2)}`) : nT(x2))).join('')} = ${nT(v)}`)])]);
            }
            case 'rank': return set(title, 'The number of rows that are not all zero once it is row-reduced.', [method('Row reduction', () => rowsWork(steps0.rref(m)), cube(m))]);
            case 'rref': return set(title, 'Row operations until every pivot is 1 with zeros above and below it.', [method('Row reduction', () => rowsWork(steps0.rref(m)), cube(m))]);
            case 'minors': case 'cof': case 'cofactors': case 'adj': case 'adjoint': {
              if (!sq || m.rows < 2) return set(title);
              const minors = name === 'minors', adj = name === 'adj' || name === 'adjoint';
              const note = minors ? 'Each entry is the determinant of what is left when that entry’s row and column are removed.' : adj ? 'The transpose of the cofactor matrix.' : 'Each minor with its sign: + where row + column is even, − where it is odd.';
              return set(title, note, [method('Working', () => adj ? [...minorLines(m, true), W.matrix(cleanM(cofactorM(m)), 'The cofactor matrix'), W.text('Its transpose is the adjugate.')] : minorLines(m, !minors), m.rows * m.rows * fact(m.rows - 1))]);
            }
            case 'eig': case 'eigvals': {
              if (!sq) return set(title);
              return set(title, 'The numbers λ with A·v = λv for some non-zero v.', [method('Characteristic equation', () => {
                const cp = charpoly(m), deg = cp.length - 1;
                const poly = cp.map((c, k) => { const p = deg - k; if (Math.abs(c) < 1e-11) return ''; const a = Math.abs(c), co = Math.abs(a - 1) < 1e-12 && p > 0 ? '' : nT(a); return `${c < 0 ? (k ? ' − ' : '−') : k ? ' + ' : ''}${co}${p === 0 ? '' : p === 1 ? 'λ' : 'λ' + supI(p)}`; }).join('');
                return [W.text('The eigenvalues are the roots of det(A − λI) = 0.'), W.math(`p(λ) = ${poly}`), W.text(deg <= 2 ? 'Solve this quadratic for λ.' : 'Its roots are then found numerically.')];
              })]);
            }
            case 'cond': return set(title, 'The largest singular value divided by the smallest. Large values mean small changes in the input can change the answer a lot.', [method('Working', () => { const s = svd(m).sigma, hi = Math.max(...s), lo = Math.min(...s); return [W.math(`σ = ${s.map(nT).join(',  ')}`), ...(lo > 0 ? [W.math(`${nT(hi)} ÷ ${nT(lo)} = ${nT(hi / lo)}`)] : [])]; })]);
            default: return set(title, FN_NOTE[name]);
          }
        }
        case 'post': {
          const a = val(x.a);
          if (x.op === 'T') return set('Transpose', FN_NOTE.transpose);
          if (x.op === 'inv') return isMat(a) ? set('Inverse', null, a.rows === a.cols ? inverseMethods(a) : []) : set('Take the reciprocal');
          if (x.op === 'sq' || x.op === 'cube') { const k = x.op === 'sq' ? 2 : 3; return isMat(a) ? set(`Raise to the power ${k}`, `The matrix multiplied by itself ${k} times.`, [method('One multiplication at a time', () => { const w = []; let P = a; for (let i = 1; i < k; i++) { const Q = mulM(P, a); w.push(W.matrix(cleanM(Q), `${i === 1 ? 'A·A' : `A${supI(i)}·A`}`)); P = Q; } return w; }, cube(a) * (k - 1))]) : set(k === 2 ? 'Square it' : 'Cube it'); }
          if (x.op === 'fact') return set('Factorial');
          return set('Degrees to radians', 'Multiply by π/180.');
        }
        case 'pow': {
          const a = val(x.a), b = val(x.b);
          if (isMat(a) && isNum(b)) { const k = Math.round(b); if (k === -1) return set('Inverse', null, inverseMethods(a)); if (k === 0) return set('Raise to the power 0', 'Any square matrix to the power 0 is the identity.'); return set(`Raise to the power ${k}`, k < 0 ? `The inverse multiplied by itself ${-k} times.` : `The matrix multiplied by itself ${k} times.`); }
          return set('Raise to the power');
        }
        case 'neg': return isMat(v) ? set('Change every sign', 'Every entry is multiplied by −1.') : set('Change the sign');
        case 'bars': { const a = val(x.a); return isMat(a) ? set('Determinant', null, a.rows === a.cols ? detMethods(a) : []) : set('Absolute value'); }
        case 'lit': return set('Put the results in a matrix', 'Each entry has been worked out in the steps above.');
        case 'bin': {
          const l = val(x.a), r = val(x.b), plus = x.op === '+';
          if (x.op === '+' || x.op === '-') {
            if (isMat(l) && isMat(r)) return set(plus ? 'Add the matrices' : 'Subtract the matrices', `Entries in the same position are ${plus ? 'added' : 'subtracted'}.`, [method('Entry by entry', () => entries(v, (i, j) => `${nT(l.data[i][j])} ${plus ? '+' : '−'} ${fT(r.data[i][j])}`), v.rows * v.cols)]);
            if (isEye(l) || isEye(r)) {
              const k = isEye(l) ? l.s : r.s, what = k === 1 ? 'I' : `${nT(k)}I`, m = isMat(l) ? l : r;
              return set(plus ? `Add ${what}` : `Subtract ${what}`, `${what} is ${nT(k)} down the diagonal and 0 elsewhere, so only the diagonal entries change.`, [method('Down the diagonal', () => m.data.map((_, i) => W.math(`c${ix(i, i)} = ${isMat(l) ? nT(m.data[i][i]) : nT(k)} ${plus ? '+' : '−'} ${fT(isMat(l) ? k : m.data[i][i])} = ${nT(v.data[i][i])}`)))]);
            }
            return set(plus ? 'Add' : 'Subtract');
          }
          if (x.op === '*') {
            if (isMat(l) && isMat(r)) return set('Multiply the matrices', 'Entry (i, j) is row i of the left matrix times column j of the right one.', [method('Entry by entry', () => mulWork(l, r), l.rows * r.cols * l.cols)]);
            if (isMat(l) || isMat(r)) { const k = isMat(l) ? r : l, kt = isEye(k) ? nT(k.s) : nT(k); return set(`Multiply every entry by ${kt}`, isEye(k) && k.s === 1 ? 'Multiplying by I leaves a matrix unchanged.' : null); }
            return set('Multiply');
          }
          if (x.op === '/') {
            if (isMat(r)) return set('Divide by a matrix', 'Dividing by a matrix means multiplying by its inverse on the right.', [method('Working', () => [W.matrix(cleanM(inverse(r)), 'The inverse of the divisor'), W.text(isMat(l) ? 'Then multiply the left matrix by this inverse.' : 'Then multiply every entry by the number.')])]);
            if (isMat(l)) return set(`Divide every entry by ${nT(r)}`);
            return set('Divide');
          }
          return set('Multiply entry by entry', isMat(l) && isMat(r) ? FN_NOTE.hadamard : null);
        }
        default: return set('Work it out');
      }
    }
    return { steps, walk, isAtom };
  }
  const steps0 = steps;

  /* (k·M)·N reads as k·(M·N): the matrices are multiplied first, then every
     entry is scaled — the order the app shows. */
  function reassoc(n, memo) {
    const c = Object.assign({}, n);
    if (n.a) c.a = reassoc(n.a, memo);
    if (n.b) c.b = reassoc(n.b, memo);
    if (n.args) c.args = n.args.map((x) => reassoc(x, memo));
    if (n.rows) c.rows = n.rows.map((r) => r.map((x) => reassoc(x, memo)));
    memo.set(c, memo.get(n));
    if (c.k === 'bin' && c.op === '*' && c.a.k === 'bin' && c.a.op === '*') {
      const k = memo.get(c.a.a), M = memo.get(c.a.b), N2 = memo.get(c.b);
      if (isNum(k) && isMat(M) && isMat(N2) && M.cols === N2.rows) {
        const right = { k: 'bin', op: '*', a: c.a.b, b: c.b };
        memo.set(right, mulM(M, N2));
        const top = { k: 'bin', op: '*', a: c.a.a, b: right };
        memo.set(top, memo.get(n));
        return top;
      }
    }
    return c;
  }

  function explain(text, env = {}) {
    const ctx = { vars: env.vars || {}, angle: env.angle || 'rad', warnings: [], memo: new Map() };
    try {
      const a = splitAssignment(text), body = a ? a.body : text;
      if (!body.trim()) return null;
      const tree = parse(body, FUNCS, ctx.vars);
      const v = evalNode(tree, ctx);
      if (isEye(v)) return null;
      const t2 = reassoc(tree, ctx.memo);
      const ex = Explainer(ctx);
      ex.walk(t2, true, false);
      return { expr: show(tree, ctx.vars), tex: tex(tree, ctx.vars), value: tidy(v), steps: ex.steps, assign: a ? a.name : null };
    } catch (e) { return null; }
  }
  function hasSteps(text, env = {}) {
    try {
      const a = splitAssignment(text), body = a ? a.body : text;
      if (!body.trim()) return false;
      const tree = parse(body, FUNCS, env.vars || {});
      return !Explainer({ vars: env.vars || {}, memo: new Map() }).isAtom(tree);
    } catch (e) { return false; }
  }

  global.MatEngine = {
    evaluate, evalScalar, splitAssignment, describe, plain, isMat, isNum,
    mat, zeros, eye, transpose, mulM, det, inverse, rank, traceOf, eigenvalues, charpoly,
    lu, qr, svd, cholesky, frob, norm1, normInf, norm2, cond, properties, steps, isSymmetric,
    FUNCS, RESERVED,
    explain, hasSteps, texValue, texNum, exprTex,
  };
})(window);
