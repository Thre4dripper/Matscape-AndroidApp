package com.example.matscape.Utils;

import android.text.SpannableStringBuilder;
import android.text.style.SuperscriptSpan;
import android.util.Log;

import androidx.annotation.NonNull;

import java.util.ArrayList;
import java.util.List;

public class ExpressionBuilder {
    private static final String TAG = "ExpressionBuilder";
    private static final List<Integer> spansIndexes = new ArrayList<>();

    /**
     * ==================================== FUNCTION TO GENERATE CALCULATION STRING ==============================
     **/

    @NonNull
    public static StringBuilder generateCalculationString(SpannableStringBuilder expression) {
        StringBuilder calculationString = new StringBuilder();
        spansIndexes.clear();
        getSpans(expression);

        int iterator = 0;
        for (int i = 0; i < expression.length(); i++) {
            if (!spansIndexes.contains(i))
                calculationString.append(expression.charAt(i));
            else {
                if (!spansIndexes.contains(i - 1)) {
                    calculationString.append(" ^(").append(expression.charAt(i)).append(")");
                    iterator++;
                } else
                    calculationString.insert(i + iterator * 3 + iterator - 1, expression.charAt(i));
            }
        }

        Log.d(TAG, calculationString.toString());
        return calculationString;

    }

    /**
     * ======================= FUNCTION TO GENERATE INDEX MAPPED TO CURSOR POSITION ==============================
     **/
    @NonNull
    public static List<Integer> generateCalculationStringIndexList(SpannableStringBuilder expression) {
        List<Integer> IndexList = new ArrayList<>();
        spansIndexes.clear();
        getSpans(expression);

        int baseCounter=0,powerCounter = 0;
        for (int i = 0; i < expression.length(); i++) {
            if (!spansIndexes.contains(i))
                IndexList.add(baseCounter++);
            else {
                if (!spansIndexes.contains(i - 1)) {
                    powerCounter++;
                    IndexList.add(i + powerCounter * 3 + powerCounter - 1);
                    baseCounter += 5;
                } else {
                    IndexList.add(i + powerCounter * 3 + powerCounter - 1);
                    baseCounter++;
                }
            }
        }

        Log.d(TAG, IndexList.toString());
        return IndexList;
    }

    /**
     * ========================== FUNCTION TO GET SPANS APPLIED ON EXPRESSION TEXT =================================
     **/
    public static void getSpans(@NonNull SpannableStringBuilder expression) {
        int spanStart;
        Object[] spans = expression.getSpans(0, expression.length(), Object.class);
        for (Object span : spans) {
            if (span.getClass().equals(SuperscriptSpan.class)) {
                SuperscriptSpan s = (SuperscriptSpan) span;
                spanStart = expression.getSpanStart(s);
                spansIndexes.add(spanStart);
            }
        }
    }
}
