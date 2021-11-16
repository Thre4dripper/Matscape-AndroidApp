package com.example.matscape.Controllers;

import android.content.Context;
import android.view.View;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.cardview.widget.CardView;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.Activities.HomeActivity;
import com.example.matscape.Adapters.ResultCardsRecyclerAdapter;
import com.example.matscape.R;
import com.example.matscape.dataModels.ResultCards;
import com.google.android.material.button.MaterialButton;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class ResultCardsController {

    public static ResultCardsRecyclerAdapter mResultCardsRecyclerAdapter;
    public static List<ResultCards> resultCardsList = new ArrayList<>();
    public static int resultCardCounter = 0;

    public static MaterialButton[] numpadButtons = new MaterialButton[10];
    public static MaterialButton plusButton, minusButton, multiplyButton, divideButton;
    public static MaterialButton dotButton, bracketOpen, bracketClose;

    public static CardView[] matOperationButtons = new CardView[10];
    public static CardView moveCursorLeft, moveCursorRight, backSpaceButton;

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

        @Override
        public boolean onMove(@NonNull RecyclerView recyclerView, @NonNull RecyclerView.ViewHolder viewHolder, @NonNull RecyclerView.ViewHolder target) {
            int fromPosition = viewHolder.getAdapterPosition();
            int toPosition = target.getAdapterPosition();

            Collections.swap(resultCardsList, fromPosition, toPosition);
            mResultCardsRecyclerAdapter.notifyItemMoved(fromPosition, toPosition);

            return true;
        }

        @Override
        public void onSwiped(@NonNull RecyclerView.ViewHolder viewHolder, int direction) {

        }
    };

    public static void addResultCards(Context context, int position, ResultCards receivedCard, @NonNull RecyclerView resultCardsRecyclerView) {

        resultCardsList.add(new ResultCards(new ArrayList<>(),
                null,
                null,
                0,
                0,
                14
        ));

        mResultCardsRecyclerAdapter.notifyItemInserted(position);

        resultCardsRecyclerView.scrollToPosition(position);

        resultCardCounter++;

    }

    public static void InitKeyboard(Context context,View view) {
        if(view== HomeActivity.numpadButtons[0])
            Toast.makeText(context, "1 clicked", Toast.LENGTH_SHORT).show();
    }
}
