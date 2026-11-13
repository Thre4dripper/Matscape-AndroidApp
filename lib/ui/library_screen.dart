import 'package:material_ui/material_ui.dart';

import 'icons.dart';
import 'scope.dart';
import 'theme.dart';
import 'widgets.dart';

class _Op {
  const _Op(
    this.group,
    this.syntax,
    this.ins,
    this.back,
    this.desc, [
    this.keywords = '',
  ]);
  final String group, syntax, ins, desc, keywords;
  final int back;

  String get haystack => '$syntax $desc $keywords $group'.toLowerCase();
}

const _ops = [
  _Op(
    'Basics',
    'A + B,  A − B',
    '+',
    0,
    'Add or subtract matrices of the same size',
  ),
  _Op(
    'Basics',
    'kA',
    '·',
    0,
    'Scale every entry by a number',
    'scalar multiply',
  ),
  _Op(
    'Basics',
    'AB  or  A·B',
    '·',
    0,
    'Matrix product — columns of A must match rows of B',
    'multiply product',
  ),
  _Op(
    'Basics',
    'A / B',
    '/',
    0,
    'Right division, worked out as A·B⁻¹',
    'divide division',
  ),
  _Op('Basics', 'Aᵀ', 'ᵀ', 0, 'Transpose — rows become columns', 'transpose'),
  _Op(
    'Basics',
    'A⁻¹',
    '⁻¹',
    0,
    'Inverse of a square, non-singular matrix',
    'inverse',
  ),
  _Op(
    'Basics',
    'Aⁿ',
    '^',
    0,
    'Whole-number powers; negative powers use the inverse',
    'power exponent',
  ),
  _Op(
    'Basics',
    'A ∘ B',
    '∘',
    0,
    'Entrywise (Hadamard) product',
    'hadamard elementwise',
  ),
  _Op(
    'Basics',
    '[1, 2; 3, 4]',
    '[]',
    1,
    'Write a matrix inline — “,” between entries, “;” between rows',
    'literal inline',
  ),
  _Op(
    'Basics',
    'k = 3',
    'k = ',
    0,
    'Name a value and reuse it in other lines',
    'variable assign name',
  ),
  _Op(
    'Measures',
    'det(A)  or  |A|',
    'det()',
    1,
    'Determinant of a square matrix',
    'determinant',
  ),
  _Op('Measures', 'tr(A)', 'tr()', 1, 'Trace — sum of the diagonal', 'trace'),
  _Op(
    'Measures',
    'rank(A)',
    'rank()',
    1,
    'Number of independent rows or columns',
  ),
  _Op('Measures', 'norm(A)', 'norm()', 1, 'Frobenius norm', 'magnitude'),
  _Op(
    'Measures',
    'norm1(A),  norminf(A)',
    'norm1()',
    1,
    'Largest column sum, largest row sum',
  ),
  _Op(
    'Measures',
    'norm2(A)',
    'norm2()',
    1,
    'Spectral norm — the largest singular value',
  ),
  _Op(
    'Measures',
    'cond(A)',
    'cond()',
    1,
    'Condition number — how sensitive A is to rounding',
    'condition',
  ),
  _Op(
    'Build',
    'I(n)',
    'I()',
    1,
    'n×n identity. Bare I adapts to its neighbour: A − 2I',
    'identity',
  ),
  _Op(
    'Build',
    'zeros(m, n),  ones(m, n)',
    'zeros()',
    1,
    'Matrix of zeros or ones',
  ),
  _Op(
    'Build',
    'diag(v)',
    'diag()',
    1,
    'Diagonal matrix from a vector, or the diagonal of a matrix',
  ),
  _Op(
    'Build',
    'aug(A, B)',
    'aug()',
    1,
    'Place B to the right of A',
    'augment concatenate',
  ),
  _Op(
    'Build',
    'sub(A, i, j)',
    'sub()',
    1,
    'Submatrix without row i and column j',
    'submatrix',
  ),
  _Op(
    'Build',
    'row(A, i),  column(A, j)',
    'row()',
    1,
    'Pull out one row or one column',
  ),
  _Op('Build', 'kron(A, B)', 'kron()', 1, 'Kronecker product', 'tensor'),
  _Op('Cofactors', 'minors(A)', 'minors()', 1, 'Matrix of minors'),
  _Op('Cofactors', 'cof(A)', 'cof()', 1, 'Cofactor matrix', 'cofactor'),
  _Op(
    'Cofactors',
    'adj(A)',
    'adj()',
    1,
    'Adjugate (classical adjoint)',
    'adjoint adjugate',
  ),
  _Op(
    'Systems',
    'rref(A)',
    'rref()',
    1,
    'Reduced row echelon form — with steps in Inspect',
    'echelon gauss jordan',
  ),
  _Op(
    'Systems',
    'solve(A, b)',
    'solve()',
    1,
    'Solve Ax = b, including systems with free variables',
    'equation linear system',
  ),
  _Op(
    'Systems',
    'null(A)',
    'null()',
    1,
    'Basis for the null space (kernel)',
    'kernel nullspace',
  ),
  _Op(
    'Systems',
    'colsp(A)',
    'colsp()',
    1,
    'Basis for the column space (range)',
    'range column space',
  ),
  _Op(
    'Systems',
    'pinv(A)',
    'pinv()',
    1,
    'Moore–Penrose pseudo-inverse',
    'pseudo inverse least squares',
  ),
  _Op(
    'Systems',
    'dot(u, v),  cross(u, v)',
    'dot()',
    1,
    'Dot product; cross product of 3-vectors',
    'vector',
  ),
  _Op(
    'Decompose',
    'lu(A)',
    'lu()',
    1,
    'PA = LU with partial pivoting',
    'lu decomposition factorization',
  ),
  _Op(
    'Decompose',
    'qr(A)',
    'qr()',
    1,
    'A = QR, Q orthogonal and R upper triangular',
    'qr decomposition',
  ),
  _Op(
    'Decompose',
    'chol(A)',
    'chol()',
    1,
    'A = LLᵀ for symmetric positive definite A',
    'cholesky',
  ),
  _Op(
    'Decompose',
    'svd(A)',
    'svd()',
    1,
    'A = UΣVᵀ, singular value decomposition',
    'singular',
  ),
  _Op(
    'Eigen',
    'eig(A)',
    'eig()',
    1,
    'Eigenvalues, including complex ones',
    'eigenvalue spectrum',
  ),
  _Op(
    'Eigen',
    'eigvec(A)',
    'eigvec()',
    1,
    'Eigenvectors grouped by eigenvalue',
    'eigenvector',
  ),
  _Op(
    'Eigen',
    'charpoly(A)',
    'charpoly()',
    1,
    'Characteristic polynomial det(λI − A)',
    'characteristic polynomial',
  ),
  _Op(
    'Matrix functions',
    'expm(A)',
    'expm()',
    1,
    'Matrix exponential eᴬ',
    'exponential',
  ),
  _Op(
    'Matrix functions',
    'sinm(A),  cosm(A)',
    'sinm()',
    1,
    'Matrix sine and cosine',
    'trig',
  ),
  _Op(
    'Matrix functions',
    'sqrtm(A)  or  A^0.5',
    'sqrtm()',
    1,
    'Principal matrix square root',
    'root',
  ),
  _Op(
    'Trig & scalar',
    'sin, cos, tan',
    'sin()',
    1,
    'On a matrix, these apply to every entry',
    'trigonometry',
  ),
  _Op(
    'Trig & scalar',
    'sec, csc, cot',
    'sec()',
    1,
    'Reciprocal trig functions',
    'trigonometry',
  ),
  _Op(
    'Trig & scalar',
    'asin, acos, atan',
    'asin()',
    1,
    'Inverse trig — answers follow the RAD/DEG setting',
    'arcsin arccos arctan inverse trigonometry',
  ),
  _Op(
    'Trig & scalar',
    'sinh, cosh, tanh',
    'sinh()',
    1,
    'Hyperbolic functions',
    'hyperbolic',
  ),
  _Op(
    'Trig & scalar',
    'sin(30°)',
    '°',
    0,
    'Mark any angle in degrees, whatever the setting',
    'degree angle',
  ),
  _Op(
    'Trig & scalar',
    'ln, log, exp',
    'ln()',
    1,
    'Natural log, log base 10, eˣ',
    'logarithm',
  ),
  _Op(
    'Trig & scalar',
    '√x,  ∛x,  n!',
    '√',
    0,
    'Roots and factorial',
    'sqrt root factorial',
  ),
  _Op(
    'Trig & scalar',
    'abs, round, floor, ceil, mod',
    'abs()',
    1,
    'Rounding and remainders',
    'absolute modulo',
  ),
];

final _groups = [
  'All',
  ...{for (final o in _ops) o.group},
];

/// Searchable list of every operation; tapping one types it into the
/// active line.
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key, required this.host});
  final WorkspaceHost host;

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _query = TextEditingController();
  final _queryFocus = FocusNode();
  String _group = 'All';

  @override
  void dispose() {
    _query.dispose();
    _queryFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final tokens = _query.text
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
    final items = [
      for (final o in _ops)
        if ((_group == 'All' || o.group == _group) &&
            tokens.every(o.haystack.contains))
          o,
    ];
    final groups = {for (final o in items) o.group};

    return SubScreen(
      title: 'Operations',
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          0,
          8,
          0,
          32 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const FieldLabel('Search operations'),
                InputBox(
                  icon: MIcon.search,
                  controller: _query,
                  focusNode: _queryFocus,
                  hint: 'inverse, eigen, sin…',
                  onChanged: (_) => setState(() {}),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              itemCount: _groups.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => ChipBtn(
                _groups[i],
                on: _groups[i] == _group,
                onTap: () => setState(() => _group = _groups[i]),
              ),
            ),
          ),
          if (items.isEmpty)
            EmptyState(
              icon: MIcon.search,
              title: 'No operations match “${_query.text}”',
              body: 'Try a shorter word like “inv”, “eig” or “trig”, or clear the filter.',
              action: Btn(
                'Clear search',
                expand: false,
                onTap: () {
                  setState(() {
                    _query.clear();
                    _group = 'All';
                  });
                  _queryFocus.requestFocus();
                },
              ),
            ),
          for (final g in groups)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GroupTitle(g),
                  CardBox(
                    child: DividedColumn(
                      children: [
                        for (final o in items.where((o) => o.group == g))
                          RowTap(
                            minHeight: 0,
                            onTap: () {
                              Navigator.of(context).pop();
                              widget.host.insertText(o.ins, back: o.back);
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  o.syntax,
                                  style: mathStyle(context, size: Fs.lg),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  o.desc,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.45,
                                    color: pal.ink2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      text,
      style: TextStyle(
        fontSize: Fs.sm,
        fontWeight: FontWeight.w600,
        color: context.pal.ink2,
      ),
    ),
  );
}

/// Bordered single-line text input with a leading icon. Uses the system
/// keyboard (unlike the math fields).
class InputBox extends StatefulWidget {
  const InputBox({
    super.key,
    required this.icon,
    required this.controller,
    this.focusNode,
    this.hint = '',
    this.maxLength,
    this.onChanged,
  });
  final MIcon icon;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hint;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  @override
  State<InputBox> createState() => _InputBoxState();
}

class _InputBoxState extends State<InputBox> {
  FocusNode? _own;
  FocusNode get _node => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _node.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _node.removeListener(_refresh);
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal, focused = _node.hasFocus;
    return AnimatedContainer(
      duration: Motion.fast,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: pal.surface,
        border: Border.all(color: focused ? pal.accent : pal.lineStrong),
        borderRadius: BorderRadius.circular(12),
        boxShadow: focused
            ? [BoxShadow(color: pal.accentSoft, spreadRadius: 3)]
            : null,
      ),
      child: Row(
        children: [
          Ico(widget.icon, size: 18, color: pal.ink3),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _node,
              maxLines: 1,
              maxLength: widget.maxLength,
              autocorrect: false,
              cursorColor: pal.accent,
              textInputAction: TextInputAction.done,
              style: TextStyle(fontSize: Fs.body, color: pal.ink),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                counterText: '',
                hintText: widget.hint,
                hintStyle: TextStyle(fontSize: Fs.body, color: pal.ink3),
              ),
              onChanged: widget.onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
