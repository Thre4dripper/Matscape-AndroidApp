package com.ByteMechanics.matscape.models;

import android.text.SpannableStringBuilder;

import java.util.List;

public class ResultCards {

    SpannableStringBuilder expressionString;
    int cursorPosition;
    StringBuilder calculationString;
    List<Integer> calculationStringIndexList;
    String message;
    List<List<String>> resultMatrix;
    int matrixRows, matrixColumns;
    String highlightedColor;

    public ResultCards(SpannableStringBuilder expressionString, int cursorPosition, StringBuilder calculationString,
                       List<Integer> calculationStringIndexList, String message, List<List<String>> resultMatrix,
                       int matrixRows, int matrixColumns, String highlightedColor) {
        this.expressionString = expressionString;
        this.cursorPosition = cursorPosition;
        this.calculationString = calculationString;
        this.calculationStringIndexList = calculationStringIndexList;
        this.message = message;
        this.resultMatrix = resultMatrix;
        this.matrixRows = matrixRows;
        this.matrixColumns = matrixColumns;
        this.highlightedColor = highlightedColor;
    }

    public SpannableStringBuilder getExpressionString() {
        return expressionString;
    }

    public void setExpressionString(SpannableStringBuilder expressionString) {
        this.expressionString = expressionString;
    }

    public int getCursorPosition() {
        return cursorPosition;
    }

    public void setCursorPosition(int cursorPosition) {
        this.cursorPosition = cursorPosition;
    }

    public StringBuilder getCalculationString() {
        return calculationString;
    }

    public void setCalculationString(StringBuilder calculationString) {
        this.calculationString = calculationString;
    }

    public List<Integer> getCalculationStringIndexList() {
        return calculationStringIndexList;
    }

    public void setCalculationStringIndexList(List<Integer> calculationStringIndexList) {
        this.calculationStringIndexList = calculationStringIndexList;
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

    public String getHighlightedColor() {
        return highlightedColor;
    }

    public void setHighlightedColor(String highlightedColor) {
        this.highlightedColor = highlightedColor;
    }
}
