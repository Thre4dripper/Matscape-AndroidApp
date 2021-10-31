package com.example.matscape.Controllers;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.Adapters.ResultCardsRecyclerAdapter;
import com.example.matscape.dataModels.ResultCards;

import java.util.ArrayList;
import java.util.List;

public class ResultCardsController {

    public static ResultCardsRecyclerAdapter mResultCardsRecyclerAdapter;
    public static List<ResultCards> resultCardsList=new ArrayList<>();
    public static int resultCardCounter=0;

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
            int fromPosition=viewHolder.getAdapterPosition();
            int toPosition=target.getAdapterPosition();

            mResultCardsRecyclerAdapter.notifyItemMoved(fromPosition,toPosition);

            return true;
        }

        @Override
        public void onSwiped(@NonNull RecyclerView.ViewHolder viewHolder, int direction) {

        }
    };

    public static void addResultCards(Context context, int position, ResultCards receivedCard, @NonNull RecyclerView resultCardsRecyclerView){

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

}
