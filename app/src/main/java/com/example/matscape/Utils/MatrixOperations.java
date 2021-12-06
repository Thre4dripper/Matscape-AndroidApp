package com.example.matscape.Utils;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.List;

public class MatrixOperations {
    /**============================================ METHOD FOR SCALAR MULTIPLY OF MATRIX =============================================================**/
    @NonNull
    public static List<List<String>> ScalarMultiply(@NonNull List<List<String>> A, double scalar){
        List<List<String>> result=new ArrayList<>();

        int rows=A.size();
        int columns=A.get(0).size();

        for(int i=0;i<rows;i++){
            result.add(new ArrayList<>());
            for(int j=0;j<columns;j++){
                result.get(i).add(String.valueOf(Double.parseDouble(A.get(i).get(j))*scalar));
            }
        }

        return result;
    }

    /**============================================ METHOD FOR SCALAR DIVIDE OF MATRIX =============================================================**/
    @NonNull
    public static List<List<String>> ScalarDivide(@NonNull List<List<String>> A, double scalar){
        List<List<String>> result=new ArrayList<>();

        int rows=A.size();
        int columns=A.get(0).size();

        for(int i=0;i<rows;i++){
            result.add(new ArrayList<>());
            for(int j=0;j<columns;j++){
                result.get(i).add(String.valueOf(Double.parseDouble(A.get(i).get(j))/scalar));
            }
        }

        return result;
    }
}
