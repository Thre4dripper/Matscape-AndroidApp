package com.ByteMechanics.matscape.Utils;

import androidx.annotation.NonNull;

import com.ByteMechanics.matscape.Constants.Constant;

import java.util.Stack;

public class ExpressionChecker {

    private static final String TAG = "ExpressionChecker";

    public static int finalExpressionCheck(String expression,int selectedCard) {
        String postfix;

        //variable for brackets error codes
        int isBracketsValid = bracketChecker(expression);
        int isDecimalsValid = decimalChecker(expression);
        //early termination of execution if brackets are not balanced
        if (isBracketsValid == 0)
            postfix = InfixToPostfix(expression);
        else
            return isBracketsValid;

        if (isDecimalsValid != 0)
            return isDecimalsValid;

        //CODE FOR FAKE EVALUATION OF EXPRESSION FOR FINDING 'HUMAN ERRORS' IN EXPRESSION
        Stack<Character> stack = new Stack<>();
        //for multi digit postfix evaluation
        int flag = 0;
        char currentChar;

        //loop for iterating over whole expression
        for (int i = 0; i < postfix.length(); i++) {
            currentChar = postfix.charAt(i);

            //whole multi-digit number pushed into stack as one entity by blocking all other digits
            if (Character.isDigit(currentChar) && flag == 0) {
                stack.push(currentChar);
                flag = 1;
            }

            //clearing flag for next multi digit number
            else if (currentChar == ' ')
                flag = 0;

            else if(currentChar=='|')
                stack.push(currentChar);
                //Matrix Names pushed normally
            else if (Character.isUpperCase(currentChar))
                stack.push(currentChar);

                //binary operators encountered
            else if (currentChar == '+' || currentChar == '-' || currentChar == '•' || currentChar == '/' || currentChar == '^') {
                char c1, c2;

                //more operators results in early empty stack
                if (!stack.isEmpty())
                    c1 = stack.pop();
                else {
                    return Constant.ERROR_MISTAKE_OPERATOR;
                }

                //more operators results in early empty stack
                if (!stack.isEmpty())
                    c2 = stack.pop();
                else {
                    return Constant.ERROR_MISTAKE_OPERATOR;
                }

                //operation is performed by operators, on two operands, so any of the popped character must not be operator
                if (c1 != '+' && c1 != '-' && c1 != '•' && c1 != '/' && c1 != '^' && c2 != '+' && c2 != '-' && c2 != '•' && c2 != '/' && c2 != '^') {
                    //binary operators perform on two operands and ONE result is pushed into stack
                    stack.push(c1);
                }
                //if so this is a operator mistake
                else {
                    return Constant.ERROR_MISTAKE_OPERATOR;
                }
            }

            //matrix operators encountered
            else if (currentChar == '#' || currentChar == '$' || currentChar == '@' || currentChar == '%' ||
                    currentChar == '&' || currentChar == '~') {
                char c;

                //more operators results in early empty stack
                if (!stack.isEmpty())
                    c = stack.pop();
                else {
                    return Constant.ERROR_MISTAKE_MATRIX;
                }

                //matrix operation is unary operation, so popped character must not be matrix operation
                if (c != '#' && c != '$' && c != '@' && c != '%' && c != '&' && c != '~')
                    stack.push(c);
                    //if so this is a operator mistake
                else
                    return Constant.ERROR_MISTAKE_MATRIX;
            }
        }

        //after whole evaluation, only final result must remain in the stack
        if (stack.size() > 1) {
            return Constant.ERROR_MISTAKE_MATRIX;
        }

        ExpressionEvaluator.EvaluateExpression(postfix,selectedCard);
        //all clear
        return 0;
    }

    /**
     * ======================================= METHOD FOR VALID DECIMALS CHECKING ================================
     **/
    public static int decimalChecker(@NonNull String expr){

        int flag=0;
        char currentChar;

        //for going up to i+1 in loops as well as scanning whole expression
        expr+=";";

        //Digit Must be present after decimal
        for(int i=0;i<expr.length()-1;i++)
            if(expr.charAt(i)=='.' && !Character.isDigit(expr.charAt(i+1)))
               return Constant.ERROR_MISTAKE_DECIMAL;

        //every number should contain only 1 decimal
        for(int i=0;i<expr.length()-1;i++)
        {
            currentChar=expr.charAt(i);
            if(Character.isDigit(currentChar) || currentChar=='.')
            {
                if(flag==0 && currentChar=='.')
                    flag=1;
                else if(flag==1 && currentChar=='.')
                    return Constant.ERROR_MISTAKE_DECIMAL;
            }
            else if(currentChar==' ')
                flag=0;
        }

        return 0;
    }

    /**
     * =============================== METHOD FOR EMPTY AND BALANCED BRACKETS CHECKING ============================
     **/
    private static int bracketChecker(@NonNull String expr) {

        //empty bracket checking
        if (expr.contains("()"))
            return Constant.ERROR_EMPTY_BRACKETS;

        int isBracketsBalanced = 0;

        for (int i = 0; i < expr.length(); i++) {
            if (expr.charAt(i) == '(')
                isBracketsBalanced++;
            else if (expr.charAt(i) == ')')
                isBracketsBalanced--;

            //var must be >=0 all the time
            if (isBracketsBalanced < 0)
                return Constant.ERROR_MISTAKE_BRACKETS;
        }

        //variable must be 0 for balanced brackets
        if (isBracketsBalanced == 0)
            return 0;
        else
            return Constant.ERROR_MISTAKE_BRACKETS;
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

            //appending Matrix Names and Digits with their separator and decimal
            if (Character.isLetterOrDigit(currentChar) || currentChar=='.' || currentChar == ' ')
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
        String character=String.valueOf(ch);
        switch (character) {
            case "+":
            case "-":
                return 1;

            case "•":
            case "/":
                return 2;

            case "^":
                return 3;

            case Constant.DET_SYMBOL:  //for determinant
            case Constant.TRC_SYMBOL:   //for trace
            case Constant.ADJ_SYMBOL:  //for adjoint
            case Constant.MIN_SYMBOL:  //for minors
            case Constant.COF_SYMBOL:   //for cofactors
            case Constant.MAT_UNARY_MINUS:   //for unary minus for matrix
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
