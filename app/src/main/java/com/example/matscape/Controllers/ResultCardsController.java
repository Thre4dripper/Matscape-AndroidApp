package com.example.matscape.Controllers;

import android.annotation.SuppressLint;
import android.graphics.Color;
import android.text.Html;
import android.text.SpannableStringBuilder;
import android.text.TextUtils;
import android.util.Log;
import android.view.View;
import android.widget.EditText;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.Activities.HomeActivity;
import com.example.matscape.Adapters.ResultCardsRecyclerAdapter;
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
                new StringBuilder(),
                0,
                message,
                matrix,
                rows,
                columns,
                14,
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
        int selection = editText.getSelectionStart();
        SpannableStringBuilder expressionText = resultCardsList.get(selectedCard).getExpressionString();

        //clicked matrix name
        String matrixName = MatrixCardsController.matrixCardsList.get(position).getMatrixName();

        //setting text to selected expression field
        resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(selection, matrixName));
        resultCardsList.get(selectedCard).setCursorPosition(selection + 1);
        ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
    }

    /**
     * ======================================= METHOD FOR HOME KEYBOARD INPUT CONTROL =====================================
     **/
    public static void HomeKeyboardInputControl(EditText editText, View view) {
        int cursorPosition;
        SpannableStringBuilder expressionText;
        StringBuilder calculationString = new StringBuilder();
        for (int i = 0; i < 10; i++)
            if (view == HomeActivity.numpadButtons[i]) {
                cursorPosition = editText.getSelectionStart();
                expressionText = resultCardsList.get(selectedCard).getExpressionString();
                calculationString = resultCardsList.get(selectedCard).getCalculationString();
                //making numpad numbers superscript when nth power button is pressed
                if (isNthPowerButtonPressed) {
                    resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition,
                            Html.fromHtml("<sup><small>" + i + "</small></sup>")));
                } else {
                    resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, String.valueOf(i)));
                    resultCardsList.get(selectedCard).setCalculationString(calculationString.insert(cursorPosition, i));
                }
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);

                ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
            }

        //multiply 'x' button
        if (view == HomeActivity.multiplyButton) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            if (isNthPowerButtonPressed)
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition,
                        Html.fromHtml("<sup><small>•</small></sup>")));
            else
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "•"));
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //plus '+' button
        else if (view == HomeActivity.plusButton) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            if (isNthPowerButtonPressed)
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition,
                        Html.fromHtml("<sup><small>+</small></sup>")));
            else
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "+"));
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //minus '-' button
        else if (view == HomeActivity.minusButton) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            if (isNthPowerButtonPressed)
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition,
                        Html.fromHtml("<sup><small>-</small></sup>")));
            else
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "-"));
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //divide '/' button
        else if (view == HomeActivity.divideButton) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "/"));
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //dot '.' button
        else if (view == HomeActivity.dotButton) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "."));
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);

        }
        //opening bracket '(' button
        else if (view == HomeActivity.bracketOpen) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "()"));
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //closing bracket ')' button
        else if (view == HomeActivity.bracketClose) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            //skipping ')' when it is already present and taking care of cursor at end
            if (cursorPosition == expressionText.length() || expressionText.charAt(cursorPosition) != ')')
                resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, ")"));

            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }

        //backspace button
        else if (view == HomeActivity.backSpaceButton) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            calculationString = resultCardsList.get(selectedCard).getCalculationString();

            //cursor position must not be at start and expression field must not be empty
            if (cursorPosition > 0 && !TextUtils.isEmpty(expressionText))
                KeyboardBackSpace(cursorPosition, expressionText, calculationString);
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
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            if (cursorPosition < expressionText.length()) {
                resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
                ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
            }
        }
        //Determinant Button
        else if (view == HomeActivity.matOperationButtons[0]) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "det()"));
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 4);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //Transpose Button
        else if (view == HomeActivity.matOperationButtons[1]) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            expressionText.insert(cursorPosition, Html.fromHtml("<sup><small>T</small></sup>"));
            resultCardsList.get(selectedCard).setExpressionString(expressionText);
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //Square Button
        else if (view == HomeActivity.matOperationButtons[2]) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            expressionText.insert(cursorPosition, Html.fromHtml("<sup><small>2</small></sup>"));
            resultCardsList.get(selectedCard).setExpressionString(expressionText);
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //Cube Button
        else if (view == HomeActivity.matOperationButtons[3]) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
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
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            expressionText.insert(cursorPosition, Html.fromHtml("<sup><small>-1</small></sup>"));
            resultCardsList.get(selectedCard).setExpressionString(expressionText);
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 2);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //Trace Button
        else if (view == HomeActivity.matOperationButtons[6]) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "trc()"));
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 4);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //Adjoint Button
        else if (view == HomeActivity.matOperationButtons[7]) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "Adj()"));
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 4);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //Minors Button
        else if (view == HomeActivity.matOperationButtons[8]) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "min()"));
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 4);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //Cofactor Button
        else if (view == HomeActivity.matOperationButtons[9]) {
            cursorPosition = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpressionString();
            resultCardsList.get(selectedCard).setExpressionString(expressionText.insert(cursorPosition, "Cof()"));
            resultCardsList.get(selectedCard).setCursorPosition(cursorPosition + 4);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }

        Log.d(TAG, "Calculation String: " + calculationString.toString());
    }

    //TODO handle all possible backspace scenarios in result cards

    /**
     * =================================== METHOD FOR HANDLING BACKSPACE EVENTS ==================================
     **/
    public static void KeyboardBackSpace(int selection, @NonNull SpannableStringBuilder expressionText, StringBuilder calculationString) {
        if (selection < expressionText.length() && expressionText.charAt(selection - 1) == '(' && expressionText.charAt(selection) == ')') {
            resultCardsList.get(selectedCard).setExpressionString(expressionText.replace(selection - 1, selection + 1, ""));
        } else {
            resultCardsList.get(selectedCard).setExpressionString(expressionText.delete(selection - 1, selection));
            resultCardsList.get(selectedCard).setCalculationString(calculationString.delete(selection - 1, selection));
        }
        resultCardsList.get(selectedCard).setCursorPosition(selection - 1);
        ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
    }
}