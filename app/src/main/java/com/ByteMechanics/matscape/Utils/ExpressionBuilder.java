package com.ByteMechanics.matscape.Utils;

import android.content.Context;
import android.text.SpannableStringBuilder;
import android.text.style.SuperscriptSpan;
import android.util.Log;

import androidx.annotation.NonNull;

import com.ByteMechanics.matscape.Constants.Constant;
import com.ByteMechanics.matscape.Controllers.ResultCardsController;

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
        spansList = getSpans(expression);

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
        spansList = getSpans(expression);

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
    public static void generateCalculationString(Context context, @NonNull StringBuilder expression, int selectedCard) {
        String calculationString = expression.toString();

        //OPTIMISED CALCULATION STRING FOR MISSING '•'
        for (int i = 1; i < calculationString.length(); i++) {

            //bracket to bracket,digit,letter
            if (calculationString.charAt(i - 1) == ')'
                    && (calculationString.charAt(i) == '(' || Character.isLetterOrDigit(calculationString.charAt(i))))
                calculationString = calculationString.substring(0, i) + "•" + calculationString.substring(i);

            //digit to bracket,,letter
            if (Character.isDigit(calculationString.charAt(i - 1)) &&
                    (calculationString.charAt(i) == '(' || Character.isAlphabetic(calculationString.charAt(i))))
                calculationString = calculationString.substring(0, i) + "•" + calculationString.substring(i);

            //letter to bracket,digit,letter
            if (Character.isUpperCase(calculationString.charAt(i - 1)) &&
                    (calculationString.charAt(i) == '(' || Character.isLetterOrDigit(calculationString.charAt(i))))
                calculationString = calculationString.substring(0, i) + "•" + calculationString.substring(i);
        }

        //OPTIMISED CALCULATION STRING FOR UNARY MINUS FOR DIGIT FOR INDEX 0
        if (!calculationString.equals("")) {
            //replacing - with ~ in case of matrix to make it as a unary matrix operation
            if (calculationString.charAt(0) == '-' && calculationString.length() > 1 && Character.isUpperCase(calculationString.charAt(1)))
                calculationString = Constant.MAT_UNARY_MINUS + calculationString.substring(1);
            else if (calculationString.charAt(0) == '-')
                calculationString = "0" + calculationString;
        }

        //OPTIMISED CALCULATION STRING FOR UNARY MINUS FOR MATRIX FOR ANY INDEX
        for (int i = 1; i < calculationString.length() - 1; i++) {
            //replacing - with ~ in case of matrix to make it as a unary matrix operation
            if (calculationString.charAt(i) == '-' && calculationString.charAt(i - 1) == '(' && Character.isUpperCase(calculationString.charAt(i + 1)))
                calculationString = calculationString.substring(0, i) + Constant.MAT_UNARY_MINUS + calculationString.substring(i + 1);
            else if (calculationString.charAt(i) == '-' && calculationString.charAt(i - 1) == '(')
                calculationString = calculationString.substring(0, i) + "0" + calculationString.substring(i);
        }

        //OPTIMISING CALCULATION STRING FOR MULTI DIGIT POSTFIX CONVERSION BY A SEPARATOR
        for (int i = 1; i < calculationString.length(); i++) {
            if (Character.isDigit(calculationString.charAt(i - 1)) && calculationString.charAt(i) != '.' && !Character.isDigit(calculationString.charAt(i)))
                calculationString = calculationString.substring(0, i) + " " + calculationString.substring(i);
        }

        //OPTIMISED CALCULATION STRING FOR PUTTING '0' BEFORE EACH '.'
        if (!calculationString.equals("") && calculationString.charAt(0) == '.')
            calculationString = "0" + calculationString;

        for (int i = 1; i < calculationString.length(); i++) {
            if (!Character.isDigit(calculationString.charAt(i - 1)) && calculationString.charAt(i) == '.')
                calculationString = calculationString.substring(0, i) + "0" + calculationString.substring(i);
        }

        //REPLACED ALL MAT OPERATIONS BY SYMBOLS FOR POSTFIX CONVERSION
        if (calculationString.contains(Constant.DET))
            calculationString = calculationString.replace(Constant.DET, Constant.DET_SYMBOL);
        if (calculationString.contains(Constant.TRC))
            calculationString = calculationString.replace(Constant.TRC, Constant.TRC_SYMBOL);
        if (calculationString.contains(Constant.ADJ))
            calculationString = calculationString.replace(Constant.ADJ, Constant.ADJ_SYMBOL);
        if (calculationString.contains(Constant.MIN))
            calculationString = calculationString.replace(Constant.MIN, Constant.MIN_SYMBOL);
        if (calculationString.contains(Constant.COF))
            calculationString = calculationString.replace(Constant.COF, Constant.COF_SYMBOL);

        //return code from evaluation of expression
        int RETURN_CODE = 0;

        //converting 'T' of transpose to '|' in every place
        int transposeIndex;
        for (int i = 0; i < calculationString.length(); i++) {
            transposeIndex = calculationString.indexOf("^", i);
            if (transposeIndex != -1) {
                i += 2;

                //for detecting +,- and T in power
                int flag1 = 0, flag2 = 0;
                while (calculationString.charAt(i) != ')') {

                    if ((calculationString.charAt(i) == '+' || calculationString.charAt(i) == '-'))
                        flag1 = 1;
                    if (calculationString.charAt(i) == 'T') {
                        calculationString = calculationString.substring(0, i) + "|" + calculationString.substring(i + 1);
                        flag2 = 1;
                    }

                    //if both '+','-' and 'T' are present in power then it is invalid transpose
                    if (flag1 == 1 && flag2 == 1) {
                        RETURN_CODE = -5;
                        break;
                    }
                    i++;
                }
            }
        }

        Log.d(TAG, "CalculationString: " + calculationString);

        if (!calculationString.isEmpty() && RETURN_CODE == 0) {
            RETURN_CODE = ExpressionChecker.finalExpressionCheck(calculationString, selectedCard);
        }
        //clearing result when expression is empty
        else {
            ResultCardsController.resultCardsList.get(selectedCard).setMessage("");
            ExpressionEvaluator.setResult(null, selectedCard);
        }
        //clearing previous result when an error occurred
        if (RETURN_CODE != 0)
            ExpressionEvaluator.setResult(null, selectedCard);

        //setting message view based on returned code
        setErrorMessage(selectedCard, RETURN_CODE);
    }

    /**
     * ============================ METHOD FOR SETTING ERROR MESSAGE IN RESULT CARD ===============================
     **/
    public static void setErrorMessage(int selectedCard, int errorCode) {


        switch (errorCode) {
            case Constant.ERROR_EMPTY_BRACKETS:
                ResultCardsController.resultCardsList.get(selectedCard).setMessage("Empty Brackets");
                break;
            case Constant.ERROR_MISTAKE_BRACKETS:
                ResultCardsController.resultCardsList.get(selectedCard).setMessage("Bracket Mistake");
                break;
            case Constant.ERROR_MISTAKE_OPERATOR:
                ResultCardsController.resultCardsList.get(selectedCard).setMessage("Operator Mistake");
                break;
            case Constant.ERROR_MISTAKE_MATRIX:
                ResultCardsController.resultCardsList.get(selectedCard).setMessage("Matrix Mistake");
                break;
            case Constant.ERROR_MISTAKE_DECIMAL:
                ResultCardsController.resultCardsList.get(selectedCard).setMessage("Decimal Mistake");
                break;
            case Constant.ERROR_MISTAKE_TRANSPOSE:
                ResultCardsController.resultCardsList.get(selectedCard).setMessage("Error Calculating Transpose");
                break;
        }

        ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
    }
}