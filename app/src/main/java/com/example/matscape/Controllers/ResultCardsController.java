package com.example.matscape.Controllers;

import android.content.Context;
import android.util.Log;
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

        /*=========================== called everytime when a card is rearranged even from several cards ================================*/
        @Override
        public boolean onMove(@NonNull RecyclerView recyclerView, @NonNull RecyclerView.ViewHolder viewHolder, @NonNull RecyclerView.ViewHolder target) {
            int fromPosition = viewHolder.getAdapterPosition();
            int toPosition = target.getAdapterPosition();

            Collections.swap(resultCardsList, fromPosition, toPosition);
            mResultCardsRecyclerAdapter.notifyItemMoved(fromPosition, toPosition);

            //updating selected card position when rearranging selected card
            if(fromPosition==selectedCard)
                selectedCard=toPosition;
            else{
                //updating card position when rearranging cards upper to lower and lower to upper w.r.t. selected card
                if(fromPosition<selectedCard && selectedCard==toPosition)
                    selectedCard--;
                if(fromPosition>selectedCard && selectedCard==toPosition)
                    selectedCard++;
            }
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

        String highlightedColor;
        if(resultCardCounter==0)
            highlightedColor="#2196F3";
        else
            highlightedColor="#FFFFFF";

        if(receivedCard!=null)
        {
            expression=receivedCard.getExpression();
            message=receivedCard.getMessage();
            matrix=receivedCard.getResultMatrix();
            rows=receivedCard.getMatrixRows();
            columns=receivedCard.getMatrixColumns();
        }

        resultCardsList.add(position,new ResultCards(expression,
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
}
