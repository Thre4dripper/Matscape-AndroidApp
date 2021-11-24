package com.example.matscape.Controllers;

import android.content.Context;
import android.view.View;
import android.widget.Toast;

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

    public static ResultCardsRecyclerAdapter mResultCardsRecyclerAdapter;
    public static List<ResultCards> resultCardsList = new ArrayList<>();
    public static int resultCardCounter = 0,selectedCard=0;

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

        String expression="",message="message";
        List<List<String>> matrix=null;
        int rows=0,columns=0;

        if(receivedCard!=null)
        {
            expression=receivedCard.getExpression();
            message=receivedCard.getMessage();
            matrix=receivedCard.getResultMatrix();
            rows=receivedCard.getMatrixRows();
            columns=receivedCard.getMatrixColumns();
        }

        resultCardsList.add(position,new ResultCards(expression,
                message,
                matrix,
                rows,
                columns,
                14,
                "#FFFFFF"
        ));

        mResultCardsRecyclerAdapter.notifyItemInserted(position);

        resultCardsRecyclerView.scrollToPosition(position);

        resultCardCounter++;

    }

    public static void InitKeyboard(Context context,View view) {
        if(view== HomeActivity.numpadButtons[0]) {

            Toast.makeText(context,"clicked", Toast.LENGTH_SHORT).show();
        }
    }
}
