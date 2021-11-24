package com.example.matscape.Adapters;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Color;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.constraintlayout.widget.ConstraintLayout;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.Activities.HomeActivity;
import com.example.matscape.Controllers.ResultCardsController;
import com.example.matscape.R;
import com.example.matscape.dataModels.ResultCards;

import java.util.List;

public class ResultCardsRecyclerAdapter extends RecyclerView.Adapter<ResultCardsRecyclerAdapter.ViewHolder>{

    private static final String TAG = "ResultCardsRecyclerAdapter";

    public static float ONE_DP;

    public  static ItemTouchHelper resultCardsTouchHelper;
    public  static ResultCardsInterface resultCardsInterface;
    public  static List<ResultCards> resultCardsList;

    //Constructor
    public ResultCardsRecyclerAdapter(Context context,List<ResultCards> list,ItemTouchHelper itemTouchHelper,
                                      ResultCardsInterface resultCardsInterface){

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
        holder.mDragButton.setBackgroundColor(Color.parseColor(resultCardsList.get(position).getHighlightedColor()));

        String expression = resultCardsList.get(position).getExpression();

        holder.expressionField.setText(expression);
        holder.expressionField.setShowSoftInputOnFocus(false);

    }

    @Override
    public int getItemCount() {
        return resultCardsList.size();
    }


    public interface ResultCardsInterface {
        void deleteResult(int position);
        void copyResult(int position);
        void clickedCard(int position);
    }

    public static class ViewHolder extends RecyclerView.ViewHolder implements View.OnClickListener, View.OnTouchListener{

        ConstraintLayout mResultCardCL;
        ImageView mDeleteButton, mCopyButton;
        ImageView mDragButton;

        EditText expressionField;

        TextView mMessageView;

        @SuppressLint("ClickableViewAccessibility")
        public ViewHolder(@NonNull View itemView) {
            super(itemView);

            mResultCardCL=itemView.findViewById(R.id.ResultCardCL);
            expressionField=itemView.findViewById(R.id.ExpressionField);
            mDeleteButton=itemView.findViewById(R.id.DeleteResultButton);
            mCopyButton=itemView.findViewById(R.id.CopyResultButton);
            mDragButton=itemView.findViewById(R.id.resultCardDragButton);
            mMessageView=itemView.findViewById(R.id.ResultCardMessage);

            expressionField.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {

                }

                @Override
                public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                    ResultCardsController.resultCardsList.get(getAdapterPosition()).setExpression(expressionField.getText().toString());
                }

                @Override
                public void afterTextChanged(Editable editable) {

                }
            });

            expressionField.setOnFocusChangeListener((view, b) -> HomeActivity.homeNumpadCardView.setVisibility(View.VISIBLE));

            expressionField.setOnClickListener(this);
            mResultCardCL.setOnTouchListener(this);
            mDeleteButton.setOnClickListener(this);
            mCopyButton.setOnClickListener(this);
        }

        @Override
        public void onClick(View view) {
            if(view==mDeleteButton)
                resultCardsInterface.deleteResult(getAdapterPosition());
            else if(view==mCopyButton)
                resultCardsInterface.copyResult(getAdapterPosition());
            else if(view==expressionField)
                HomeActivity.homeNumpadCardView.setVisibility(View.VISIBLE);
        }

        @SuppressLint("ClickableViewAccessibility")
        @Override
        public boolean onTouch(View view, MotionEvent motionEvent) {
            if(view==mResultCardCL)
                resultCardsInterface.clickedCard(getAdapterPosition());
            return false;
        }
    }
}
