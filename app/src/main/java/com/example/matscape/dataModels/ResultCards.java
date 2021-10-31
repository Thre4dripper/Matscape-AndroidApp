package com.example.matscape.dataModels;

import java.util.List;

public class ResultCards {

    List<String> expression;
    String message;
    List<List<String>> resultMatrix;
    int matrixRows,matrixColumns;
    double textSize;

    public ResultCards(List<String> expression, String message, List<List<String>> resultMatrix, int matrixRows, int matrixColumns, double textSize) {
        this.expression = expression;
        this.message = message;
        this.resultMatrix = resultMatrix;
        this.matrixRows = matrixRows;
        this.matrixColumns = matrixColumns;
        this.textSize = textSize;
    }

    public List<String> getExpression() {
        return expression;
    }

    public void setExpression(List<String> expression) {
        this.expression = expression;
    }

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }

    public List<List<String>> getResultMatrix() {
        return resultMatrix;
    }

    public void setResultMatrix(List<List<String>> resultMatrix) {
        this.resultMatrix = resultMatrix;
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

    public double getTextSize() {
        return textSize;
    }

    public void setTextSize(double textSize) {
        this.textSize = textSize;
    }
}
