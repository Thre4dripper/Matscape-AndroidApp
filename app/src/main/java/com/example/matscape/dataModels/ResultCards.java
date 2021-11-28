package com.example.matscape.dataModels;

import android.text.SpannableStringBuilder;

import java.util.List;

public class ResultCards {

    SpannableStringBuilder expressionString;
    StringBuilder calculationString;
    int cursorPosition;
    String message;
    List<List<String>> resultMatrix;
    int matrixRows,matrixColumns;
    double textSize;
    String highlightedColor;

    public ResultCards(SpannableStringBuilder expressionString,StringBuilder calculationString,int cursorPosition, String message, List<List<String>> resultMatrix,
                       int matrixRows, int matrixColumns, double textSize, String highlightedColor) {
        this.expressionString = expressionString;
        this.calculationString=calculationString;
        this.cursorPosition=cursorPosition;
        this.message = message;
        this.resultMatrix = resultMatrix;
        this.matrixRows = matrixRows;
        this.matrixColumns = matrixColumns;
        this.textSize = textSize;
        this.highlightedColor=highlightedColor;
    }

    public SpannableStringBuilder getExpressionString() {
        return expressionString;
    }

    public void setExpressionString(SpannableStringBuilder expressionString) {
        this.expressionString = expressionString;
    }

    public StringBuilder getCalculationString() {
        return calculationString;
    }

    public void setCalculationString(StringBuilder calculationString) {
        this.calculationString = calculationString;
    }

    public int getCursorPosition() {
        return cursorPosition;
    }

    public void setCursorPosition(int cursorPosition) {
        this.cursorPosition = cursorPosition;
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

    public String getHighlightedColor() {
        return highlightedColor;
    }

    public void setHighlightedColor(String highlightedColor) {
        this.highlightedColor = highlightedColor;
    }
}
