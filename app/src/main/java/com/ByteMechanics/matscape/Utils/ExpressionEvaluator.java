package com.ByteMechanics.matscape.Utils;

import android.content.Context;
import android.graphics.Color;
import android.graphics.Typeface;
import android.text.SpannableString;
import android.text.Spanned;
import android.text.style.ForegroundColorSpan;
import android.text.style.StyleSpan;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import com.ByteMechanics.matscape.Constants.Constant;
import com.ByteMechanics.matscape.Controllers.MatrixCardsController;
import com.ByteMechanics.matscape.Controllers.ResultCardsController;
import com.ByteMechanics.matscape.R;

import java.util.ArrayList;
import java.util.List;
import java.util.Stack;

public class ExpressionEvaluator {
    private static final String TAG = "ExpressionEvaluator";
    public static int evaluationErrorCode = 0;
    private static SpannableString messageString;

    /**
     * ================================== MASTER FUNCTION FOR EVALUATING EXPRESSION =========================
     **/
    public static void EvaluateExpression(Context context, @NonNull String postfixExpression, int selectedCard) {
        //resetting error code
        evaluationErrorCode = 0;
        Stack<List<List<String>>> stack = new Stack<>();
        int flag = 0;
        char currentChar;
        List<List<String>> number;

        //Evaluation will continue till errorCode remains '0'
        for (int i = 0; i < postfixExpression.length() && isErrorCodeValid(evaluationErrorCode); i++) {
            currentChar = postfixExpression.charAt(i);

            if (Character.isDigit(currentChar) || currentChar == '.') {
                if (flag == 0) {
                    number = new ArrayList<>();
                    number.add(new ArrayList<>());
                    number.get(0).add(String.valueOf(currentChar));

                    stack.push(number);
                    flag = 1;
                } else {
                    number = stack.pop();
                    number.get(0).set(0, number.get(0).get(0) + currentChar);
                    stack.push(number);
                }
            } else if (currentChar == ' ')
                flag = 0;

            else if (currentChar == '|') {
                number = new ArrayList<>();
                number.add(new ArrayList<>());
                number.get(0).add(String.valueOf(currentChar));
                stack.push(number);
            } else if (Character.isUpperCase(currentChar))
                stack.push(getCurrentMatrix(context, currentChar));


            else if (currentChar == '+' || currentChar == '-' || currentChar == '•' || currentChar == '/' || currentChar == '^') {
                List<List<String>> str1 = stack.pop();
                List<List<String>> str2 = stack.pop();
                List<List<String>> result = new ArrayList<>();
                result.add(new ArrayList<>());

                //WHEN BOTH FETCHED STRINGS ARE NUMBERS
                if (str2.size() == 1 && str2.get(0).size() == 1 && str1.size() == 1 && str1.get(0).size() == 1)
                    switch (currentChar) {
                        case '+':
                            result.get(0).add(String.valueOf(Double.parseDouble(str2.get(0).get(0)) + Double.parseDouble(str1.get(0).get(0))));
                            stack.push(result);
                            break;
                        case '-':
                            result.get(0).add(String.valueOf(Double.parseDouble(str2.get(0).get(0)) - Double.parseDouble(str1.get(0).get(0))));
                            stack.push(result);
                            break;
                        case '•':
                            result.get(0).add(String.valueOf(Double.parseDouble(str2.get(0).get(0)) * Double.parseDouble(str1.get(0).get(0))));
                            stack.push(result);
                            break;
                        case '/':
                            result.get(0).add(String.valueOf(Double.parseDouble(str2.get(0).get(0)) / Double.parseDouble(str1.get(0).get(0))));
                            stack.push(result);
                            break;
                        case '^':
                            if (!str1.get(0).get(0).equals("|"))
                                result.get(0).add(String.valueOf(Math.pow(Double.parseDouble(str2.get(0).get(0)), Double.parseDouble(str1.get(0).get(0)))));
                            else
                                result.get(0).add(str2.get(0).get(0));


                            stack.push(result);
                            break;
                    }
                    //WHEN FIRST STRING IS MATRIX AND SECOND IS NUMBER
                else if ((str2.size() > 1 || str2.get(0).size() > 1) && str1.size() == 1 && str1.get(0).size() == 1)
                    switch (currentChar) {
                        case '+':
                            evaluationErrorCode = Constant.ERROR_MATRIX_SCALAR_ADDITION;
                            break;
                        case '-':
                            evaluationErrorCode = Constant.ERROR_MATRIX_SCALAR_SUBTRACTION;
                            break;
                        case '•':
                            result = MatrixOperations.ScalarMultiply(str2, Double.parseDouble(str1.get(0).get(0)));
                            stack.push(result);
                            break;
                        case '/':
                            result = MatrixOperations.ScalarDivide(str2, Double.parseDouble(str1.get(0).get(0)));
                            stack.push(result);
                            break;
                        case '^':
                            //power for now sq matrices is allowed in case of transpose
                            if (str1.get(0).get(0).equals("|") || str2.size() == str2.get(0).size()) {
                                result = MatrixOperations.matrixPower(str2, str1.get(0).get(0));
                                stack.push(result);
                            } else {
                                evaluationErrorCode = Constant.ERROR_SQUARE_MATRIX_POWER;
                            }
                            break;
                    }
                    //WHEN FIRST STRING IS NUMBER AND SECOND IS MATRIX
                else if (str2.size() == 1 && str2.get(0).size() == 1 && (str1.size() > 1 || str1.get(0).size() > 1))
                    switch (currentChar) {
                        case '+':
                            evaluationErrorCode = Constant.ERROR_MATRIX_SCALAR_ADDITION;
                            break;
                        case '-':
                            evaluationErrorCode = Constant.ERROR_MATRIX_SCALAR_SUBTRACTION;
                            break;
                        case '•':
                            result = MatrixOperations.ScalarMultiply(str1, Double.parseDouble(str2.get(0).get(0)));
                            stack.push(result);
                            break;
                        case '/':
                            result = MatrixOperations.ScalarDivide(str1, Double.parseDouble(str2.get(0).get(0)));
                            stack.push(result);
                            break;
                        case '^':
                            /*
                             * NOT POSSIBLE (will never encounter)
                             * app doesn't have functionality to raise matrix as a power to some number
                             */
                            break;
                    }
                    //WHEN BOTH FETCHED STRINGS ARE MATRICES
                else if ((str2.size() > 1 || str2.get(0).size() > 1) && (str1.size() > 1 || str1.get(0).size() > 1))
                    switch (currentChar) {
                        case '+':
                            result = MatrixOperations.matrixAddition(str2, str1);
                            if (result != null)
                                stack.push(result);
                            else
                                evaluationErrorCode = Constant.ERROR_INCOMPATIBLE_DIMENS;

                            break;
                        case '-':
                            result = MatrixOperations.matrixSubtraction(str2, str1);
                            if (result != null)
                                stack.push(result);
                            else
                                evaluationErrorCode = Constant.ERROR_INCOMPATIBLE_DIMENS;
                            break;
                        case '•':
                            result = MatrixOperations.matrixMultiply(str2, str1);
                            if (result != null)
                                stack.push(result);
                            else
                                evaluationErrorCode = Constant.ERROR_INCOMPATIBLE_DIMENS;
                            break;
                        case '/':
                            result = MatrixOperations.matrixDivide(str2, str1);
                            if (result != null) {
                                evaluationErrorCode = Constant.WARNING_DIVISOR_AS_INVERSE;
                                stack.push(result);
                            }

                            break;
                        case '^':
                            /*
                             * NOT POSSIBLE (will never encounter)
                             * app doesn't have functionality to raise matrix as a power to some matrix
                             */
                            break;
                    }
            }
            //UNARY MATRIX OPERATIONS
            else if (currentChar == '#' || currentChar == '$' || currentChar == '@'
                    || currentChar == '%' || currentChar == '&' || currentChar == '~') {
                List<List<String>> str = stack.pop();
                List<List<String>> result = new ArrayList<>();
                result.add(new ArrayList<>());

                switch (currentChar) {

                    //for determinant
                    case '#':
                        if (str.size() == str.get(0).size()) {
                            result.get(0).add(String.valueOf(MatrixOperations.determinant(str)));
                            stack.push(result);
                            //for 1x1 matrices
                            if (str.size() == 1)
                                evaluationErrorCode = Constant.WARNING_1X1_DETERMINANT;
                        } else
                            evaluationErrorCode = Constant.ERROR_SQUARE_MATRIX_DETERMINANT;


                        break;

                    //for trace
                    case '$':
                        if (str.size() == str.get(0).size()) {
                            result.get(0).add(String.valueOf(MatrixOperations.trace(str)));
                            stack.push(result);
                        } else
                            evaluationErrorCode = Constant.ERROR_SQUARE_MATRIX_TRACE;

                        break;

                    //for adjoint
                    case '@':
                        if (str.size() == str.get(0).size()) {
                            if (str.size() != 1)
                                result = MatrixOperations.adjoint(str);

                                //adjoint is 1 for 1x1 matrices
                            else
                                result.get(0).add("1");

                            stack.push(result);
                        } else
                            evaluationErrorCode = Constant.ERROR_SQUARE_MATRIX_ADJOINT;

                        break;

                    //for minors
                    case '%':
                        if (str.size() == str.get(0).size()) {
                            if (str.size() != 1) {
                                result = MatrixOperations.minorMatrix(str);
                                stack.push(result);
                            } else
                                evaluationErrorCode = Constant.ERROR_1X1_MINOR;

                        } else
                            evaluationErrorCode = Constant.ERROR_SQUARE_MATRIX_MINORS;

                        break;

                    //for cofactors
                    case '&':
                        if (str.size() == str.get(0).size()) {
                            if (str.size() != 1) {
                                result = MatrixOperations.cofactorMatrix(str);
                                stack.push(result);
                            } else
                                evaluationErrorCode = Constant.ERROR_1X1_COFACTOR;

                        } else
                            evaluationErrorCode = Constant.ERROR_SQUARE_MATRIX_COFACTORS;

                        break;
                    case '~':
                        List<List<String>> nullMatrix = new ArrayList<>();
                        for (int j = 0; j < str.size(); j++) {
                            nullMatrix.add(new ArrayList<>());
                            for (int k = 0; k < str.get(0).size(); k++)
                                nullMatrix.get(j).add("0");
                        }
                        result = MatrixOperations.matrixSubtraction(nullMatrix, str);
                        stack.push(result);
                }

            }
        }

        //sending final result if there are no errors, warnings are allowed
        if (isErrorCodeValid(evaluationErrorCode)) {
            setResult(stack.pop(), selectedCard);
        }
        //error encountered
        else setResult(null, selectedCard);

        //setting error message text based on result
        setErrorsAndWarnings(context, selectedCard);
    }

    /**
     * ================================= METHOD FOR CHECKING PERMISSIBLE ERROR CODES ================================
     **/
    public static boolean isErrorCodeValid(int errorCode) {
        return errorCode == 0 || errorCode == Constant.WARNING_1X1_DETERMINANT
                || errorCode == Constant.WARNING_DIVISOR_AS_INVERSE;
    }

    /**
     * ================================= METHOD FOR GETTING MATRIX FROM ITS NAME ===================================
     **/

    @Nullable
    public static List<List<String>> getCurrentMatrix(Context context, Character Name) {

        int matrixIndex = MatrixCardsController.NamesList.indexOf(String.valueOf(Name));
        //receiving matrix by its index
        if (matrixIndex == -1) {
            evaluationErrorCode = Constant.ERROR_NO_MATRIX_FOUND;
            messageString = new SpannableString(context.getString(R.string.error_no_matrix_found, Name));
            messageString.setSpan(new ForegroundColorSpan(Color.RED), 0, messageString.length(),
                    Spanned.SPAN_INCLUSIVE_INCLUSIVE);
            return null;
        }
        List<List<String>> receivedMatrix = MatrixCardsController.matrixCardsList.get(matrixIndex).getMatrix();

        //cloning original matrix, so that any changes doesn't reflect back
        List<List<String>> clone = new ArrayList<>();
        for (int i = 0; i < receivedMatrix.size(); i++)
            clone.add(new ArrayList<>(receivedMatrix.get(i)));

        return clone;
    }

    /**
     * ================================== METHOD FOR SETTING RESULT ON RESULT CARD ==================================
     **/
    public static void setResult(List<List<String>> result, int selectedCard) {

        //resetting result matrix when result is null (Invalid Expression)
        if (result == null) {
            ResultCardsController.resultCardsList.get(selectedCard).setResultMatrix(null);
            ResultCardsController.resultCardsList.get(selectedCard).setMatrixColumns(0);
            ResultCardsController.resultCardsList.get(selectedCard).setMatrixRows(0);
            return;
        }

        boolean isResultValuesInt = true;
        int rows = result.size();
        int columns = result.get(0).size();
        double currentValue;
        //checking for result contains double value or not, Also rounding up to 2 decimal places
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < columns; j++) {
                //rounding up to 2 decimal places
                currentValue = Math.round(Double.parseDouble(result.get(i).get(j)) * 100.0) / 100.0;
                result.get(i).set(j, String.valueOf(currentValue));

                //logic for checking a number is in decimal or not
                //rounded this value before for better checking
                if (currentValue != Math.floor(currentValue)) {
                    isResultValuesInt = false;
                }
                //breaking loop if any of the value is in decimal
            }
        }

        //trimming '.0' from result when all result values are pure Integer
        if (isResultValuesInt) {
            for (int i = 0; i < rows; i++) {
                for (int j = 0; j < columns; j++)
                    if (result.get(i).get(j).length() > 2)
                        result.get(i).set(j, result.get(i).get(j).substring(0, result.get(i).get(j).length() - 2));
            }
        }

        //sending final result to the result card
        ResultCardsController.resultCardsList.get(selectedCard).setResultMatrix(result);
        ResultCardsController.resultCardsList.get(selectedCard).setMatrixColumns(result.get(0).size());
        ResultCardsController.resultCardsList.get(selectedCard).setMatrixRows(result.size());

        ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);

    }

    public static void setErrorsAndWarnings(Context context, int selectedCard) {

        String warningColor = "#" + Integer.toHexString(ContextCompat.getColor(context, R.color.warning_color));
        switch (evaluationErrorCode) {
            case Constant.ERROR_MATRIX_SCALAR_ADDITION:
                messageString = new SpannableString(context.getString(R.string.error_matrix_scalar_addition));
                messageString.setSpan(new ForegroundColorSpan(Color.RED), 0, messageString.length(),
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);
                break;
            case Constant.ERROR_MATRIX_SCALAR_SUBTRACTION:
                messageString = new SpannableString(context.getString(R.string.error_matrix_scalar_subtraction));
                messageString.setSpan(new ForegroundColorSpan(Color.RED), 0, messageString.length(),
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);

                break;
            case Constant.ERROR_INCOMPATIBLE_DIMENS:
                messageString = new SpannableString(context.getString(R.string.error_incompatible_dimens));
                messageString.setSpan(new ForegroundColorSpan(Color.RED), 0, messageString.length(),
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);

                break;
            case Constant.ERROR_MATRIX_DIVIDE_SINGULAR:
                messageString = new SpannableString(context.getString(R.string.error_matrix_divide_singular));

                messageString.setSpan(new ForegroundColorSpan(Color.parseColor(warningColor)), 0, 38,
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);
                messageString.setSpan(new ForegroundColorSpan(Color.RED), 38, messageString.length(),
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);

                break;
            case Constant.WARNING_DIVISOR_AS_INVERSE:
                messageString = new SpannableString(context.getString(R.string.warning_divisor_as_inverse));
                messageString.setSpan(new ForegroundColorSpan(Color.parseColor(warningColor)), 0, messageString.length(),
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);

                break;
            case Constant.ERROR_SQUARE_MATRIX_DETERMINANT:
                messageString = new SpannableString(context.getString(R.string.error_square_matrix_determinant));
                messageString.setSpan(new ForegroundColorSpan(Color.RED), 0, messageString.length(),
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);

                break;
            case Constant.WARNING_1X1_DETERMINANT:
                messageString = new SpannableString(context.getString(R.string.warning_1x1_determinant));
                messageString.setSpan(new ForegroundColorSpan(Color.parseColor(warningColor)), 0, messageString.length(),
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);

                break;
            case Constant.ERROR_SQUARE_MATRIX_TRACE:
                messageString = new SpannableString(context.getString(R.string.error_square_matrix_trace));
                messageString.setSpan(new ForegroundColorSpan(Color.RED), 0, messageString.length(),
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);

                break;
            case Constant.ERROR_SQUARE_MATRIX_ADJOINT:
                messageString = new SpannableString(context.getString(R.string.error_square_matrix_adjoint));
                messageString.setSpan(new ForegroundColorSpan(Color.RED), 0, messageString.length(),
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);

                break;
            case Constant.ERROR_1X1_MINOR:
                messageString = new SpannableString(context.getString(R.string.error_1x1_minor));
                messageString.setSpan(new ForegroundColorSpan(Color.RED), 0, messageString.length(),
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);

                break;
            case Constant.ERROR_SQUARE_MATRIX_MINORS:
                messageString = new SpannableString(context.getString(R.string.error_square_matrix_minors));
                messageString.setSpan(new ForegroundColorSpan(Color.RED), 0, messageString.length(),
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);

                break;
            case Constant.ERROR_1X1_COFACTOR:
                messageString = new SpannableString(context.getString(R.string.error_1x1_cofactor));
                messageString.setSpan(new ForegroundColorSpan(Color.RED), 0, messageString.length(),
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);

                break;
            case Constant.ERROR_SQUARE_MATRIX_COFACTORS:
                messageString = new SpannableString(context.getText(R.string.error_square_matrix_cofactors));
                messageString.setSpan(new ForegroundColorSpan(Color.RED), 0, messageString.length(),
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);

                break;
            case Constant.ERROR_SQUARE_MATRIX_POWER:
                messageString = new SpannableString(context.getString(R.string.error_square_matrix_power));
                messageString.setSpan(new ForegroundColorSpan(Color.RED), 0, messageString.length(),
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);

                break;
            case Constant.ERROR_SINGULAR_MATRIX_INVERSE:
                messageString = new SpannableString(context.getString(R.string.error_singular_matrix_inverse));
                messageString.setSpan(new ForegroundColorSpan(Color.RED), 0, messageString.length(),
                        Spanned.SPAN_INCLUSIVE_INCLUSIVE);

                break;
            //no error
            case 0:
                messageString = new SpannableString("");
        }
        messageString.setSpan(new StyleSpan(Typeface.BOLD), 0, messageString.length(),
                Spanned.SPAN_INCLUSIVE_INCLUSIVE);
        ResultCardsController.resultCardsList.get(selectedCard).setMessage(messageString);
    }
}
