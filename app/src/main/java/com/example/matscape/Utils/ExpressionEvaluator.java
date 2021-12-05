package com.example.matscape.Utils;

import android.util.Log;

import androidx.annotation.NonNull;

import com.example.matscape.Controllers.MatrixCardsController;
import com.example.matscape.Controllers.ResultCardsController;

import java.util.ArrayList;
import java.util.List;
import java.util.Stack;

public class ExpressionEvaluator {
    private static final String TAG = "ExpressionEvaluator";

    public static void EvaluateExpression(@NonNull String postfixExpression, int selectedCard) {
        Stack<List<List<String>>> stack = new Stack<>();
        int flag = 0;
        char currentChar;

        for (int i = 0; i < postfixExpression.length(); i++) {
            currentChar = postfixExpression.charAt(i);

            if (Character.isDigit(currentChar) || currentChar == '.') {
                if (flag == 0) {

                    List<List<String>> element = new ArrayList<>();
                    element.add(new ArrayList<>());
                    element.get(0).add(String.valueOf(currentChar));

                    stack.push(element);
                    flag = 1;
                } else {
                    List<List<String>> element = stack.pop();
                    element.get(0).set(0, element.get(0).get(0) + currentChar);
                    stack.push(element);
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

        Log.d(TAG, "Ans: " + stack.pop());
    }

    public static List<List<String>> getCurrentMatrix(Character Name) {

        int matrixIndex = MatrixCardsController.matrixCardsList.indexOf(String.valueOf(Name));

        return MatrixCardsController.matrixCardsList.get(matrixIndex).getMatrix();
    }
}
