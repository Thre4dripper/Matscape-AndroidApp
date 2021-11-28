package com.example.matscape.dataModels;

import java.util.List;

public class MatrixCards {

    String matrixName;
    List<List<String>> matrix;
    int matrixRows, matrixColumns;
    int height;

    public MatrixCards(String matrixName, List<List<String>> matrix, int matrixRows, int matrixColumns, int height) {
        this.matrixName = matrixName;
        this.matrix = matrix;
        this.matrixRows = matrixRows;
        this.matrixColumns = matrixColumns;
        this.height = height;
    }

    public String getMatrixName() {
        return matrixName;
    }

    public void setMatrixName(String matrixName) {
        this.matrixName = matrixName;
    }

    public List<List<String>> getMatrix() {
        return matrix;
    }

    public void setMatrix(List<List<String>> matrix) {
        this.matrix = matrix;
    }

    public int getMatrixRows() {
        return matrixRows;
    }

    public void setMatrixRows(int matrixRows) {
        this.matrixRows = matrixRows;
    }

    public int getMatrixColumns() {
        return matrixColumns;
    }

    public void setMatrixColumns(int matrixColumns) {
        this.matrixColumns = matrixColumns;
    }

    public int getHeight() {
        return height;
    }

}
