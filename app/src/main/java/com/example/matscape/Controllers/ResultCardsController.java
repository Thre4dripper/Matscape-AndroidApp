package com.example.matscape.Controllers;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.Adapters.ResultCardsRecyclerAdapter;

public class ResultCardsController {

    public static ResultCardsRecyclerAdapter mResultCardsRecyclerAdapter;

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

}
