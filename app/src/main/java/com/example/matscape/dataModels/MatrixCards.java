package com.example.matscape.dataModels;

import java.util.List;

public class MatrixCards {

    String matrixName;
    List<List<String>> matrix;
    int matrixRows,matrixColumns;
    double textSize;
    int height,width;

    public MatrixCards(String matrixName, List<List<String>> matrix, int matrixRows, int matrixColumns, double textSize, int height, int width) {
        this.matrixName = matrixName;
        this.matrix = matrix;
        this.matrixRows = matrixRows;
        this.matrixColumns = matrixColumns;
        this.textSize = textSize;
        this.height = height;
        this.width = width;
    }

    public String getMatrixName() {
        return matrixName;
    }

    public List<List<String>> getMatrix() {
        return matrix;
    }

    public int getMatrixRows() {
        return matrixRows;
    }

    public int getMatrixColumns() {
        return matrixColumns;
    }

    public double getTextSize() {
        return textSize;
    }

    public int getHeight() {
        return height;
    }

    public int getWidth() {
        return width;
    }
}
