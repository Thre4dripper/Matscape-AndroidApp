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
     * ============================================ METHOD FOR MULTIPLYING TWO MATRICES =============================================================
     **/
    @Nullable
    public static List<List<String>> matrixMultiply(@NonNull List<List<String>> A, @NonNull List<List<String>> B) {
        List<List<String>> result = new ArrayList<>();

        int rows1 = A.size(), cols1 = A.get(0).size();
        int rows2 = B.size(), cols2 = B.get(0).size();
        double currentElementA, currentElementB;
        double currentElementResult;

        if (cols1 == rows2)
            for (int i = 0; i < cols2; i++) {
                result.add(new ArrayList<>());
                for (int j = 0; j < rows1; j++) {
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

    @Nullable
    public static List<List<String>> Power(List<List<String>> A, double power) {
        List<List<String>> result = A;

        for (int i = 0; i < power - 1; i++) {
            result = matrixMultiply(A, result);
            if (result == null)
                return null;
        }
        return result;
    }
}
