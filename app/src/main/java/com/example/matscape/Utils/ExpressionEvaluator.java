package com.example.matscape.Utils;

import java.util.Stack;

public class ExpressionEvaluator {

    public static String InfixToPostfix(String expression) {
        expression = '(' + expression + ')';
        StringBuilder postfixExpression = new StringBuilder();
        Stack<Character> stack = new Stack<>();

        char currentChar;
        for (int i = 0; i < expression.length(); i++) {
            currentChar = expression.charAt(i);
            if (Character.isLetterOrDigit(currentChar))
                postfixExpression.append(currentChar);

            else if (currentChar == '(')
                stack.push(currentChar);

            else if (currentChar == ')') {
                while (!stack.isEmpty() && stack.peek() != '(')
                    postfixExpression.append(stack.pop());

                stack.pop();
            }
            // an operator is encountered
            else {
                while (!stack.isEmpty()
                        && (Precedence(currentChar) < Precedence(stack.peek())
                        || (Precedence(currentChar) == Precedence(stack.peek())) && Associativity(currentChar) == 'L')) {
                    postfixExpression.append(stack.pop());
                }
                stack.push(currentChar);
            }


        }

        while (!stack.isEmpty())
            postfixExpression.append(stack.pop());

        return postfixExpression.toString();
    }

    private static int Precedence(char ch) {
        switch (ch) {
            case '+':
            case '-':
                return 1;

            case '·':
            case '/':
                return 2;

            case '^':
                return 3;

            case '#':   //for determinant
            case '$':  //for trace
            case '@': //for adjoint
            case '%': //for minors
            case '*': //for cofactors
            case '~': //for unary minus for matrix
                return 4;
        }
        return -1;
    }

    private static char Associativity(char ch) {
        switch (ch) {
            case '+':
            case '-':
            case '*':
            case '/':
                return 'L';

            case '^':
                return 'R';
        }
        return '0';
    }
}
