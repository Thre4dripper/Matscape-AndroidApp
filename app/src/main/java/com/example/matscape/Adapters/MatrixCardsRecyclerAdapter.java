package com.example.matscape.Adapters;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.cardview.widget.CardView;
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.R;
import com.example.matscape.dataModels.MatrixCards;

import java.util.List;

public class MatrixCardsRecyclerAdapter extends RecyclerView.Adapter<MatrixCardsRecyclerAdapter.ViewHolder> {

    Context mContext;
    List<MatrixCards> list;

    public MatrixCardsRecyclerAdapter(Context context){
        mContext=context;
    }
    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view= LayoutInflater.from(mContext).inflate(R.layout.matrix_cards_layout,parent,false);

        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {

    }

    @Override
    public int getItemCount() {
        return 10;
    }

    public static class ViewHolder extends RecyclerView.ViewHolder{

        CardView cardView;
        public ViewHolder(@NonNull View itemView) {
            super(itemView);

            cardView =itemView.findViewById(R.id.card);
        }
    }
}
