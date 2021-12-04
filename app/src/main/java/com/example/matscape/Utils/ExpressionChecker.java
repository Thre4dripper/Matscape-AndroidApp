package com.example.matscape.Utils;

import android.util.Log;

import androidx.annotation.NonNull;

import java.util.Stack;

public class ExpressionChecker {

    private static final String TAG = "ExpressionChecker";

    public static int finalExpressionCheck(String expression) {
                String postfix = "";
        if (bracketChecker(expression))
            postfix = InfixToPostfix(expression);
        else return -1;
        Log.d(TAG, "postfix: " + postfix);
        return 0;
    }

    /**
     * =============================== METHOD FOR EMPTY AND BALANCED BRACKETS CHECKING ============================
     **/
    private static boolean bracketChecker(@NonNull String expr) {

        //empty bracket checking
        if (expr.contains("()"))
            return false;

        int isBracketsBalanced = 0;

        for (int i = 0; i < expr.length(); i++) {
            if (expr.charAt(i) == '(')
                isBracketsBalanced++;
            else if (expr.charAt(i) == ')')
                isBracketsBalanced--;

            if (isBracketsBalanced < 0)
                return false;
        }

        return isBracketsBalanced == 0;
    }

    /**
     * ======================================== INFIX TO POSTFIX METHOD ==============================================
     **/
    @NonNull
    private static String InfixToPostfix(String expression) {
        //initial step
        expression = '(' + expression + ')';
        //variables for conversion
        StringBuilder postfixExpression = new StringBuilder();
        Stack<Character> stack = new Stack<>();
        char currentChar;

        //conversion loop
        for (int i = 0; i < expression.length(); i++) {
            currentChar = expression.charAt(i);

            //appending Matrix Names and Digits with their separator
            if (Character.isLetterOrDigit(currentChar) || currentChar == ' ')
                postfixExpression.append(currentChar);

            else if (currentChar == '(')
                stack.push(currentChar);

                //  If the scanned character is an ')',
                // pop and output from the stack
                // until an '(' is encountered.
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
        // pop all the remaining operators from the stack
        while (!stack.isEmpty())
            postfixExpression.append(stack.pop());

        return postfixExpression.toString();
    }

    /**
     * ================================ METHOD FOR FINDING PRECEDENCE OF OPERATOR ==================================
     **/
    private static int Precedence(char ch) {
        switch (ch) {
            case '+':
            case '-':
                return 1;

            case '•':
            case '/':
                return 2;

            case '^':
                return 3;

            case '#':  //for determinant
            case '$':   //for trace
            case '@':  //for adjoint
            case '%':  //for minors
            case '*':   //for cofactors
            case '~':   //for unary minus for matrix
                return 4;
        }
        return -1;
    }

    /**
     * ================================ METHOD FOR FINDING ASSOCIATIVITY OF OPERATOR ==================================
     **/
    private static char Associativity(char ch) {
        switch (ch) {
            case '+':
            case '-':
            case '•':
            case '/':
                return 'L';

            case '^':
                return 'R';
        }
        return '0';
    }

}
