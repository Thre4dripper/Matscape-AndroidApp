package com.example.matscape.Utils;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.List;

public class MatrixOperations {
    /**
     * ============================================ METHOD FOR SCALAR MULTIPLY OF MATRIX =============================================================
     **/
    @NonNull
    public static List<List<String>> ScalarMultiply(@NonNull List<List<String>> A, double scalar) {
        List<List<String>> result = new ArrayList<>();

        int rows = A.size();
        int columns = A.get(0).size();
        double currentElement;

        for (int i = 0; i < rows; i++) {
            result.add(new ArrayList<>());
            for (int j = 0; j < columns; j++) {
                currentElement = Double.parseDouble(A.get(i).get(j));
                result.get(i).add(String.valueOf(currentElement * scalar));
            }
        }

        return result;
    }

    /**
     * ============================================ METHOD FOR SCALAR DIVIDE OF MATRIX =============================================================
     **/
    @NonNull
    public static List<List<String>> ScalarDivide(@NonNull List<List<String>> A, double scalar) {
        List<List<String>> result = new ArrayList<>();

        int rows = A.size();
        int columns = A.get(0).size();
        double currentElement;

        for (int i = 0; i < rows; i++) {
            result.add(new ArrayList<>());
            for (int j = 0; j < columns; j++) {
                currentElement = Double.parseDouble(A.get(i).get(j));
                result.get(i).add(String.valueOf(currentElement / scalar));
            }
        }

        return result;
    }

    /**
     * ============================================ METHOD FOR ADDITION OF MATRICES =============================================================
     **/
    @Nullable
    public static List<List<String>> matrixAddition(@NonNull List<List<String>> A, @NonNull List<List<String>> B) {
        List<List<String>> result = new ArrayList<>();

        int rows1 = A.size(), cols1 = A.get(0).size();
        int rows2 = B.size(), cols2 = B.get(0).size();
        double currentElementA, currentElementB;

        if (rows1 == rows2 && cols1 == cols2)
            for (int i = 0; i < cols2; i++) {
                result.add(new ArrayList<>());
                for (int j = 0; j < rows1; j++) {
                    currentElementA = Double.parseDouble(A.get(i).get(j));
                    currentElementB = Double.parseDouble(B.get(i).get(j));
                    result.get(i).add(String.valueOf(currentElementA + currentElementB));
                }
            }
        else {
            return null;
        }

        return result;
    }

    /**
     * ============================================ METHOD FOR SUBTRACTION OF MATRICES =============================================================
     **/
    @Nullable
    public static List<List<String>> matrixSubtraction(@NonNull List<List<String>> A, @NonNull List<List<String>> B) {
        List<List<String>> result = new ArrayList<>();

        int rows1 = A.size(), cols1 = A.get(0).size();
        int rows2 = B.size(), cols2 = B.get(0).size();
        double currentElementA, currentElementB;

        if (rows1 == rows2 && cols1 == cols2)
            for (int i = 0; i < cols2; i++) {
                result.add(new ArrayList<>());
                for (int j = 0; j < rows1; j++) {
                    currentElementA = Double.parseDouble(A.get(i).get(j));
                    currentElementB = Double.parseDouble(B.get(i).get(j));
                    result.get(i).add(String.valueOf(currentElementA - currentElementB));
                }
            }
        else {
            return null;
        }

        return result;
    }

    /**
     * ============================================ METHOD FOR MULTIPLICATION OF MATRICES =============================================================
     **/
    @Nullable
    public static List<List<String>> matrixMultiply(@NonNull List<List<String>> A, @NonNull List<List<String>> B) {
        List<List<String>> result = new ArrayList<>();

        int rows1 = A.size(), cols1 = A.get(0).size();
        int rows2 = B.size(), cols2 = B.get(0).size();
        double currentElementA, currentElementB;
        double currentElementResult;

        if (cols1 == rows2)
            for (int i = 0; i < rows1; i++) {
                result.add(new ArrayList<>());
                for (int j = 0; j < cols2; j++) {
                    result.get(i).add("0.0");
                    for (int k = 0; k < cols1; k++) {
                        currentElementA = Double.parseDouble(A.get(i).get(k));
                        currentElementB = Double.parseDouble(B.get(k).get(j));
                        currentElementResult = Double.parseDouble(result.get(i).get(j));
                        result.get(i).set(j, String.valueOf((currentElementA * currentElementB) + currentElementResult));
                    }
                }
            }
        else {
            return null;
        }

        return result;
    }

    /**
     * ============================================ METHOD FOR POWER OF MATRIX =============================================================
     **/
    @Nullable
    public static List<List<String>> matrixPower(List<List<String>> A, double power) {
        List<List<String>> result = A;

        for (int i = 0; i < power - 1; i++) {
            result = matrixMultiply(A, result);
            if (result == null)
                return null;
        }
        return result;
    }

    /**
     * ============================================ METHOD FOR DETERMINANT OF MATRIX =============================================================
     **/
    public static double determinant(@NonNull List<List<String>> A) {
        if (A.size() == 1)
            return Double.parseDouble(A.get(0).get(0));
        else if (A.size() == 2)
            return (Double.parseDouble(A.get(0).get(0)) * Double.parseDouble(A.get(1).get(1)))
                    - (Double.parseDouble(A.get(0).get(1)) * Double.parseDouble(A.get(1).get(0)));
        double det = 0;
        for (int i = 0; i < A.size(); i++) {
            List<List<String>> B = new ArrayList<>();
            for (int j = 1; j < A.size(); j++) {
                B.add(new ArrayList<>());
                for (int k = 0; k < A.size(); k++)
                    if (k != i)
                        B.get(j - 1).add(A.get(j).get(k));
            }
            det += Math.pow(-1, i) * Double.parseDouble(A.get(0).get(i)) * determinant(B);
        }
        return det;
    }

    /**
     * ================================= METHOD FOR CALCULATING MINOR OF MATRIX ==============================
     **/
    public static double minors(@NonNull List<List<String>> A, int rows, int cols) {
        List<List<String>> B = new ArrayList<>();
        int n = A.size();
        int i1 = 0, j1 = 0;

        for (int i = 0; i < n - 1; i++) {
            B.add(new ArrayList<>());
            for (int j = 0; j < n - 1; j++)
                B.get(i).add("0.0");
        }

        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                if (i != rows && j != cols) {
                    B.get(i1).set(j1, A.get(i).get(j));

                    if (j1 == n - 2) {
                        if (i1 == n - 2)
                            i1 = 0;
                        else i1++;
                        j1 = 0;
                    } else j1++;

                }

            }
        }
        return determinant(B);
    }

    /**
     * ================================= METHOD FOR GENERATING MINOR  MATRIX =====================================
     **/
    @NonNull
    public static List<List<String>> minorMatrix(@NonNull List<List<String>> A) {
        List<List<String>> B = new ArrayList<>();
        int n = A.size();

        //for 1x1 matrix returning Null matrix
        if (n == 1) return B;

        for (int i = 0; i < n; i++) {
            B.add(new ArrayList<>());
            for (int j = 0; j < n; j++)
                B.get(i).add("0.0");
        }

        for (int i = 0; i < n; i++) {
            for (int j = 0; j < n; j++) {
                B.get(i).set(j, String.valueOf(minors(A, i, j)));
            }
        }

        return B;
    }

    /**
     * ================================ METHOD FOR GENERATING COFACTOR MATRIX ======================================
     **/
    @NonNull
    public static List<List<String>> cofactorMatrix(@NonNull List<List<String>> A) {
        List<List<String>> B = new ArrayList<>();
        for (int i = 0; i < A.size(); i++) {
            B.add(new ArrayList<>());
            for (int j = 0; j < A.size(); j++)
                B.get(i).add(String.valueOf(Math.pow(-1, i + j) * minors(A, i, j)));
        }
        return B;
    }

    /**
     * ================================== METHOD FOR GENERATING ADJOINT  MATRIX ==================================
     **/
    @NonNull
    public static List<List<String>> adjoint(@NonNull List<List<String>> A) {
        List<List<String>> B = new ArrayList<>();
        int n = A.size();

        //for 1x1 matrix returning Null matrix
        if (n == 1) return B;

        B = cofactorMatrix(A);

        return B;
    }

    /**
     * ====================================== METHOD FOR GENERATING INVERSE  MATRIX ===============================
     **/
    @Nullable
    public static List<List<String>> inverse(List<List<String>> A, int n) {
        List<List<String>> B = new ArrayList<>();

        if (determinant(A) != 0) {
            if (n == 1) return B;

            B = adjoint(A);

            for (int i = 0; i < n; i++) {
                for (int j = 0; j < n; j++) {
                    B.get(i).set(j, String.valueOf(Double.parseDouble(B.get(i).get(j)) / determinant(A)));
                }
            }
        } else {
            return null;
        }

        return B;
    }
}
