/// One entry in the operations library: the row in the list and the page
/// that explains it.
class Op {
  const Op(
    this.group,
    this.title,
    this.syntax,
    this.ins,
    this.back,
    this.desc,
    this.about,
    this.examples, {
    this.more = const [],
    this.notes = const [],
    this.keywords = '',
    this.sample,
    this.inlineOnly = false,
  });

  final String group;

  /// Plain-language name, the heading of the page.
  final String title;

  /// How it is written, shown in the maths font.
  final String syntax;

  /// What "Insert" types into the active line, and how far the caret
  /// steps back afterwards (to land inside brackets).
  final String ins;
  final int back;

  /// One line for the list.
  final String desc;

  /// The explanation on the page. Blank lines separate paragraphs.
  final String about;

  /// Further sections for the harder topics, as (heading, text): what the
  /// parts of a result are, how to read it, why it is useful.
  final List<(String, String)> more;

  /// Self-contained expressions, shown with their results. "Try it" adds
  /// them to the workspace. Later ones may use names set by earlier ones.
  final List<String> examples;

  /// Requirements and tips, shown as a list.
  final List<String> notes;
  final String keywords;

  /// Sample workspace to point to, when it isn't the group's usual one.
  final String? sample;

  /// The page is about typing matrices inline, so its examples are not
  /// also shown with named matrices.
  final bool inlineOnly;

  String get haystack => '$title $syntax $desc $keywords $group'.toLowerCase();

  /// Name of the sample workspace that covers this operation.
  String get sampleName => sample ?? samplesByGroup[group]!;
}

/// The sample workspace (see `seedWorkspaces`) that goes with each group.
const samplesByGroup = {
  'Basics': 'Basics — add, multiply, transpose',
  'Measures': 'Determinant, trace, rank & norms',
  'Build': 'Building matrices',
  'Cofactors': 'Minors, cofactors & adjugate',
  'Systems': 'Linear systems',
  'Decompose': 'Decompositions — LU, QR, Cholesky, SVD',
  'Eigen': 'Eigenvalues & eigenvectors',
  'Matrix functions': 'Matrix functions — expm, sinm, sqrtm',
  'Trig & scalar': 'Numbers, fractions & exact results',
};

const ops = [
  /* ---------- basics ---------- */
  Op(
    'Basics',
    'Add and subtract',
    'A + B,  A − B',
    '+',
    0,
    'Add or subtract matrices of the same size',
    'Adding two matrices adds the entries that sit in the same place, and '
        'subtracting works the same way. The result has the same size as the '
        'two matrices you started with.',
    ['[1, 2; 3, 4] + [5, 6; 7, 8]', '[1, 2; 3, 4] − 2I'],
    notes: [
      'Both matrices must have the same number of rows and columns.',
      'A number can’t be added to a matrix. To shift the diagonal, use the '
          'identity matrix, as in A − 2I.',
    ],
    keywords: 'sum difference plus minus',
  ),
  Op(
    'Basics',
    'Multiply by a number',
    '3A  or  k·A',
    '·',
    0,
    'Scale every entry by a number',
    'Multiplying a matrix by a number multiplies every entry by it. Write '
        'the number in front of the matrix. Dividing a matrix by a number '
        'divides every entry.',
    ['3[1, 2; 3, 4]', '[2, 4; 6, 8] / 2'],
    notes: [
      'A number can sit right against a matrix: 3A.',
      'A named value needs the dot: k·A. Written together, kA is read as '
          'one name.',
    ],
    keywords: 'scalar multiply scale',
  ),
  Op(
    'Basics',
    'Matrix product',
    'AB  or  A·B',
    '·',
    0,
    'Matrix product — columns of A must match rows of B',
    'The product AB combines each row of A with each column of B: the entry '
        'in row i, column j is the dot product of row i of A and column j of '
        'B. An m×n matrix times an n×p matrix gives an m×p matrix.',
    ['[1, 2; 3, 4]·[0, 1; 1, 0]', '[1, 2, 3]·[4; 5; 6]'],
    notes: [
      'The number of columns of A must equal the number of rows of B.',
      'Order matters: AB and BA are usually different, and one can exist '
          'when the other doesn’t.',
      'Capital letters written together are multiplied, so BA means B·A.',
    ],
    keywords: 'multiply product times',
  ),
  Op(
    'Basics',
    'Division',
    'A / B',
    '/',
    0,
    'Right division, worked out as A·B⁻¹',
    'Matrices can’t be divided the way numbers can. Matscape reads A / B as '
        'A multiplied by the inverse of B, that is A·B⁻¹.',
    ['[2, 4; 6, 8] / [1, 0; 0, 2]'],
    notes: [
      'B must be square and invertible.',
      'To solve A·x = b, solve(A, b) is more direct than dividing.',
    ],
    keywords: 'divide division quotient',
  ),
  Op(
    'Basics',
    'Transpose',
    'Aᵀ',
    'ᵀ',
    0,
    'Transpose — rows become columns',
    'The transpose flips a matrix over its main diagonal: row 1 becomes '
        'column 1, row 2 becomes column 2, and so on. An m×n matrix becomes '
        'n×m.',
    ['[1, 2, 3; 4, 5, 6]ᵀ'],
    notes: [
      'A matrix that equals its own transpose is called symmetric.',
      'On a hardware keyboard, an apostrophe types the transpose.',
    ],
    keywords: 'transpose flip',
  ),
  Op(
    'Basics',
    'Inverse',
    'A⁻¹',
    '⁻¹',
    0,
    'Inverse of a square, non-singular matrix',
    'The inverse A⁻¹ undoes A: multiplying A by A⁻¹, in either order, gives '
        'the identity matrix. It plays the part that 1/a plays for numbers.',
    ['[4, 7; 2, 6]⁻¹', '[4, 7; 2, 6]·[4, 7; 2, 6]⁻¹'],
    more: [
      (
        'For a 2×2 matrix',
        'Take a matrix with rows (a, b) and (c, d). Swap a and d, change the '
            'signs of b and c, and divide every entry by the determinant, '
            'which is a times d minus b times c.\n\n'
            'In the first example the determinant is 4 × 6 − 7 × 2 = 10.',
      ),
    ],
    notes: [
      'Only square matrices with a non-zero determinant have an inverse.',
      'For a singular or non-square matrix, pinv(A) is the closest '
          'substitute.',
      'Inspect shows the inverse worked out step by step.',
    ],
    keywords: 'inverse invert reciprocal',
  ),
  Op(
    'Basics',
    'Powers',
    'A²,  A^n',
    '^',
    0,
    'Whole-number powers; negative powers use the inverse',
    'A² means A·A, A³ means A·A·A, and so on. A negative power uses the '
        'inverse, so A⁻² is the inverse multiplied by itself, and A to the '
        'power 0 is the identity.',
    ['[1, 1; 0, 1]^5', '[2, 0; 0, 4]^−1'],
    notes: [
      'The matrix must be square.',
      'Type ^ followed by the power.',
      'Powers are whole numbers, with one exception: A^0.5 is the matrix '
          'square root.',
    ],
    keywords: 'power exponent square cube',
  ),
  Op(
    'Basics',
    'Entrywise product',
    'A ∘ B',
    '∘',
    0,
    'Entrywise (Hadamard) product',
    'The entrywise product multiplies each entry of A by the entry of B in '
        'the same place. It is not the matrix product, which combines rows '
        'with columns. It is also called the Hadamard product.',
    ['[1, 2; 3, 4] ∘ [5, 6; 7, 8]'],
    notes: ['Both matrices must be the same size.'],
    keywords: 'hadamard elementwise schur',
  ),
  Op(
    'Basics',
    'Inline matrix',
    '[1, 2; 3, 4]',
    '[]',
    1,
    'Write a matrix inline — “,” between entries, “;” between rows',
    'You can write a matrix straight into an expression without saving it '
        'first. Put the entries in square brackets, with a comma between '
        'entries and a semicolon between rows.\n\n'
        'So [1, 2; 3, 4] has the rows 1 2 and 3 4. The examples on the '
        'other pages are shown both ways: with named matrices, and typed '
        'in one line like this.',
    ['[1, 2; 3, 4]', '[1, 2, 3]', '[1; 2; 3]', '[cos(60°), √4; 1/2, 2²]'],
    notes: [
      'Entries can be expressions: fractions, roots, trig.',
      'One row makes a row vector, [1, 2, 3]. One column is [1; 2; 3].',
      'Tap “Save” under a matrix result to keep it as a named matrix.',
    ],
    keywords: 'literal inline vector brackets',
    inlineOnly: true,
  ),
  Op(
    'Basics',
    'Named values',
    'k = 3',
    'k = ',
    0,
    'Name a value and reuse it in other lines',
    'Give any result a name by writing the name, an equals sign and the '
        'expression. You can then use that name in the other lines of the '
        'workspace, and they update whenever it changes.',
    ['k = 3', 'k·[1, 2; 3, 4]'],
    notes: [
      'A name starts with a letter and can be a whole word, such as total.',
      'It can’t be the name of one of your matrices, or a built-in name '
          'such as I, e or sin.',
      'Order doesn’t matter: a name can be used above the line that sets it.',
    ],
    keywords: 'variable assign name store equals',
  ),

  /* ---------- measures ---------- */
  Op(
    'Measures',
    'Determinant',
    'det(A)  or  |A|',
    'det()',
    1,
    'Determinant of a square matrix',
    'The determinant is a single number that says how a square matrix '
        'scales area or volume. If it is zero, the matrix squashes space '
        'flat: it is singular and has no inverse.\n\n'
        'For a 2×2 matrix with rows (a, b) and (c, d), it is a times d '
        'minus b times c. In the first example that is 2 × 3 − 1 × 1 = 5.',
    ['det([2, 1; 1, 3])', '|[1, 2; 2, 4]|'],
    notes: [
      'Only square matrices have a determinant.',
      'It can also be written with bars: |A|.',
      'A negative determinant means the matrix also flips orientation, as '
          'a mirror does.',
      'Inspect shows the determinant worked out step by step.',
    ],
    keywords: 'determinant singular',
  ),
  Op(
    'Measures',
    'Trace',
    'tr(A)',
    'tr()',
    1,
    'Trace — sum of the diagonal',
    'The trace is the sum of the entries on the main diagonal. It also '
        'equals the sum of the eigenvalues.',
    ['tr([1, 2; 3, 4])'],
    notes: ['The matrix must be square.'],
    keywords: 'trace diagonal sum',
  ),
  Op(
    'Measures',
    'Rank',
    'rank(A)',
    'rank()',
    1,
    'Number of independent rows or columns',
    'The rank is the number of rows that are truly independent — the ones '
        'that can’t be built from the others. Counting independent columns '
        'gives the same number.\n\n'
        'In the first example the second row is twice the first, so only '
        'one row counts and the rank is 1.',
    ['rank([1, 2; 2, 4])', 'rank([1, 2; 3, 4])'],
    notes: [
      'A square matrix is invertible exactly when its rank equals its size.',
      'It is the number of non-zero rows left after row reduction, rref(A).',
      'The rank plus the number of vectors in null(A) equals the number of '
          'columns.',
    ],
    keywords: 'rank independent',
  ),
  Op(
    'Measures',
    'Frobenius norm',
    'norm(A)',
    'norm()',
    1,
    'Frobenius norm',
    'A norm measures the size of a matrix as one number. The Frobenius norm '
        'squares every entry, adds them up and takes the square root. For a '
        'vector that is its ordinary length.',
    ['norm([3, 4])', 'norm([1, 2; 3, 4])'],
    keywords: 'magnitude length size euclidean',
  ),
  Op(
    'Measures',
    'Column and row norms',
    'norm1(A),  norminf(A)',
    'norm1()',
    1,
    'Largest column sum, largest row sum',
    'norm1 adds up the absolute values in each column and returns the '
        'largest total. norminf does the same with the rows.',
    ['norm1([1, −2; 3, 4])', 'norminf([1, −2; 3, 4])'],
    keywords: 'one infinity norm column row sum',
  ),
  Op(
    'Measures',
    'Spectral norm',
    'norm2(A)',
    'norm2()',
    1,
    'Spectral norm — the largest singular value',
    'The spectral norm is the most a matrix can stretch a vector. It equals '
        'the largest singular value.',
    ['norm2([3, 0; 0, 4])'],
    notes: ['svd(A) gives all the singular values.'],
    keywords: 'two norm singular stretch',
  ),
  Op(
    'Measures',
    'Condition number',
    'cond(A)',
    'cond()',
    1,
    'Condition number — how sensitive A is to rounding',
    'The condition number says how much a small change in the input, such '
        'as a rounding error, can grow when you solve with this matrix. 1 is '
        'ideal; a large value means the answer should be read with care.',
    ['cond([1, 2; 3, 4])', 'cond([1, 2; 2, 4])'],
    more: [
      (
        'How to read it',
        'Think of it as an error multiplier. With a condition number of '
            '1000, an error in the fourth decimal place of the input can '
            'show up in the first decimal place of the answer.\n\n'
            'It is the largest singular value divided by the smallest, so '
            'it measures how unevenly the matrix stretches different '
            'directions. A singular matrix flattens some direction '
            'completely, and its condition number is infinite.',
      ),
    ],
    keywords: 'condition sensitivity stability',
  ),

  /* ---------- build ---------- */
  Op(
    'Build',
    'Identity matrix',
    'I(n)',
    'I()',
    1,
    'n×n identity. Bare I adapts to its neighbour: A − 2I',
    'The identity matrix has ones on the diagonal and zeros everywhere '
        'else. Multiplying by it changes nothing, like multiplying a number '
        'by 1.',
    ['I(3)', '[2, 1; 1, 3] − 2I'],
    notes: [
      'I(n) gives the n×n identity.',
      'A bare I takes whatever size its neighbour needs, so A − 2I works '
          'for any square A.',
    ],
    keywords: 'identity unit eye',
  ),
  Op(
    'Build',
    'Zeros and ones',
    'zeros(m, n),  ones(m, n)',
    'zeros()',
    1,
    'Matrix of zeros or ones',
    'zeros(m, n) builds a matrix with m rows and n columns filled with '
        'zeros, and ones(m, n) one filled with ones. With a single number '
        'you get a square matrix.',
    ['zeros(2, 3)', 'ones(2)'],
    notes: ['Sizes up to 64 are supported.'],
    keywords: 'zero one fill empty',
  ),
  Op(
    'Build',
    'Diagonal',
    'diag(v)',
    'diag()',
    1,
    'Diagonal matrix from a vector, or the diagonal of a matrix',
    'Given a vector, diag builds a square matrix with those values on the '
        'diagonal and zeros elsewhere. Given a matrix, it does the opposite '
        'and returns the diagonal as a column.',
    ['diag([1, 2, 3])', 'diag([1, 2; 3, 4])'],
    keywords: 'diagonal',
  ),
  Op(
    'Build',
    'Augment',
    'aug(A, B)',
    'aug()',
    1,
    'Place B to the right of A',
    'aug places B to the right of A to make one wider matrix. Its usual job '
        'is the augmented matrix [A | b] of a linear system, ready for row '
        'reduction.',
    ['aug([1, 2; 3, 4], [5; 6])', 'rref(aug([2, 1; 1, 3], [3; 5]))'],
    notes: ['A and B need the same number of rows.'],
    keywords: 'augment concatenate join append',
  ),
  Op(
    'Build',
    'Submatrix',
    'sub(A, i, j)',
    'sub()',
    1,
    'Submatrix without row i and column j',
    'sub(A, i, j) removes row i and column j from A and returns what is '
        'left. The determinant of that smaller matrix is the minor used in '
        'cofactor expansion.',
    ['sub([1, 2, 3; 4, 5, 6; 7, 8, 9], 1, 1)'],
    notes: ['Rows and columns are counted from 1.'],
    keywords: 'submatrix delete remove minor',
  ),
  Op(
    'Build',
    'Rows and columns',
    'row(A, i),  column(A, j)',
    'row()',
    1,
    'Pull out one row or one column',
    'row(A, i) returns row i of a matrix as a row vector, and column(A, j) '
        'returns column j as a column vector.',
    ['row([1, 2; 3, 4], 2)', 'column([1, 2; 3, 4], 1)'],
    notes: ['Rows and columns are counted from 1.'],
    keywords: 'row column extract vector',
  ),
  Op(
    'Build',
    'Kronecker product',
    'kron(A, B)',
    'kron()',
    1,
    'Kronecker product',
    'The Kronecker product builds one large matrix out of two smaller '
        'ones. Every entry of the first matrix is replaced by a whole copy '
        'of the second matrix multiplied by that entry, so the result is a '
        'grid of blocks.\n\n'
        'In the example the first matrix has the entries 1, 2, 3 and 4, so '
        'the result is made of four blocks: 1 times the second matrix, 2 '
        'times it, 3 times it and 4 times it.',
    ['kron([1, 2; 3, 4], [1, 0; 0, 1])'],
    notes: [
      'A matrix with m rows and n columns and one with p rows and q '
          'columns give m × p rows and n × q columns.',
      'Order matters: kron(A, B) and kron(B, A) arrange the same numbers '
          'differently.',
      'The result can have up to 64 rows and columns.',
    ],
    keywords: 'tensor kronecker block',
  ),

  /* ---------- cofactors ---------- */
  Op(
    'Cofactors',
    'Matrix of minors',
    'minors(A)',
    'minors()',
    1,
    'Matrix of minors',
    'The minor of an entry is the determinant of what is left after '
        'deleting that entry’s row and column. minors(A) works this out for '
        'every entry and returns the results as a matrix.',
    ['minors([1, 2, 3; 0, 1, 4; 5, 6, 0])'],
    notes: ['The matrix must be square.'],
    keywords: 'minor',
  ),
  Op(
    'Cofactors',
    'Cofactor matrix',
    'cof(A)',
    'cof()',
    1,
    'Cofactor matrix',
    'A cofactor is a minor with a sign attached: plus where row + column is '
        'even, minus where it is odd, in a chessboard pattern. Cofactors are '
        'what you multiply by when expanding a determinant along a row or '
        'column.',
    ['cof([1, 2, 3; 0, 1, 4; 5, 6, 0])'],
    notes: ['The matrix must be square.'],
    keywords: 'cofactor sign',
  ),
  Op(
    'Cofactors',
    'Adjugate',
    'adj(A)',
    'adj()',
    1,
    'Adjugate (classical adjoint)',
    'The adjugate is the transpose of the cofactor matrix. Dividing it by '
        'the determinant gives the inverse: A⁻¹ = adj(A) / det(A).',
    ['adj([1, 2; 3, 4])', 'adj([1, 2; 3, 4]) / det([1, 2; 3, 4])'],
    notes: ['It is also called the classical adjoint.'],
    keywords: 'adjoint adjugate',
  ),

  /* ---------- systems ---------- */
  Op(
    'Systems',
    'Row reduction',
    'rref(A)',
    'rref()',
    1,
    'Reduced row echelon form — with steps in Inspect',
    'Row reduction uses three moves — swap two rows, multiply a row by a '
        'number, add a multiple of one row to another — until every leading '
        'entry is 1 with zeros above and below it. The result is the '
        'reduced row echelon form.\n\n'
        'These moves never change the solutions of the system the matrix '
        'stands for, which is why the answer can be read straight from the '
        'result.',
    ['rref([1, 2, 3; 4, 5, 6; 7, 8, 10])', 'rref(aug([2, 1; 1, 3], [3; 5]))'],
    more: [
      (
        'How to read the result',
        'The first non-zero entry of each row is a 1, called a pivot. The '
            'number of pivots is the rank.\n\n'
            'For an augmented matrix [A | b], the last column is the '
            'answer when every column of A has a pivot — as in the second '
            'example, where x = 4/5 and y = 7/5.\n\n'
            'A column of A without a pivot is a free variable: the system '
            'has infinitely many solutions. A row that reads 0 … 0 | 1 '
            'says 0 = 1: the system has no solution.',
      ),
    ],
    notes: [
      'To solve a system, augment first: rref(aug(A, b)).',
      'Inspect lists every row operation in order.',
    ],
    keywords: 'echelon gauss jordan elimination reduce',
  ),
  Op(
    'Systems',
    'Solve a system',
    'solve(A, b)',
    'solve()',
    1,
    'Solve Ax = b, including systems with free variables',
    'solve(A, b) finds the x for which A·x = b. If there is exactly one '
        'solution you get it. If there are infinitely many you get one of '
        'them, with a note. If there are none, Matscape says so.',
    ['solve([2, 1; 1, 3], [3; 5])', 'solve([1, 2; 2, 4], [3; 6])'],
    notes: [
      'b needs as many rows as A.',
      'With infinitely many solutions, add any multiple of null(A) to get '
          'the others.',
      'With no solution, pinv(A)·b gives the least-squares best fit.',
    ],
    keywords: 'equation linear system unknowns',
  ),
  Op(
    'Systems',
    'Null space',
    'null(A)',
    'null()',
    1,
    'Basis for the null space (kernel)',
    'The null space is every vector x that the matrix sends to zero: '
        'A·x = 0. null(A) returns a basis for it — a few vectors, as '
        'columns, from which all the others can be built by scaling and '
        'adding.\n\n'
        'In the first example the answer is (−2, 1): take −2 of the first '
        'column of the matrix and 1 of the second, and they cancel.',
    ['null([1, 2; 2, 4])', 'null([1, 2, 3; 4, 5, 6])'],
    more: [
      (
        'Why it matters',
        'If A·x = b has one solution, every other solution is that one '
            'plus something from the null space. So the null space is '
            'exactly the freedom the solutions have.\n\n'
            'When only the zero vector is sent to zero, the columns of A '
            'are independent and a solution, if there is one, is the only '
            'one. Matscape says so instead of returning a vector.',
      ),
    ],
    notes: [
      'The number of basis vectors is the number of columns minus the rank.',
      'It is also called the kernel.',
    ],
    keywords: 'kernel nullspace homogeneous',
  ),
  Op(
    'Systems',
    'Column space',
    'colsp(A)',
    'colsp()',
    1,
    'Basis for the column space (range)',
    'The column space is everything A·x can produce: all the combinations '
        'of the columns of A. colsp(A) returns a basis for it, chosen from '
        'the columns of A.\n\n'
        'In the example the second column is twice the first, so one '
        'column is enough to describe everything the matrix can reach.',
    ['colsp([1, 2; 2, 4])'],
    notes: [
      'A·x = b has a solution exactly when b lies in the column space.',
      'The number of basis vectors is the rank.',
      'It is also called the range or the image.',
    ],
    keywords: 'range image column space span',
  ),
  Op(
    'Systems',
    'Pseudo-inverse',
    'pinv(A)',
    'pinv()',
    1,
    'Moore–Penrose pseudo-inverse',
    'Many matrices have no inverse: they are not square, or they are '
        'singular. The pseudo-inverse is the best available substitute, and '
        'every matrix has exactly one. For an invertible matrix it is the '
        'ordinary inverse.',
    ['pinv([1, 2; 2, 4])', 'pinv([1; 2; 3])'],
    more: [
      (
        'What pinv(A)·b gives you',
        'For the system A·x = b:\n\n'
            'If there is exactly one solution, it gives that solution.\n\n'
            'If there is no solution, it gives the least-squares answer: '
            'the x that brings A·x as close to b as possible. This is how '
            'a line is fitted through points that don’t lie exactly on '
            'one.\n\n'
            'If there are infinitely many solutions, it gives the shortest '
            'one.',
      ),
      (
        'How it is built',
        'From the singular value decomposition, svd(A). Where A stretches '
            'a direction, the pseudo-inverse shrinks it back by the same '
            'amount. Where A flattens a direction to nothing, there is '
            'nothing to undo, and the pseudo-inverse leaves it at zero.',
      ),
    ],
    notes: ['Its full name is the Moore–Penrose pseudo-inverse.'],
    keywords: 'pseudo inverse least squares moore penrose',
  ),
  Op(
    'Systems',
    'Dot and cross product',
    'dot(u, v),  cross(u, v)',
    'dot()',
    1,
    'Dot product; cross product of 3-vectors',
    'The dot product multiplies the matching entries of two vectors and '
        'adds them up; it is zero when the vectors are perpendicular. The '
        'cross product of two 3-vectors is a third vector perpendicular to '
        'both.',
    ['dot([1; 2; 3], [4; 5; 6])', 'cross([1; 0; 0], [0; 1; 0])'],
    notes: [
      'The vectors can be rows or columns, with the same number of entries.',
      'The cross product needs exactly three entries in each vector.',
    ],
    keywords: 'vector inner scalar perpendicular',
    sample: 'Vectors — dot and cross',
  ),

  /* ---------- decompose ---------- */
  Op(
    'Decompose',
    'LU decomposition',
    'lu(A)',
    'lu()',
    1,
    'PA = LU with partial pivoting',
    'LU decomposition rewrites a square matrix as a product of two '
        'triangular matrices. It is what Gaussian elimination produces if '
        'you keep a record of every step instead of throwing it away.',
    ['lu([4, 3; 6, 3])'],
    more: [
      (
        'What the three matrices are',
        'L is lower triangular: every entry above its diagonal is zero, '
            'and the diagonal is all ones. Below the diagonal it keeps the '
            'multipliers that elimination used to clear each column.\n\n'
            'U is upper triangular: every entry below its diagonal is zero. '
            'It is the matrix that elimination ends with.\n\n'
            'P is a permutation matrix: an identity matrix with its rows in '
            'a different order. It records the row swaps made along the '
            'way, which keep the arithmetic accurate.\n\n'
            'Together they satisfy P·A = L·U. In the example the two rows '
            'were swapped, which is why P is not the identity.',
      ),
      (
        'Why it is useful',
        'Triangular systems are easy to solve, one unknown at a time. Once '
            'A is factored, A·x = b becomes two quick steps: solve '
            'L·y = P·b, then U·x = y. The same L and U work for any number '
            'of right-hand sides b.\n\n'
            'The determinant comes with it: multiply the diagonal of U, and '
            'change the sign once for every row swap.',
      ),
    ],
    notes: [
      'The matrix must be square.',
      'Tap any of the matrices in the result to inspect it.',
      'A result with several parts can’t be used inside a larger '
          'expression, so keep lu on its own line.',
    ],
    keywords: 'lu decomposition factorization triangular gaussian',
  ),
  Op(
    'Decompose',
    'QR decomposition',
    'qr(A)',
    'qr()',
    1,
    'A = QR, Q orthogonal and R upper triangular',
    'QR decomposition writes a matrix as A = Q·R: a matrix Q whose columns '
        'are perpendicular unit vectors, times an upper-triangular matrix '
        'R.',
    ['qr([3, 1; 4, 2])'],
    more: [
      (
        'What the two matrices are',
        'Q is orthogonal: its columns are perpendicular to one another and '
            'each has length 1. Multiplying by Q never stretches anything '
            '— it only rotates or reflects — and its inverse is simply its '
            'transpose.\n\n'
            'R is upper triangular: every entry below its diagonal is zero. '
            'It says how to rebuild each column of A from the columns of '
            'Q.\n\n'
            'The columns of Q are made from the columns of A, straightened '
            'one after another so that each is perpendicular to the ones '
            'before it. That is the Gram–Schmidt process. In the example '
            'the first column of A is (3, 4), which has length 5, so the '
            'first column of Q is (3/5, 4/5).',
      ),
      (
        'Why it is useful',
        'QR is the standard way to solve least-squares problems, such as '
            'fitting a line through points that don’t lie exactly on one. '
            'Because Q doesn’t distort lengths, the problem reduces to a '
            'triangular system in R.\n\n'
            'Repeating QR again and again is also how computers find '
            'eigenvalues.',
      ),
    ],
    notes: [
      'A doesn’t have to be square.',
      'Tap either matrix in the result to inspect it.',
    ],
    keywords: 'qr decomposition orthogonal gram schmidt least squares',
  ),
  Op(
    'Decompose',
    'Cholesky decomposition',
    'chol(A)',
    'chol()',
    1,
    'A = LLᵀ for symmetric positive definite A',
    'Cholesky decomposition writes a symmetric positive definite matrix as '
        'A = L·Lᵀ: a lower-triangular matrix times its own transpose. It is '
        'the matrix version of a square root.',
    ['chol([4, 2; 2, 3])'],
    more: [
      (
        'Which matrices it works for',
        'Symmetric means the matrix equals its transpose. Positive definite '
            'means every eigenvalue is positive.\n\n'
            'Matrices of the form Aᵀ·A, where the columns of A are '
            'independent, are always like this. So are the covariance '
            'matrices used in statistics.',
      ),
      (
        'Why it is useful',
        'For these matrices it does the job of LU in about half the work, '
            'and it never needs row swaps.\n\n'
            'It is also the quickest test for positive definiteness: if the '
            'matrix isn’t positive definite the factorisation fails, and '
            'Matscape says what is wrong.',
      ),
    ],
    notes: ['Lower triangular: every entry above the diagonal is zero.'],
    keywords: 'cholesky positive definite symmetric',
  ),
  Op(
    'Decompose',
    'Singular value decomposition',
    'svd(A)',
    'svd()',
    1,
    'A = UΣVᵀ, singular value decomposition',
    'The singular value decomposition writes any matrix, square or not, as '
        'A = U·Σ·Vᵀ. It shows that every matrix, however complicated it '
        'looks, does three simple things in a row: turn, stretch, turn.',
    ['svd([3, 0; 0, 4])', 'svd([2, 2; −1, 1])'],
    more: [
      (
        'What the three matrices are',
        'Vᵀ turns the input — a rotation or a reflection — so that the '
            'directions the matrix treats most simply line up with the '
            'axes.\n\n'
            'Σ is diagonal. It stretches each axis by a singular value. '
            'Singular values are never negative, and they are listed '
            'largest first.\n\n'
            'U turns the stretched result into its final position.',
      ),
      (
        'How to read it',
        'The number of non-zero singular values is the rank. A singular '
            'value of zero means a whole direction is flattened to '
            'nothing.\n\n'
            'The largest singular value is the most the matrix can stretch '
            'any vector, which is norm2(A). The largest divided by the '
            'smallest is the condition number, cond(A).',
      ),
      (
        'Why it is useful',
        'Keeping only the largest few singular values gives the best '
            'approximation of a matrix by a simpler one. That is the idea '
            'behind image compression, noise removal and principal '
            'component analysis.\n\n'
            'The pseudo-inverse, pinv(A), is built from it too.',
      ),
    ],
    notes: ['Tap any of the three matrices in the result to inspect it.'],
    keywords: 'singular value svd pca compression',
  ),

  /* ---------- eigen ---------- */
  Op(
    'Eigen',
    'Eigenvalues',
    'eig(A)',
    'eig()',
    1,
    'Eigenvalues, including complex ones',
    'Most vectors change direction when a matrix multiplies them. An '
        'eigenvector is one that doesn’t: A·v lies along the same line as '
        'v, only longer, shorter or reversed. The factor it is scaled by is '
        'the eigenvalue λ, so A·v = λ·v.\n\n'
        'eig(A) lists every eigenvalue of the matrix.',
    ['eig([4, 1; 2, 3])', 'eig([0, −1; 1, 0])'],
    more: [
      (
        'How to read them',
        'A matrix with n rows and n columns has n eigenvalues, counting '
            'repeats.\n\n'
            'A real eigenvalue is a stretch factor along its eigenvector: '
            'more than 1 stretches, between 0 and 1 shrinks, a negative one '
            'flips, and 0 means the matrix is singular.\n\n'
            'Complex eigenvalues come in pairs and mean the matrix '
            'rotates. The second example is a quarter turn: it leaves no '
            'line where it was, so it has no real eigenvalue.',
      ),
      (
        'Why they matter',
        'Eigenvalues describe what happens when a matrix is applied again '
            'and again: whether something grows, dies away or oscillates. '
            'They give the natural frequencies of a vibrating structure, '
            'the stability of a system of differential equations, and the '
            'long-run behaviour of a Markov chain.',
      ),
    ],
    notes: [
      'The matrix must be square.',
      'Their sum is the trace and their product is the determinant.',
      'They are the roots of the characteristic polynomial, charpoly(A).',
    ],
    keywords: 'eigenvalue spectrum lambda',
  ),
  Op(
    'Eigen',
    'Eigenvectors',
    'eigvec(A)',
    'eigvec()',
    1,
    'Eigenvectors grouped by eigenvalue',
    'For each eigenvalue λ, the eigenvectors are the directions that the '
        'matrix leaves on their own line, only scaling them by λ. '
        'eigvec(A) returns them grouped by eigenvalue.\n\n'
        'In the example, multiplying the matrix by (1, 1) gives (5, 5): the '
        'same direction, five times as long.',
    ['eigvec([4, 1; 2, 3])'],
    more: [
      (
        'Diagonalising a matrix',
        'Suppose a matrix with n rows and columns has n independent '
            'eigenvectors. Put them side by side as the columns of a '
            'matrix P, and put the eigenvalues on the diagonal of a matrix '
            'D. Then A = P·D·P⁻¹.\n\n'
            'This makes powers easy: a power of A is P times the same '
            'power of D times P⁻¹, and a power of D just raises each '
            'eigenvalue to that power.',
      ),
    ],
    notes: [
      'Any multiple of an eigenvector is also an eigenvector, so the scale '
          'shown is a choice.',
      'Eigenvectors are given for real eigenvalues. eig(A) still lists '
          'complex ones.',
    ],
    keywords: 'eigenvector direction diagonalise',
  ),
  Op(
    'Eigen',
    'Characteristic polynomial',
    'charpoly(A)',
    'charpoly()',
    1,
    'Characteristic polynomial det(λI − A)',
    'The characteristic polynomial is det(λI − A), written out as a '
        'polynomial in λ. Setting it equal to zero and solving gives the '
        'eigenvalues.',
    ['charpoly([4, 1; 2, 3])', 'eig([4, 1; 2, 3])'],
    more: [
      (
        'How it connects',
        'For a 2×2 matrix it is always λ² minus the trace times λ plus the '
            'determinant. In the example the trace is 7 and the '
            'determinant is 10.\n\n'
            'It factors as (λ − 5)(λ − 2), so the eigenvalues are 5 and 2, '
            'which is what the second example shows.',
      ),
    ],
    notes: ['The matrix must be square.'],
    keywords: 'characteristic polynomial roots',
  ),

  /* ---------- matrix functions ---------- */
  Op(
    'Matrix functions',
    'Matrix exponential',
    'expm(A)',
    'expm()',
    1,
    'Matrix exponential, e to the power A',
    'For a number, eˣ = 1 + x + x²/2! + x³/3! + … The matrix exponential '
        'uses the same series with a square matrix in place of x: '
        'I + A + A²/2! + A³/3! + … The result is a matrix of the same size.',
    ['expm([1, 0; 0, 2])', 'expm([0, −π; π, 0])'],
    more: [
      (
        'Not the same as exp',
        'exp(A) raises e to each entry on its own. expm(A) uses matrix '
            'powers, so the entries mix.\n\n'
            'For a diagonal matrix, expm raises e to each diagonal entry '
            'and leaves the zeros alone, as the first example shows.',
      ),
      (
        'Why it is useful',
        'It solves systems of linear differential equations. If the rate '
            'of change of x is A·x, then x at time t is expm(t·A) times x '
            'at the start.\n\n'
            'The second example is a rotation. Its matrix describes '
            'turning at π radians per unit of time, and the exponential is '
            'the result after one unit: half a turn, which is −I.',
      ),
    ],
    notes: ['The matrix must be square.'],
    keywords: 'exponential differential',
  ),
  Op(
    'Matrix functions',
    'Matrix sine and cosine',
    'sinm(A),  cosm(A)',
    'sinm()',
    1,
    'Matrix sine and cosine',
    'Matrix sine and cosine use the same power series as sin and cos, with '
        'matrix powers in place of numbers. They are not sin(A) and cos(A), '
        'which work entry by entry.',
    ['sinm([0, 1; 1, 0])', 'cosm([0, 1; 1, 0])'],
    notes: ['As with numbers, sinm(A)² + cosm(A)² is the identity.'],
    keywords: 'trig sine cosine',
  ),
  Op(
    'Matrix functions',
    'Matrix square root',
    'sqrtm(A)  or  A^0.5',
    'sqrtm()',
    1,
    'Principal matrix square root',
    'The matrix square root is a matrix that gives A when multiplied by '
        'itself. sqrtm(A) returns the principal one. It is not the square '
        'root of each entry.',
    ['sqrtm([5, 4; 4, 5])', 'sqrtm([5, 4; 4, 5])²'],
    notes: [
      'A^0.5 means the same thing.',
      'A needs to have no zero or negative eigenvalues.',
    ],
    keywords: 'root square',
  ),

  /* ---------- trig & scalar ---------- */
  Op(
    'Trig & scalar',
    'Sine, cosine, tangent',
    'sin, cos, tan',
    'sin()',
    1,
    'On a matrix, these apply to every entry',
    'The three basic trigonometric functions. An angle is read in radians '
        'or degrees according to the RAD/DEG setting; add ° to a number to '
        'make it degrees whatever the setting. Results stay exact where '
        'they can, such as 1/2.',
    ['sin(30°)', 'tan(45°)', 'cos([0°, 60°; 90°, 180°])'],
    notes: [
      'On a matrix they apply to every entry. For the true matrix sine and '
          'cosine use sinm and cosm.',
    ],
    keywords: 'trigonometry sine cosine tangent',
  ),
  Op(
    'Trig & scalar',
    'Secant, cosecant, cotangent',
    'sec, csc, cot',
    'sec()',
    1,
    'Reciprocal trig functions',
    'The reciprocal functions: sec x = 1 / cos x, csc x = 1 / sin x and '
        'cot x = 1 / tan x.',
    ['sec(60°)', 'csc(30°)', 'cot(45°)'],
    keywords: 'trigonometry reciprocal secant cosecant cotangent',
  ),
  Op(
    'Trig & scalar',
    'Inverse trig',
    'asin, acos, atan',
    'asin()',
    1,
    'Inverse trig — answers follow the RAD/DEG setting',
    'The inverse functions give back the angle: asin(1/2) is the angle '
        'whose sine is 1/2. The answer is in radians or degrees, following '
        'the RAD/DEG setting.',
    ['asin(1/2)', 'acos(0)', 'atan(1)'],
    notes: ['asin and acos take values from −1 to 1.'],
    keywords: 'arcsin arccos arctan inverse trigonometry angle',
  ),
  Op(
    'Trig & scalar',
    'Hyperbolic functions',
    'sinh, cosh, tanh',
    'sinh()',
    1,
    'Hyperbolic functions',
    'The hyperbolic functions are built from eˣ: sinh x = (eˣ − e⁻ˣ) / 2, '
        'cosh x = (eˣ + e⁻ˣ) / 2 and tanh x = sinh x / cosh x. They don’t '
        'use the angle setting.',
    ['sinh(1)', 'cosh(0)', 'tanh(1)'],
    keywords: 'hyperbolic',
  ),
  Op(
    'Trig & scalar',
    'Degrees',
    'sin(30°)',
    '°',
    0,
    'Mark any angle in degrees, whatever the setting',
    'Put ° after a number to say it is in degrees, whatever the RAD/DEG '
        'setting is. It is handy for one-off angles and inside matrix '
        'entries, such as a rotation by 30°.',
    ['sin(30°)', 'cos(60°) + sin(30°)'],
    keywords: 'degree angle radians',
    sample: 'Trig inside matrices',
  ),
  Op(
    'Trig & scalar',
    'Logarithms and exponential',
    'ln, log, exp',
    'ln()',
    1,
    'Natural log, log base 10, eˣ',
    'ln is the natural logarithm (base e), log is the logarithm base 10, '
        'and exp(x) is e raised to the power x. The constant e can also be '
        'typed on its own.',
    ['ln(e²)', 'log(1000)', 'exp(1)'],
    notes: ['Logarithms need a positive number.'],
    keywords: 'logarithm natural exponential euler',
  ),
  Op(
    'Trig & scalar',
    'Roots and factorial',
    '√x,  ∛x,  n!',
    '√',
    0,
    'Roots and factorial',
    '√ is the square root and ∛ the cube root; each applies to the number '
        'or bracket that follows it. n! multiplies the whole numbers from 1 '
        'up to n. Square roots stay exact where they can: √8 is shown as '
        '2√2.',
    ['√8', '∛27', '5!'],
    notes: ['A number in front multiplies: 2√3.'],
    keywords: 'sqrt cbrt root factorial surd',
  ),
  Op(
    'Trig & scalar',
    'Rounding and remainders',
    'abs, round, floor, ceil, mod',
    'abs()',
    1,
    'Rounding and remainders',
    'abs removes the sign. round goes to the nearest whole number, floor '
        'always goes down and ceil always goes up. mod(a, b) is the '
        'remainder when a is divided by b.',
    ['abs(−7)', 'round(2.6)', 'mod(17, 5)'],
    keywords: 'absolute modulo remainder round floor ceiling',
  ),
];

final opGroups = [
  'All',
  ...{for (final o in ops) o.group},
];
