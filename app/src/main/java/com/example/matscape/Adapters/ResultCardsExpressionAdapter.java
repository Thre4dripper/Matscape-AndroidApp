package com.example.matscape.Adapters;

import android.annotation.SuppressLint;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.R;
import com.example.matscape.dataModels.ExpressionItem;

import java.util.List;

public class ResultCardsExpressionAdapter extends RecyclerView.Adapter<ResultCardsExpressionAdapter.ViewHolder>{

    public  List<ExpressionItem> expression;
    public  ExpressionItemClickInterface expressionItemClickInterface;

    public ResultCardsExpressionAdapter(List<ExpressionItem> expression,ExpressionItemClickInterface itemClickInterface) {
        this.expression = expression;
        this.expressionItemClickInterface=itemClickInterface;
    }

    @NonNull @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {

        Context context=parent.getContext();
        View view= LayoutInflater.from(context).inflate(R.layout.item_expression,parent,false);

        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {

        holder.editText.setText(expression.get(position).getText());
        holder.editText.requestFocus();

    }

    @Override
    public int getItemCount() {
        return expression.size();
    }

    public interface ExpressionItemClickInterface{
        void expressionItemClick(int position);
    }
    @SuppressLint("ClickableViewAccessibility")
    public  class ViewHolder extends RecyclerView.ViewHolder {
        EditText editText;
        public ViewHolder(@NonNull View itemView) {
            super(itemView);
            editText=itemView.findViewById(R.id.ItemExpression);
            editText.setShowSoftInputOnFocus(false);
            editText.setOnTouchListener((view, motionEvent) -> {
                if(motionEvent.getAction()==MotionEvent.ACTION_DOWN)
                expressionItemClickInterface.expressionItemClick(expression.get(0).getResultCardIndex());
                return false;
            });
        }
    }
}
