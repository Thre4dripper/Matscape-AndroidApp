package com.example.matscape.Adapters;

import android.content.Context;
import android.util.Log;
import android.util.TypedValue;
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

    private static final String TAG = "MatrixCardsAdapter";

    public static float ONE_DP;
    public Context mContext;
    public static List<MatrixCards> matrixCardsList;

    public MatrixCardsRecyclerAdapter(Context context,List<MatrixCards> list){
        mContext=context;
        matrixCardsList=list;

        ONE_DP = mContext.getResources().getDisplayMetrics().density;
    }


    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view= LayoutInflater.from(mContext).inflate(R.layout.matrix_cards_layout,parent,false);

        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {

        RecyclerView.LayoutParams matrixCardsParams=new RecyclerView.LayoutParams(
                (int) (ONE_DP*150),
                matrixCardsList.get(position).getHeight()- (int) (ONE_DP*20)
        );

        matrixCardsParams.setMargins( (int) ONE_DP*12, (int) ONE_DP*12, (int) ONE_DP*12, (int) ONE_DP*12);
        holder.cardView.setLayoutParams(matrixCardsParams);

    }

    @Override
    public int getItemCount() {
        return matrixCardsList.size();
    }

    public static class ViewHolder extends RecyclerView.ViewHolder{

        CardView cardView;
        public ViewHolder(@NonNull View itemView) {
            super(itemView);

            cardView =itemView.findViewById(R.id.card);
        }
    }
}
