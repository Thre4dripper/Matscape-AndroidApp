package com.example.matscape.Utils;

import android.util.Log;

import androidx.annotation.NonNull;

public class ExpressionChecker {

    private static final String TAG = "ExpressionChecker";

    public static void finalExpressionCheck(String expression) {
        String postfix = "";
        if (bracketChecker(expression))
            postfix = ExpressionEvaluator.InfixToPostfix(expression);
        Log.d(TAG, "postfix: " + postfix);
    }

    /**
     * =============================== METHOD FOR EMPTY AND BALANCED BRACKETS CHECKING ============================
     **/
    static boolean bracketChecker(@NonNull String expr) {

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

}
