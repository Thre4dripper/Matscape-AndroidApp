package com.example.matscape.Adapters;

import android.annotation.SuppressLint;
import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.R;
import com.example.matscape.dataModels.ResultCards;

import java.util.List;

public class ResultCardsRecyclerAdapter extends RecyclerView.Adapter<ResultCardsRecyclerAdapter.ViewHolder> {

    private static final String TAG = "ResultCardsRecyclerAdapter";

    public static float ONE_DP;

    public  static ItemTouchHelper resultCardsTouchHelper;
    public  static ResultCardsInterface resultCardsInterface;
    public  static List<ResultCards> resultCardsList;

    //Constructor
    public ResultCardsRecyclerAdapter(Context context,List<ResultCards> list,ItemTouchHelper itemTouchHelper,ResultCardsInterface resultCardsInterface){

        resultCardsList=list;
        resultCardsTouchHelper=itemTouchHelper;
        ResultCardsRecyclerAdapter.resultCardsInterface=resultCardsInterface;

        ONE_DP = context.getResources().getDisplayMetrics().density;
    }

    @NonNull @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {

        Context context=parent.getContext();
        View view= LayoutInflater.from(context).inflate(R.layout.item_result_card,parent,false);

        return new ViewHolder(view);
    }

    @SuppressLint("ClickableViewAccessibility")
    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {

        holder.mDragButton.setOnTouchListener((view, motionEvent) -> {
            resultCardsTouchHelper.startDrag(holder);
            return true;
        });

        List<String> expression = resultCardsList.get(position).getExpression();
        ResultCardsExpressionAdapter expressionAdapter=new ResultCardsExpressionAdapter(expression);
        holder.expressionRecyclerView.setAdapter(expressionAdapter);

    }

    @Override
    public int getItemCount() {
        return resultCardsList.size();
    }

    public interface ResultCardsInterface {
        void deleteResult(int position);
        void copyResult(int position);
    }

    public static class ViewHolder extends RecyclerView.ViewHolder implements View.OnClickListener {

        ImageView mDeleteButton, mCopyButton;
        ImageView mDragButton;

        RecyclerView expressionRecyclerView;

        TextView mMessageView;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);

            expressionRecyclerView=itemView.findViewById(R.id.ExpressionRecyclerView);
            mDeleteButton=itemView.findViewById(R.id.DeleteResultButton);
            mCopyButton=itemView.findViewById(R.id.CopyResultButton);
            mDragButton=itemView.findViewById(R.id.resultCardDragButton);
            mMessageView=itemView.findViewById(R.id.ResultCardMessage);

            expressionRecyclerView.setLayoutManager(new LinearLayoutManager(itemView.getContext(),
                    LinearLayoutManager.HORIZONTAL,
                    false
            ));

            mDeleteButton.setOnClickListener(this);
            mCopyButton.setOnClickListener(this);
        }

        @Override
        public void onClick(View view) {
            if(view==mDeleteButton)
                resultCardsInterface.deleteResult(getAdapterPosition());
            else if(view==mCopyButton)
                resultCardsInterface.copyResult(getAdapterPosition());
        }
    }
}
