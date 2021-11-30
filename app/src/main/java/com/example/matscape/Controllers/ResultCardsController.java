package com.example.matscape.Controllers;

import android.annotation.SuppressLint;
import android.graphics.Color;
import android.text.Html;
import android.text.SpannableStringBuilder;
import android.text.TextUtils;
import android.view.View;
import android.widget.EditText;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.Activities.HomeActivity;
import com.example.matscape.Adapters.ResultCardsRecyclerAdapter;
import com.example.matscape.Utils.ExpressionBuilder;
import com.example.matscape.dataModels.ResultCards;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class ResultCardsController {
    private static final String TAG = "ResultCardsController";

    @SuppressLint("StaticFieldLeak")
    public static ResultCardsRecyclerAdapter mResultCardsRecyclerAdapter;
    public static List<ResultCards> resultCardsList = new ArrayList<>();
    public static int resultCardCounter = 0, selectedCard = 0;
    public static boolean isNthPowerButtonPressed = false;

    /**
     * ===================================== CALLBACK FOR DRAGGING RESULT CARDS ===========================================
     **/
    public static ItemTouchHelper.SimpleCallback callbackResultCards = new ItemTouchHelper.SimpleCallback(
            ItemTouchHelper.UP | ItemTouchHelper.DOWN,
            0) {

        @Override
        public boolean isLongPressDragEnabled() {
            return false;
        }

        /*=========================== called everytime when a card is rearranged even from several cards ================================*/
        @Override
        public boolean onMove(@NonNull RecyclerView recyclerView, @NonNull RecyclerView.ViewHolder viewHolder, @NonNull RecyclerView.ViewHolder target) {
            int fromPosition = viewHolder.getAdapterPosition();
            int toPosition = target.getAdapterPosition();

            Collections.swap(resultCardsList, fromPosition, toPosition);
            mResultCardsRecyclerAdapter.notifyItemMoved(fromPosition, toPosition);

            //updating selected card position when rearranging selected card
            if (fromPosition == selectedCard)
                selectedCard = toPosition;
            else {
                //updating card position when rearranging cards upper to lower and lower to upper w.r.t. selected card
                if (fromPosition < selectedCard && selectedCard == toPosition)
                    selectedCard--;
                if (fromPosition > selectedCard && selectedCard == toPosition)
                    selectedCard++;
            }
            return true;
        }

        @Override
        public void onSwiped(@NonNull RecyclerView.ViewHolder viewHolder, int direction) {

        }
    };

    /**
     * ================================================== ADDING RESULT CARDS ====================================================
     **/
    public static void addResultCards(int position, ResultCards receivedCard, @NonNull RecyclerView resultCardsRecyclerView) {

        SpannableStringBuilder expression = new SpannableStringBuilder("");
        String message = "message";
        List<List<String>> matrix = null;
        int rows = 0, columns = 0;

        String highlightedColor;
        if (resultCardCounter == 0)
            highlightedColor = "#2196F3";
        else
            highlightedColor = "#FFFFFF";

        if (receivedCard != null) {
            expression = receivedCard.getExpressionString();
            message = receivedCard.getMessage();
            matrix = receivedCard.getResultMatrix();
            rows = receivedCard.getMatrixRows();
            columns = receivedCard.getMatrixColumns();
        }

        resultCardsList.add(position, new ResultCards(expression,
                0,
                new StringBuilder(),
                new ArrayList<>(),
                message,
                matrix,
                rows,
                columns,
                highlightedColor
        ));

        mResultCardsRecyclerAdapter.notifyItemInserted(position);

        resultCardsRecyclerView.scrollToPosition(position);

        resultCardCounter++;

    }

    //TODO optimise for auto inputs of multiply when ')' , letter , numbers etc.. encounter

    /**
     * ====================================== METHOD FOR MATRIX CARDS CLICK INPUT CONTROL =================================
     **/
    public static void MatrixCardsOnClick(@NonNull EditText editText, int position) {
        //cursor position and expression retrieval
        int cursorPosition = editText.getSelectionStart();
        SpannableStringBuilder expressionText = resultCardsList.get(selectedCard).getExpressionString();
        StringBuilder calculationString = resultCardsList.get(selectedCard).getCalculationString();
        List<Integer> calculationStringIndexList = resultCardsList.get(selectedCard).getCalculationStringIndexList();
        int mappedIndex = 0;
        if (cursorPosition > 0)
            mappedIndex = calculationStringIndexList.get(cursorPosition - 1) + 1;

        //clicked matrix name
        String matrixName = MatrixCardsController.matrixCardsList.get(position).getMatrixName();

        //setting text to selected expression field
        if (calculationString.length() != 0 && calculationString.length() > mappedIndex && calculationString.charAt(mappedIndex) == ')') {
            resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "•" + matrixName));
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 2);
        } else {
            resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, matrixName));
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
        }

        ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);

        //updating after usage
        calculationString = ExpressionBuilder.generateCalculationString(expressionText);
        calculationStringIndexList = ExpressionBuilder.generateCalculationStringIndexList(expressionText);

        resultCardsList.get(selectedCard).setCalculationString(calculationString);
        resultCardsList.get(selectedCard).setCalculationStringIndexList(calculationStringIndexList);
    }

    /**
     * ======================================= METHOD FOR HOME KEYBOARD INPUT CONTROL =====================================
     **/
    public static void HomeKeyboardInputControl(@NonNull EditText editText, View view) {

        int cursorPosition = editText.getSelectionStart();
        SpannableStringBuilder expressionText = resultCardsList.get(selectedCard).getExpressionString();
        StringBuilder calculationString = resultCardsList.get(selectedCard).getCalculationString();
        List<Integer> calculationStringIndexList = resultCardsList.get(selectedCard).getCalculationStringIndexList();
        int mappedIndex = 0;
        if (cursorPosition > 0)
            mappedIndex = calculationStringIndexList.get(cursorPosition - 1) + 1;

        for (int i = 0; i < 10; i++)
            if (view == HomeActivity.numpadButtons[i]) {
                //making numpad numbers superscript when nth power button is pressed
                if (calculationString.length() != 0 && calculationString.length() > mappedIndex && calculationString.charAt(mappedIndex) == ')') {
                    if (isNthPowerButtonPressed)
                        expressionText.insert(cursorPosition, Html.fromHtml("<sup><small>" + "•" + i + "</small></sup>"));
                    else
                        expressionText.insert(cursorPosition, "•" + i);
                    resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 2);
                } else {
                    if (isNthPowerButtonPressed)
                        expressionText.insert(cursorPosition, Html.fromHtml("<sup><small>" + i + "</small></sup>"));
                    else
                        expressionText.insert(cursorPosition, String.valueOf(i));
                    resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
                }

                resultCardsList.get(selectedCard).setExpressionString(expressionText);

                ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
            }

        //multiply 'x' button
        if (view == HomeActivity.multiplyButton) {
            if (isNthPowerButtonPressed)
                expressionText.insert(cursorPosition, Html.fromHtml("<sup><small>•</small></sup>"));
            else
                expressionText.insert(cursorPosition, "•");

            resultCardsList.get(selectedCard).setExpressionString(expressionText);
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //plus '+' button
        else if (view == HomeActivity.plusButton) {
            if (isNthPowerButtonPressed)
                expressionText.insert(cursorPosition, Html.fromHtml("<sup><small>+</small></sup>"));
            else
                expressionText.insert(cursorPosition, "+");

            resultCardsList.get(selectedCard).setExpressionString(expressionText);
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //minus '-' button
        else if (view == HomeActivity.minusButton) {

            if (isNthPowerButtonPressed)
                expressionText.insert(cursorPosition, Html.fromHtml("<sup><small>-</small></sup>"));
            else
                expressionText.insert(cursorPosition, "-");

            resultCardsList.get(selectedCard).setExpressionString(expressionText);
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //divide '/' button
        else if (view == HomeActivity.divideButton) {
            resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "/"));
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //dot '.' button
        else if (view == HomeActivity.dotButton) {
            if (calculationString.length() != 0 && calculationString.length() > mappedIndex && calculationString.charAt(mappedIndex) == ')') {
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "•."));
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 2);
            } else {
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "."));
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            }

            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);

        }
        //opening bracket '(' button
        else if (view == HomeActivity.bracketOpen) {
            if (calculationString.length() != 0 && calculationString.length() > mappedIndex && calculationString.charAt(mappedIndex) == ')') {
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "•()"));
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 2);
            } else {
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "()"));
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            }
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //closing bracket ')' button
        else if (view == HomeActivity.bracketClose) {
            //skipping ')' when it is already present and taking care of cursor at end
            if (cursorPosition == expressionText.length() || expressionText.charAt(cursorPosition) != ')')
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, ")"));

            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }

        //backspace button
        else if (view == HomeActivity.backSpaceButton) {
            //cursor position must not be at start and expression field must not be empty
            if (cursorPosition > 0 && !TextUtils.isEmpty(expressionText))
                KeyboardBackSpace(cursorPosition, expressionText);
        }
        //move cursor left button
        else if (view == HomeActivity.moveCursorLeft) {
            cursorPosition = editText.getSelectionStart();
            if (cursorPosition > 0) {
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition - 1);
                ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
            }
        }
        //move cursor right button
        else if (view == HomeActivity.moveCursorRight) {
            if (cursorPosition < expressionText.length()) {
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
                ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
            }
        }
        //Determinant Button
        else if (view == HomeActivity.matOperationButtons[0]) {
            if (calculationString.length() != 0 && calculationString.length() > mappedIndex && calculationString.charAt(mappedIndex) == ')') {
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "•det()"));
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 5);
            } else {
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "det()"));
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 4);
            }

            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //Transpose Button
        else if (view == HomeActivity.matOperationButtons[1]) {
            expressionText.insert(cursorPosition, Html.fromHtml("<sup><small>T</small></sup>"));
            resultCardsList.get(selectedCard).setExpressionString(expressionText);
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //Square Button
        else if (view == HomeActivity.matOperationButtons[2]) {
            expressionText.insert(cursorPosition, Html.fromHtml("<sup><small>2</small></sup>"));
            resultCardsList.get(selectedCard).setExpressionString(expressionText);
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //Cube Button
        else if (view == HomeActivity.matOperationButtons[3]) {
            expressionText.insert(cursorPosition, Html.fromHtml("<sup><small>3</small></sup>"));
            resultCardsList.get(selectedCard).setExpressionString(expressionText);
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //Nth Power Button
        else if (view == HomeActivity.matOperationButtons[4] && HomeActivity.matOperationButtons[4] != null) {
            if (isNthPowerButtonPressed) {
                HomeActivity.matOperationButtons[4].setCardBackgroundColor(Color.parseColor("#FFFFFF"));
                isNthPowerButtonPressed = false;
            } else {
                HomeActivity.matOperationButtons[4].setCardBackgroundColor(Color.parseColor("#B0BEC5"));
                isNthPowerButtonPressed = true;
            }
        }
        //Inverse Button
        else if (view == HomeActivity.matOperationButtons[5]) {
            expressionText.insert(cursorPosition, Html.fromHtml("<sup><small>-1</small></sup>"));
            resultCardsList.get(selectedCard).setExpressionString(expressionText);
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 2);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //Trace Button
        else if (view == HomeActivity.matOperationButtons[6]) {
            if (calculationString.length() != 0 && calculationString.length() > mappedIndex && calculationString.charAt(mappedIndex) == ')') {
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "•trc()"));
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 5);
            } else {
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "trc()"));
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 4);
            }

            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //Adjoint Button
        else if (view == HomeActivity.matOperationButtons[7]) {
            if (calculationString.length() != 0 && calculationString.length() > mappedIndex && calculationString.charAt(mappedIndex) == ')') {
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "•Adj()"));
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 5);
            } else {
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "Adj()"));
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 4);
            }

            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //Minors Button
        else if (view == HomeActivity.matOperationButtons[8]) {
            if (calculationString.length() != 0 && calculationString.length() > mappedIndex && calculationString.charAt(mappedIndex) == ')') {
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "•min()"));
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 5);
            } else {
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "min()"));
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 4);
            }

            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //Cofactor Button
        else if (view == HomeActivity.matOperationButtons[9]) {
            if (calculationString.length() != 0 && calculationString.length() > mappedIndex && calculationString.charAt(mappedIndex) == ')') {
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "•Cof()"));
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 5);
            } else {
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "Cof()"));
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 4);
            }

            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }

        //updating after usage
        calculationString = ExpressionBuilder.generateCalculationString(expressionText);
        calculationStringIndexList = ExpressionBuilder.generateCalculationStringIndexList(expressionText);

        resultCardsList.get(selectedCard).setCalculationString(calculationString);
        resultCardsList.get(selectedCard).setCalculationStringIndexList(calculationStringIndexList);
    }

    //TODO handle all possible backspace scenarios in result cards

    /**
     * =================================== METHOD FOR HANDLING BACKSPACE EVENTS ==================================
     **/
    public static void KeyboardBackSpace(int selection, @NonNull SpannableStringBuilder expressionText) {
        if (selection < expressionText.length() && expressionText.charAt(selection - 1) == '(' && expressionText.charAt(selection) == ')') {
            expressionText.delete(selection - 1, selection + 1);
        } else {
            expressionText.delete(selection - 1, selection);
        }
        resultCardsList.get(selectedCard).setExpressionString(expressionText);
        resultCardsList.get(selectedCard).setCursorPosition(selection - 1);
        ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
    }
}