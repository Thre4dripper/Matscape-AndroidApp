package com.example.matscape.Utils;

import android.util.Log;

import androidx.annotation.NonNull;

import java.util.ArrayDeque;
import java.util.Deque;

public class ExpressionChecker {

    private static final String TAG = "ExpressionChecker";

    public static void finalExpressionCheck(String expression) {
        String postfix = null;


        Log.d(TAG, "postfix:" + bracketChecker(expression));
    }

    /**=============================== METHOD FOR EMPTY AND BALANCED BRACKETS CHECKING ============================**/
    static boolean bracketChecker(@NonNull String expr) {

        //empty bracket checking
        if(expr.contains("()"))
            return false;

        //Balanced brackets checking
        // using ArrayDeque is faster than using Stack class
        Deque<Character> stack = new ArrayDeque<>();

        // Traversing the Expression
        for (int i = 0; i < expr.length(); i++) {
            char x = expr.charAt(i);

            if (x == '(') {
                // Push the element in the stack
                stack.push(x);
            } else if (expr.charAt(i) == ')') {
                //necessary condition when ')' encounter stack should not be empty
                if (!stack.isEmpty())
                    stack.pop();
                else
                    return false;
            }
        }

        // Check Empty Stack
        return (stack.isEmpty());
    }

}
