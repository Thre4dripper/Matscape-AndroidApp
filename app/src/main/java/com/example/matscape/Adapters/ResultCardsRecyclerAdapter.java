package com.example.matscape.Adapters;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Color;
import android.text.Editable;
import android.text.SpannableStringBuilder;
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
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.Activities.HomeActivity;
import com.example.matscape.Controllers.ResultCardsController;
import com.example.matscape.R;
import com.example.matscape.models.ResultCards;

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
    public ResultCardsRecyclerAdapter(@NonNull Context context, List<ResultCards> list, ItemTouchHelper itemTouchHelper,
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

        SpannableStringBuilder expression = resultCardsList.get(position).getExpressionString();
        holder.expressionField.setText(expression);
        holder.expressionField.setShowSoftInputOnFocus(false);

        if (position == ResultCardsController.selectedCard) {
            editText = holder.expressionField;
            holder.expressionField.setSelection(resultCardsList.get(position).getCursorPosition());
        }

        holder.mMessageView.setText(resultCardsList.get(position).getMessage());

        //getting result matrix
        int rows = resultCardsList.get(position).getMatrixRows();
        int columns = resultCardsList.get(position).getMatrixColumns();
        List<List<String>> matrix = resultCardsList.get(position).getResultMatrix();

        //resetting visibility of all result matrix text views
        for (int i = 0; i < 5; i++)
            for (int j = 0; j < 5; j++)
                holder.mResultTextViews[i][j].setVisibility(View.GONE);


        //setting result
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < columns; j++) {
                holder.mResultTextViews[i][j].setText(matrix.get(i).get(j));
                holder.mResultTextViews[i][j].setVisibility(View.VISIBLE);
            }
        }
    }

    @Override
    public int getItemCount() {
        return resultCardsList.size();
    }


    public interface ResultCardsInterface {
        void deleteResult(int position);

        void copyResult(int position);

        void clickedCard(int position, int from);
    }

    public static class ViewHolder extends RecyclerView.ViewHolder implements View.OnClickListener, View.OnTouchListener {

        EditText expressionField;
        ConstraintLayout mResultCardCL;
        ImageView mDeleteButton, mCopyButton;
        ImageView mDragButton;
        TextView mMessageView;

        TextView[][] mResultTextViews = new TextView[5][5];

        @SuppressLint("ClickableViewAccessibility")
        public ViewHolder(@NonNull View itemView) {
            super(itemView);

            mResultCardCL = itemView.findViewById(R.id.ResultCardCL);
            expressionField = itemView.findViewById(R.id.ExpressionField);
            mDeleteButton = itemView.findViewById(R.id.DeleteResultButton);
            mCopyButton = itemView.findViewById(R.id.CopyResultButton);
            mDragButton = itemView.findViewById(R.id.resultCardDragButton);
            mMessageView = itemView.findViewById(R.id.ResultCardMessage);

            //initialising result matrix text views
            mResultTextViews[0][0] = itemView.findViewById(R.id.ResultCardTextView11);
            mResultTextViews[0][1] = itemView.findViewById(R.id.ResultCardTextView12);
            mResultTextViews[0][2] = itemView.findViewById(R.id.ResultCardTextView13);
            mResultTextViews[0][3] = itemView.findViewById(R.id.ResultCardTextView14);
            mResultTextViews[0][4] = itemView.findViewById(R.id.ResultCardTextView15);
            mResultTextViews[1][0] = itemView.findViewById(R.id.ResultCardTextView21);
            mResultTextViews[1][1] = itemView.findViewById(R.id.ResultCardTextView22);
            mResultTextViews[1][2] = itemView.findViewById(R.id.ResultCardTextView23);
            mResultTextViews[1][3] = itemView.findViewById(R.id.ResultCardTextView24);
            mResultTextViews[1][4] = itemView.findViewById(R.id.ResultCardTextView25);
            mResultTextViews[2][0] = itemView.findViewById(R.id.ResultCardTextView31);
            mResultTextViews[2][1] = itemView.findViewById(R.id.ResultCardTextView32);
            mResultTextViews[2][2] = itemView.findViewById(R.id.ResultCardTextView33);
            mResultTextViews[2][3] = itemView.findViewById(R.id.ResultCardTextView34);
            mResultTextViews[2][4] = itemView.findViewById(R.id.ResultCardTextView35);
            mResultTextViews[3][0] = itemView.findViewById(R.id.ResultCardTextView41);
            mResultTextViews[3][1] = itemView.findViewById(R.id.ResultCardTextView42);
            mResultTextViews[3][2] = itemView.findViewById(R.id.ResultCardTextView43);
            mResultTextViews[3][3] = itemView.findViewById(R.id.ResultCardTextView44);
            mResultTextViews[3][4] = itemView.findViewById(R.id.ResultCardTextView45);
            mResultTextViews[4][0] = itemView.findViewById(R.id.ResultCardTextView51);
            mResultTextViews[4][1] = itemView.findViewById(R.id.ResultCardTextView52);
            mResultTextViews[4][2] = itemView.findViewById(R.id.ResultCardTextView53);
            mResultTextViews[4][3] = itemView.findViewById(R.id.ResultCardTextView54);
            mResultTextViews[4][4] = itemView.findViewById(R.id.ResultCardTextView55);

            //listeners on expression field
            expressionField.addTextChangedListener(new TextWatcher() {
                @Override
                public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {

                }

                @Override
                public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                    ResultCardsController.resultCardsList.get(getAdapterPosition()).setExpressionString(
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
         * ======================================= METHOD FOR MATRIX CARDS CLICK INPUT CONTROL ================================
         **/
        public static void MatrixCardsOnClick(int position) {
            ResultCardsController.MatrixCardsOnClick(editText, position);
        }

        /**
         * ======================================= METHOD FOR HOME KEYBOARD INPUT CONTROL =====================================
         **/
        public static void InitKeyboard(View view) {
            ResultCardsController.HomeKeyboardInputControl(editText, view);
        }

        @Override
        public void onClick(View view) {
            if (view == mDeleteButton)
                resultCardsInterface.deleteResult(getAdapterPosition());
            else if (view == mCopyButton)
                resultCardsInterface.copyResult(getAdapterPosition());
            else if (view == mResultCardCL) {
                resultCardsInterface.clickedCard(getAdapterPosition(), 0);
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
                    resultCardsInterface.clickedCard(getAdapterPosition(), 0);
            }
            return false;
        }
    }
}
