package com.example.matscape.Utils;

import android.util.Log;

import androidx.annotation.NonNull;

import java.util.Stack;

public class ExpressionEvaluator {
    private static final String TAG = "ExpressionEvaluator";

    public static void EvaluateExpression(@NonNull String postfixExpression, int selectedCard) {
        Stack<String> stack = new Stack<>();
        int flag = 0;
        char currentChar;

        for (int i = 0; i < postfixExpression.length(); i++) {
            currentChar = postfixExpression.charAt(i);

            if (Character.isDigit(currentChar)) {
                if (flag == 0) {
                    stack.push(String.valueOf(currentChar));
                    flag = 1;
                } else {
                    String number = stack.pop();
                    number += currentChar;
                    stack.push(number);
                }
            } else if (currentChar == ' ')
                flag = 0;

            else if (Character.isUpperCase(currentChar))
                stack.push(String.valueOf(currentChar));

            else if (currentChar == '+' || currentChar == '-' || currentChar == '•' || currentChar == '/' || currentChar == '^') {
                String num1 = stack.pop();
                String num2 = stack.pop();
                Double result;
                switch (currentChar) {
                    case '+':
                        result = Double.parseDouble(num2) + Double.parseDouble(num1);
                        stack.push(String.valueOf(result));
                        break;
                    case '-':
                        result = Double.parseDouble(num2) - Double.parseDouble(num1);
                        stack.push(String.valueOf(result));
                        break;
                    case '•':
                        result = Double.parseDouble(num2) * Double.parseDouble(num1);
                        stack.push(String.valueOf(result));
                        break;
                    case '/':
                        result = Double.parseDouble(num2) / Double.parseDouble(num1);
                        stack.push(String.valueOf(result));
                        break;
                    case '^':
                        result = Math.pow(Double.parseDouble(num2), Double.parseDouble(num1));
                        stack.push(String.valueOf(result));
                        break;
                }
            }
        }

        Log.d(TAG, "Ans: " + stack.pop());
    }
}
