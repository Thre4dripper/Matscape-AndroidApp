package com.example.matscape.Utils;

import androidx.annotation.NonNull;

import com.example.matscape.Controllers.MatrixCardsController;
import com.example.matscape.Controllers.ResultCardsController;

import java.util.ArrayList;
import java.util.List;
import java.util.Stack;

public class ExpressionEvaluator {
    private static final String TAG = "ExpressionEvaluator";
    public static int error = 0;

    /**
     * ================================== MASTER FUNCTION FOR EVALUATING EXPRESSION =========================
     **/
    public static void EvaluateExpression(@NonNull String postfixExpression, int selectedCard) {
        //resetting error code
        error = 0;
        Stack<List<List<String>>> stack = new Stack<>();
        int flag = 0;
        char currentChar;
        List<List<String>> number;

        for (int i = 0; i < postfixExpression.length() && error != -1; i++) {
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
                stack.push(getCurrentMatrix(currentChar));


            else if (currentChar == '+' || currentChar == '-' || currentChar == '•' || currentChar == '/' || currentChar == '^') {
                List<List<String>> str1 = stack.pop();
                List<List<String>> str2 = stack.pop();
                List<List<String>> result = new ArrayList<>();
                result.add(new ArrayList<>());

                //when both fetched strings are numbers
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
                            result.get(0).add(String.valueOf(Math.pow(Double.parseDouble(str2.get(0).get(0)), Double.parseDouble(str1.get(0).get(0)))));
                            stack.push(result);
                            break;
                    }
                else if ((str2.size() > 1 || str2.get(0).size() > 1) && str1.size() == 1 && str1.get(0).size() == 1)
                    switch (currentChar) {
                        case '+':
                            ResultCardsController.resultCardsList.get(selectedCard).setMessage("Only Matrices can be Added in Matrices");
                            error = -1;
                            break;
                        case '-':
                            ResultCardsController.resultCardsList.get(selectedCard).setMessage("Only Matrices can be Subtracted from Matrices");
                            error = -1;
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
                            result = MatrixOperations.matrixPower(str2, str1.get(0).get(0), selectedCard);
                            if (result != null)
                                stack.push(result);
                            else
                                error = -1;

                            break;
                    }
                else if (str2.size() == 1 && str2.get(0).size() == 1 && (str1.size() > 1 || str1.get(0).size() > 1))
                    switch (currentChar) {
                        case '+':
                            ResultCardsController.resultCardsList.get(selectedCard).setMessage("Only Matrices can be Added in Matrices");
                            error = -1;
                            break;
                        case '-':
                            ResultCardsController.resultCardsList.get(selectedCard).setMessage("Only Matrices can be Subtracted from Matrices");
                            error = -1;
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
                else if ((str2.size() > 1 || str2.get(0).size() > 1) && (str1.size() > 1 || str1.get(0).size() > 1))
                    switch (currentChar) {
                        case '+':
                            result = MatrixOperations.matrixAddition(str2, str1);
                            if (result != null)
                                stack.push(result);
                            else {
                                ResultCardsController.resultCardsList.get(selectedCard).setMessage("Matrices with Incompatible dimensions");
                                error = -1;
                            }
                            break;
                        case '-':
                            result = MatrixOperations.matrixSubtraction(str2, str1);
                            if (result != null)
                                stack.push(result);
                            else {
                                ResultCardsController.resultCardsList.get(selectedCard).setMessage("Matrices with Incompatible dimensions");
                                error = -1;
                            }
                            break;
                        case '•':
                            result = MatrixOperations.matrixMultiply(str2, str1);
                            if (result != null)
                                stack.push(result);
                            else {
                                ResultCardsController.resultCardsList.get(selectedCard).setMessage("Matrices with Incompatible dimensions");
                                error = -1;
                            }
                            break;
                        case '/':
                            result = MatrixOperations.matrixDivide(str2, str1);
                            if (result != null) {
                                ResultCardsController.resultCardsList.get(selectedCard).setMessage("Considering Inverse of Divisor Matrix");
                                error = 1;
                            } else {
                                ResultCardsController.resultCardsList.get(selectedCard).setMessage("Considering Inverse of Divisor Matrix\n" +
                                        "Singular Matrices Do not Have Inverse");
                                error = -1;
                            }
                            stack.push(result);
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
                        } else {
                            ResultCardsController.resultCardsList.get(selectedCard).setMessage("Only Square Matrices have a Determinant");
                            error = -1;
                        }

                        break;

                    //for trace
                    case '$':
                        if (str.size() == str.get(0).size()) {
                            result.get(0).add(String.valueOf(MatrixOperations.trace(str)));
                            stack.push(result);
                        } else {
                            ResultCardsController.resultCardsList.get(selectedCard).setMessage("Only Square Matrices have a Trace");
                            error = -1;
                        }
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
                        } else {
                            ResultCardsController.resultCardsList.get(selectedCard).setMessage("Only Square Matrices have a Adjoint");
                            error = -1;
                        }
                        break;

                    //for minors
                    case '%':
                        if (str.size() == str.get(0).size()) {
                            if (str.size() != 1) {
                                result = MatrixOperations.minorMatrix(str);
                                stack.push(result);
                            } else {
                                ResultCardsController.resultCardsList.get(selectedCard).setMessage("1x1 Matrices do not have Minors");
                                error = -1;
                            }
                        } else {
                            ResultCardsController.resultCardsList.get(selectedCard).setMessage("Only Square Matrices have a Minors");
                            error = -1;
                        }
                        break;

                    //for cofactors
                    case '&':
                        if (str.size() == str.get(0).size()) {
                            if (str.size() != 1) {
                                result = MatrixOperations.cofactorMatrix(str);
                                stack.push(result);
                            } else {
                                ResultCardsController.resultCardsList.get(selectedCard).setMessage("1x1 Matrices do not have Cofactors");
                                error = -1;
                            }
                        } else {
                            ResultCardsController.resultCardsList.get(selectedCard).setMessage("Only Square Matrices have a Cofactors");
                            error = -1;
                        }
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

        //resetting message and sending result if there is no error
        if (error != -1) {
            //warning but not error
            if (error != 1)
                ResultCardsController.resultCardsList.get(selectedCard).setMessage("");
            setResult(stack.pop(), selectedCard);
        }
        //error encountered
        else setResult(null, selectedCard);
    }

    /**
     * ================================= METHOD FOR GETTING MATRIX FROM ITS NAME ===================================
     **/
    @NonNull
    public static List<List<String>> getCurrentMatrix(Character Name) {

        int matrixIndex = MatrixCardsController.matrixNamesList.indexOf(String.valueOf(Name));
        //receiving matrix by its index
        List<List<String>> receivedMatrix = MatrixCardsController.matrixCardsList.get(matrixIndex).getMatrix();

        //cloning original matrix, so that any changes doesn't reflect back
        List<List<String>> clone = new ArrayList<>();
        for (int i = 0; i < receivedMatrix.size(); i++) {
            clone.add(new ArrayList<>());
            for (int j = 0; j < receivedMatrix.get(0).size(); j++)
                clone.get(i).add(receivedMatrix.get(i).get(j));

        }
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
                currentValue = Double.parseDouble(result.get(i).get(j));

                //rounding up to 2 decimal places
                result.get(i).set(j, String.valueOf(Math.round(currentValue * 100.0) / 100.0));


                //logic for checking number is in decimal or not
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
}
