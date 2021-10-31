package com.example.matscape.Adapters;

import android.annotation.SuppressLint;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.R;

public class ResultCardsRecyclerAdapter extends RecyclerView.Adapter<ResultCardsRecyclerAdapter.ViewHolder> {

    Context mContext;
    ItemTouchHelper resultCardsTouchHelper;
    public ResultCardsRecyclerAdapter(Context context,ItemTouchHelper itemTouchHelper){
        mContext=context;
        resultCardsTouchHelper=itemTouchHelper;
    }

    @NonNull @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view= LayoutInflater.from(mContext).inflate(R.layout.item_result_card,parent,false);

        return new ViewHolder(view);
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {

        holder.mDragButton.setOnTouchListener(new View.OnTouchListener() {
            @Override
            public boolean onTouch(View view, MotionEvent motionEvent) {

                resultCardsTouchHelper.startDrag(holder);
                return true;

            }
        });

    }

    @Override
    public int getItemCount() {
        return 10;
    }

    public static class ViewHolder extends RecyclerView.ViewHolder{

        ImageView mDragButton;
        public ViewHolder(@NonNull View itemView) {
            super(itemView);

            mDragButton=itemView.findViewById(R.id.resultCardDragButton);
        }
    }
}
