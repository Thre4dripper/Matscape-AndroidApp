package com.example.matscape.Adapters;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Color;
import android.graphics.Typeface;
import android.text.Editable;
import android.text.SpannableStringBuilder;
import android.text.Spanned;
import android.text.TextWatcher;
import android.text.style.AbsoluteSizeSpan;
import android.text.style.RelativeSizeSpan;
import android.text.style.StyleSpan;
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
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.Activities.HomeActivity;
import com.example.matscape.Controllers.ResultCardsController;
import com.example.matscape.R;
import com.example.matscape.dataModels.ResultCards;

import java.util.List;

public class ResultCardsRecyclerAdapter extends RecyclerView.Adapter<ResultCardsRecyclerAdapter.ViewHolder> {

    private static final String TAG = "ResultCardsRecycler";

    public static float ONE_DP;

    public static ItemTouchHelper resultCardsTouchHelper;
    public static ResultCardsInterface resultCardsInterface;
    public static List<ResultCards> resultCardsList;
    @SuppressLint("StaticFieldLeak")
    private static EditText editText;

    //Constructor
    public ResultCardsRecyclerAdapter(Context context, List<ResultCards> list, ItemTouchHelper itemTouchHelper,
                                      ResultCardsInterface resultCardsInterface) {

        resultCardsList = list;
        resultCardsTouchHelper = itemTouchHelper;
        ResultCardsRecyclerAdapter.resultCardsInterface = resultCardsInterface;

        ONE_DP = context.getResources().getDisplayMetrics().density;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {

        Context context = parent.getContext();
        View view = LayoutInflater.from(context).inflate(R.layout.item_result_card, parent, false);

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

        SpannableStringBuilder expression = resultCardsList.get(position).getExpression();
        holder.expressionField.setText(expression);
        holder.expressionField.setShowSoftInputOnFocus(false);

        if (position == ResultCardsController.selectedCard) {
            editText = holder.expressionField;
            holder.expressionField.setSelection(resultCardsList.get(position).getCursorPosition());
        }
    }

    @Override
    public int getItemCount() {
        return resultCardsList.size();
    }


    public interface ResultCardsInterface {
        void deleteResult(int position);

        void copyResult(int position);

        void clickedCard(int position,int from);
    }

    public static class ViewHolder extends RecyclerView.ViewHolder implements View.OnClickListener, View.OnTouchListener {

        EditText expressionField;
        ConstraintLayout mResultCardCL;
        ImageView mDeleteButton, mCopyButton;
        ImageView mDragButton;
        TextView mMessageView;

        @SuppressLint("ClickableViewAccessibility")
        public ViewHolder(@NonNull View itemView) {
            super(itemView);

            mResultCardCL = itemView.findViewById(R.id.ResultCardCL);
            expressionField = itemView.findViewById(R.id.ExpressionField);
            mDeleteButton = itemView.findViewById(R.id.DeleteResultButton);
            mCopyButton = itemView.findViewById(R.id.CopyResultButton);
            mDragButton = itemView.findViewById(R.id.resultCardDragButton);
            mMessageView = itemView.findViewById(R.id.ResultCardMessage);

            expressionField.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {

                }

                @Override
                public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                    ResultCardsController.resultCardsList.get(getAdapterPosition()).setExpression(
                            new SpannableStringBuilder(expressionField.getText())
                    );
                }

                @Override
                public void afterTextChanged(Editable editable) {

                }
            });

            //always select focused field's card
            expressionField.setOnFocusChangeListener((view, b) -> HomeActivity.homeNumpadCardView.setVisibility(View.VISIBLE));

            expressionField.setOnClickListener(this);
            expressionField.setOnTouchListener(this);
            mResultCardCL.setOnClickListener(this);
            mDeleteButton.setOnClickListener(this);
            mCopyButton.setOnClickListener(this);
        }

        /**
         * ======================================= METHOD FOR HOME KEYBOARD INPUT CONTROL =====================================
         **/
        public static void InitKeyboard(Context context, View view) {
            ResultCardsController.HomeKeyboardInputControl(context,editText,view);
        }

        @Override
        public void onClick(View view) {
            if (view == mDeleteButton)
                resultCardsInterface.deleteResult(getAdapterPosition());
            else if (view == mCopyButton)
                resultCardsInterface.copyResult(getAdapterPosition());
            else if (view == mResultCardCL) {
                resultCardsInterface.clickedCard(getAdapterPosition(),0);
                HomeActivity.homeNumpadCardView.setVisibility(View.VISIBLE);
                //always focus selected card's field
                expressionField.requestFocus();
            }
        }

        @SuppressLint("ClickableViewAccessibility")
        @Override
        public boolean onTouch(View view, MotionEvent motionEvent) {

            if (view == expressionField) {
                if (motionEvent.getAction() == MotionEvent.ACTION_UP)
                    resultCardsInterface.clickedCard(getAdapterPosition(),0);
            }
            return false;
        }
    }
}
