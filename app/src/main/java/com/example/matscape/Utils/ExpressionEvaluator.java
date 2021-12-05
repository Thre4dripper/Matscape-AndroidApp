package com.example.matscape.Utils;

import androidx.annotation.NonNull;

import com.example.matscape.Controllers.MatrixCardsController;
import com.example.matscape.Controllers.ResultCardsController;

import java.util.ArrayList;
import java.util.List;
import java.util.Stack;

public class ExpressionEvaluator {
    private static final String TAG = "ExpressionEvaluator";

    /**
     * ================================== MASTER FUNCTION FOR EVALUATING EXPRESSION =========================
     **/
    public static void EvaluateExpression(@NonNull String postfixExpression, int selectedCard) {
        Stack<List<List<String>>> stack = new Stack<>();
        int flag = 0;
        char currentChar;
        List<List<String>> number;
        for (int i = 0; i < postfixExpression.length(); i++) {
            currentChar = postfixExpression.charAt(i);

            if (Character.isDigit(currentChar) || currentChar == '.') {
                if (flag == 0) {
                    number = new ArrayList<>();
                    number.add(new ArrayList<>());
                    number.get(0).add(String.valueOf(currentChar));

                    stack.push(number);
                    flag = 1;
                } else {
                    number = stack.pop();
                    number.get(0).set(0, number.get(0).get(0) + currentChar);
                    stack.push(number);
                }
            } else if (currentChar == ' ')
                flag = 0;

            else if (Character.isUpperCase(currentChar))
                stack.push(getCurrentMatrix(currentChar));

            else if (currentChar == '+' || currentChar == '-' || currentChar == '•' || currentChar == '/' || currentChar == '^') {
                List<List<String>> num1 = stack.pop();
                List<List<String>> num2 = stack.pop();
                List<List<String>> result = new ArrayList<>();
                result.add(new ArrayList<>());
                switch (currentChar) {
                    case '+':
                        result.get(0).add(String.valueOf(Double.parseDouble(num2.get(0).get(0)) + Double.parseDouble(num1.get(0).get(0))));
                        stack.push(result);
                        break;
                    case '-':
                        result.get(0).add(String.valueOf(Double.parseDouble(num2.get(0).get(0)) - Double.parseDouble(num1.get(0).get(0))));
                        stack.push(result);
                        break;
                    case '•':
                        result.get(0).add(String.valueOf(Double.parseDouble(num2.get(0).get(0)) * Double.parseDouble(num1.get(0).get(0))));
                        stack.push(result);
                        break;
                    case '/':
                        result.get(0).add(String.valueOf(Double.parseDouble(num2.get(0).get(0)) / Double.parseDouble(num1.get(0).get(0))));
                        stack.push(result);
                        break;
                    case '^':
                        result.get(0).add(String.valueOf(Math.pow(Double.parseDouble(num2.get(0).get(0)), Double.parseDouble(num1.get(0).get(0)))));
                        stack.push(result);
                        break;
                }
            }
        }

        //resetting Result Card's  message for Valid Expression
        ResultCardsController.resultCardsList.get(selectedCard).setMessage("");

        //sending result to Result Card
        setResult(stack.pop(), selectedCard);
    }

    /**
     * ================================= METHOD FOR GETTING MATRIX FROM ITS NAME ===================================
     **/
    public static List<List<String>> getCurrentMatrix(Character Name) {

        int matrixIndex = MatrixCardsController.matrixNamesList.indexOf(String.valueOf(Name));
        return MatrixCardsController.matrixCardsList.get(matrixIndex).getMatrix();
    }

    /**
     * ================================== METHOD FOR SETTING RESULT ON RESULT CARD ==================================
     **/
    public static void setResult(List<List<String>> result, int selectedCard) {

        //resetting result matrix when result is null (Invalid Expression)
        if (result == null) {
            ResultCardsController.resultCardsList.get(selectedCard).setResultMatrix(null);
            ResultCardsController.resultCardsList.get(selectedCard).setMatrixColumns(0);
            ResultCardsController.resultCardsList.get(selectedCard).setMatrixRows(0);
            return;
        }

        boolean isResultValuesInt = true;
        int rows = result.size();
        int columns = result.get(0).size();
        double currentValue;

        //checking for result contains double value or not, Also rounding up to 2 decimal places
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < columns; j++) {
                currentValue = Double.parseDouble(result.get(i).get(j));

                //rounding up to 2 decimal places
                result.get(i).set(i, Math.round(currentValue * 100) / 100.0 + "");

                //logic for checking number is in decimal or not
                if (currentValue != (int) currentValue) {
                    isResultValuesInt = false;
                    break;
                }
                //breaking loop if any of the value is in decimal
            }
        }

        //trimming '.0' from result when all result values are pure Integer
        if (isResultValuesInt) {
            for (int i = 0; i < rows; i++) {
                for (int j = 0; j < columns; j++)
                    if (result.get(i).get(j).length() > 2)
                        result.get(i).set(j, result.get(i).get(j).substring(0, result.get(i).get(j).length() - 2));
            }
        }

        //sending final result to the result card
        ResultCardsController.resultCardsList.get(selectedCard).setResultMatrix(result);
        ResultCardsController.resultCardsList.get(selectedCard).setMatrixColumns(result.get(0).size());
        ResultCardsController.resultCardsList.get(selectedCard).setMatrixRows(result.size());

        ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);

    }
}
