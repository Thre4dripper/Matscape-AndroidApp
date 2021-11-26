package com.example.matscape.Controllers;

import android.annotation.SuppressLint;
import android.content.Context;
import android.text.Html;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.TextUtils;
import android.text.style.SuperscriptSpan;
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

    public static void addResultCards(Context context, int position, ResultCards receivedCard, @NonNull RecyclerView resultCardsRecyclerView) {

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
            expression = receivedCard.getExpression();
            message = receivedCard.getMessage();
            matrix = receivedCard.getResultMatrix();
            rows = receivedCard.getMatrixRows();
            columns = receivedCard.getMatrixColumns();
        }

        resultCardsList.add(position, new ResultCards(expression,
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

    /**
     * ======================================= METHOD FOR HOME KEYBOARD INPUT CONTROL =====================================
     **/
    public static void HomeKeyboardInputControl(Context context, EditText editText, View view) {
        int selection;
        SpannableStringBuilder expressionText;
        for (int i = 0; i < 10; i++)
            if (view == HomeActivity.numpadButtons[i]) {
                selection = editText.getSelectionStart();
                expressionText = resultCardsList.get(selectedCard).getExpression();
                resultCardsList.get(selectedCard).setExpression(expressionText.insert(selection, String.valueOf(i)));
                resultCardsList.get(selectedCard).setCursorPosition(selection + 1);
                ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
            }

        //multiply 'x' button
        if (view == HomeActivity.multiplyButton) {
            selection = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpression();
            resultCardsList.get(selectedCard).setExpression(expressionText.insert(selection, "•"));
            resultCardsList.get(selectedCard).setCursorPosition(selection + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //plus '+' button
        else if (view == HomeActivity.plusButton) {
            selection = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpression();
            resultCardsList.get(selectedCard).setExpression(expressionText.insert(selection, "+"));
            resultCardsList.get(selectedCard).setCursorPosition(selection + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //minus '-' button
        else if (view == HomeActivity.minusButton) {
            selection = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpression();
            resultCardsList.get(selectedCard).setExpression(expressionText.insert(selection, "-"));
            resultCardsList.get(selectedCard).setCursorPosition(selection + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //divide '/' button
        else if (view == HomeActivity.divideButton) {
            selection = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpression();
            resultCardsList.get(selectedCard).setExpression(expressionText.insert(selection, "/"));
            resultCardsList.get(selectedCard).setCursorPosition(selection + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //dot '.' button
        else if (view == HomeActivity.dotButton) {
            selection = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpression();
            resultCardsList.get(selectedCard).setExpression(expressionText.insert(selection, "."));
            resultCardsList.get(selectedCard).setCursorPosition(selection + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);

        }
        //opening bracket '(' button
        else if (view == HomeActivity.bracketOpen) {
            selection = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpression();
            resultCardsList.get(selectedCard).setExpression(expressionText.insert(selection, "()"));
            resultCardsList.get(selectedCard).setCursorPosition(selection + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        //closing bracket ')' button
        else if (view == HomeActivity.bracketClose) {
            selection = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpression();
            //skipping ')' when it is already present and taking care of cursor at end
            if (selection == expressionText.length() || expressionText.charAt(selection) != ')')
                resultCardsList.get(selectedCard).setExpression(expressionText.insert(selection, ")"));

            resultCardsList.get(selectedCard).setCursorPosition(selection + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }

        //backspace button
        else if (view == HomeActivity.backSpaceButton) {
            selection = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpression();
            //cursor position must not be at start and expression field must not be empty
            if (selection > 0 && !TextUtils.isEmpty(expressionText))
                KeyboardBackSpace(selection, expressionText);
        }
        //move cursor left button
        else if (view == HomeActivity.moveCursorLeft) {
            selection = editText.getSelectionStart();
            if (selection > 0) {
                resultCardsList.get(selectedCard).setCursorPosition(selection - 1);
                ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
            }
        }
        //move cursor right button
        else if (view == HomeActivity.moveCursorRight) {
            selection = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpression();
            if (selection < expressionText.length()) {
                resultCardsList.get(selectedCard).setCursorPosition(selection + 1);
                ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
            }
        }

        else if(view==HomeActivity.matOperationButtons[0])
        {
            selection = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpression();
            resultCardsList.get(selectedCard).setExpression(expressionText.insert(selection, "det()"));
            resultCardsList.get(selectedCard).setCursorPosition(selection + 4);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        else if(view==HomeActivity.matOperationButtons[1])
        {
            selection = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpression();
            expressionText.insert(selection, Html.fromHtml("<sup><small>T</small></sup>"));
            resultCardsList.get(selectedCard).setExpression(expressionText);
            resultCardsList.get(selectedCard).setCursorPosition(selection + 1);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        else if(view==HomeActivity.matOperationButtons[6])
        {
            selection = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpression();
            resultCardsList.get(selectedCard).setExpression(expressionText.insert(selection, "trc()"));
            resultCardsList.get(selectedCard).setCursorPosition(selection + 4);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        else if(view==HomeActivity.matOperationButtons[7])
        {
            selection = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpression();
            resultCardsList.get(selectedCard).setExpression(expressionText.insert(selection, "Adj()"));
            resultCardsList.get(selectedCard).setCursorPosition(selection + 4);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        else if(view==HomeActivity.matOperationButtons[8])
        {
            selection = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpression();
            resultCardsList.get(selectedCard).setExpression(expressionText.insert(selection, "min()"));
            resultCardsList.get(selectedCard).setCursorPosition(selection + 4);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }
        else if(view==HomeActivity.matOperationButtons[9])
        {
            selection = editText.getSelectionStart();
            expressionText = resultCardsList.get(selectedCard).getExpression();
            resultCardsList.get(selectedCard).setExpression(expressionText.insert(selection, "Cof()"));
            resultCardsList.get(selectedCard).setCursorPosition(selection + 4);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
        }


    }

    public static void KeyboardBackSpace(int selection, SpannableStringBuilder expressionText) {
        if (selection < expressionText.length() && expressionText.charAt(selection - 1) == '(' && expressionText.charAt(selection) == ')')
            resultCardsList.get(selectedCard).setExpression(expressionText.replace(selection - 1, selection + 1, ""));
        else
            resultCardsList.get(selectedCard).setExpression(expressionText.replace(selection - 1, selection, ""));
        resultCardsList.get(selectedCard).setCursorPosition(selection - 1);
        ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(selectedCard);
    }
}