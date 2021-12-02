package com.example.matscape.Utils;

import android.text.SpannableStringBuilder;
import android.text.style.SuperscriptSpan;
import android.util.Log;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.List;

public class ExpressionBuilder {
    private static final String TAG = "ExpressionBuilder";
    private static List<Integer> spansList = new ArrayList<>();

    /**
     * ===================== FUNCTION TO INSERT SUPERSCRIPT IN CALCULATION STRING ===========================
     **/

    @NonNull
    public static StringBuilder insertSuperscript(SpannableStringBuilder expression) {
        StringBuilder modifiedString = new StringBuilder();
        spansList.clear();
        spansList =getSpans(expression);

        int iterator = 0;
        for (int i = 0; i < expression.length(); i++) {
            if (!spansList.contains(i))
                modifiedString.append(expression.charAt(i));
            else {
                if (!spansList.contains(i - 1)) {
                    modifiedString.append("^(").append(expression.charAt(i)).append(")");
                    iterator++;
                } else
                    modifiedString.insert(i + iterator * 3 - 1, expression.charAt(i));
            }
        }
        return modifiedString;
    }

    /**
     * ======================= FUNCTION TO GENERATE INDEX MAPPED TO CURSOR POSITION ==============================
     **/
    @NonNull
    public static List<Integer> getMappedIndexesList(SpannableStringBuilder expression) {
        List<Integer> IndexList = new ArrayList<>();
        spansList.clear();
        spansList =getSpans(expression);

        int baseCounter = 0, powerCounter = 0;
        for (int i = 0; i < expression.length(); i++) {
            if (!spansList.contains(i))
                IndexList.add(baseCounter++);
            else {
                if (!spansList.contains(i - 1)) {
                    powerCounter++;
                    IndexList.add(i + powerCounter * 3 - 1);
                    baseCounter += 4;
                } else {
                    IndexList.add(i + powerCounter * 3 - 1);
                    baseCounter++;
                }
            }
        }
        return IndexList;
    }

    /**
     * ========================== FUNCTION TO GET SPANS APPLIED ON EXPRESSION TEXT =================================
     **/

    @NonNull
    public static List<Integer> getSpans(@NonNull SpannableStringBuilder expression) {
        int spanStart;
        List<Integer> spansList = new ArrayList<>();
        Object[] spans = expression.getSpans(0, expression.length(), Object.class);
        for (Object span : spans) {
            if (span.getClass().equals(SuperscriptSpan.class)) {
                SuperscriptSpan s = (SuperscriptSpan) span;
                spanStart = expression.getSpanStart(s);
                spansList.add(spanStart);
            }
        }
        return spansList;
    }

    /**
     * ==================================== FUNCTION TO GENERATE CALCULATION STRING ==============================
     **/
    public static void generateCalculationString(@NonNull StringBuilder expression){
        StringBuilder calculationString=new StringBuilder(expression);

        for(int i=1;i<calculationString.length();i++)
        {
            if(Character.isDigit(calculationString.charAt(i-1)) && !Character.isDigit(calculationString.charAt(i)))
                calculationString.insert(i," ");
        }

        Log.d(TAG, "CalculationString: "+calculationString);
        ExpressionChecker.finalExpressionCheck(calculationString.toString());
    }
}