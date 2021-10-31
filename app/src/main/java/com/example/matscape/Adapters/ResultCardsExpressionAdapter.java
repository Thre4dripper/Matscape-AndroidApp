package com.example.matscape.Adapters;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.R;

import java.util.List;

public class ResultCardsExpressionAdapter extends RecyclerView.Adapter<ResultCardsExpressionAdapter.ViewHolder>{

    List<String> expression;

    public ResultCardsExpressionAdapter(List<String> expression) {
        this.expression = expression;
    }

    @NonNull @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {

        Context context=parent.getContext();
        View view= LayoutInflater.from(context).inflate(R.layout.item_expression,parent,false);

        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {

    }

    @Override
    public int getItemCount() {
        return 20;
    }

    public static class ViewHolder extends RecyclerView.ViewHolder{

        public ViewHolder(@NonNull View itemView) {
            super(itemView);
        }
    }
}
