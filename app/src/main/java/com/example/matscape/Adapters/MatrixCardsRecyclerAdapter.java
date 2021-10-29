package com.example.matscape.Adapters;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.cardview.widget.CardView;
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.R;
import com.example.matscape.dataModels.MatrixCards;

import java.util.List;

public class MatrixCardsRecyclerAdapter extends RecyclerView.Adapter<MatrixCardsRecyclerAdapter.ViewHolder> {

    private static final String TAG = "MatrixCardsAdapter";

    public static float ONE_DP;
    public static List<MatrixCards> matrixCardsList;
    public static MatrixCardsInterface matrixCardsInterface;
    public Context mContext;

    public MatrixCardsRecyclerAdapter(Context context, List<MatrixCards> list, MatrixCardsInterface matrixCardsInterface) {
        mContext = context;
        matrixCardsList = list;
        this.matrixCardsInterface = matrixCardsInterface;

        ONE_DP = mContext.getResources().getDisplayMetrics().density;
    }

    @NonNull
    @Override
    public ViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View view = LayoutInflater.from(mContext).inflate(R.layout.item_matrix_cards, parent, false);

        return new ViewHolder(view);
    }

    @Override
    public void onBindViewHolder(@NonNull ViewHolder holder, int position) {

        RecyclerView.LayoutParams matrixCardsParams = new RecyclerView.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                matrixCardsList.get(position).getHeight() - (int) (ONE_DP * 20)
        );

        matrixCardsParams.setMargins((int) ONE_DP * 12, (int) ONE_DP * 12, (int) ONE_DP * 12, (int) ONE_DP * 12);
        holder.mCardView.setLayoutParams(matrixCardsParams);

        holder.mMatrixName.setText(matrixCardsList.get(position).getMatrixName());

    }

    @Override
    public int getItemCount() {
        return matrixCardsList.size();
    }

    public interface MatrixCardsInterface {
        void deleteMatrix(int position,String deletedName);

        void copyMatrix(int position);

        void subMatrix(int position);

        void editMatrix(int position);
    }

    public static class ViewHolder extends RecyclerView.ViewHolder implements View.OnClickListener {

        CardView mCardView;
        TextView mMatrixName;
        TextView[][] mMatrixTextViews = new TextView[5][5];

        ImageView mDeleteButton, mCopyButton, mSubMatrixButton, mEditButton;

        public ViewHolder(@NonNull View itemView) {
            super(itemView);

            mCardView = itemView.findViewById(R.id.card);
            mMatrixName = itemView.findViewById(R.id.MatrixName);

            mMatrixTextViews[0][0] = itemView.findViewById(R.id.MatrixCardTextView11);
            mMatrixTextViews[0][1] = itemView.findViewById(R.id.MatrixCardTextView12);
            mMatrixTextViews[0][2] = itemView.findViewById(R.id.MatrixCardTextView13);
            mMatrixTextViews[0][3] = itemView.findViewById(R.id.MatrixCardTextView14);
            mMatrixTextViews[0][4] = itemView.findViewById(R.id.MatrixCardTextView15);
            mMatrixTextViews[1][0] = itemView.findViewById(R.id.MatrixCardTextView21);
            mMatrixTextViews[1][1] = itemView.findViewById(R.id.MatrixCardTextView22);
            mMatrixTextViews[1][2] = itemView.findViewById(R.id.MatrixCardTextView23);
            mMatrixTextViews[1][3] = itemView.findViewById(R.id.MatrixCardTextView24);
            mMatrixTextViews[1][4] = itemView.findViewById(R.id.MatrixCardTextView25);
            mMatrixTextViews[2][0] = itemView.findViewById(R.id.MatrixCardTextView31);
            mMatrixTextViews[2][1] = itemView.findViewById(R.id.MatrixCardTextView32);
            mMatrixTextViews[2][2] = itemView.findViewById(R.id.MatrixCardTextView33);
            mMatrixTextViews[2][3] = itemView.findViewById(R.id.MatrixCardTextView34);
            mMatrixTextViews[2][4] = itemView.findViewById(R.id.MatrixCardTextView35);
            mMatrixTextViews[3][0] = itemView.findViewById(R.id.MatrixCardTextView41);
            mMatrixTextViews[3][1] = itemView.findViewById(R.id.MatrixCardTextView42);
            mMatrixTextViews[3][2] = itemView.findViewById(R.id.MatrixCardTextView43);
            mMatrixTextViews[3][3] = itemView.findViewById(R.id.MatrixCardTextView44);
            mMatrixTextViews[3][4] = itemView.findViewById(R.id.MatrixCardTextView45);
            mMatrixTextViews[4][0] = itemView.findViewById(R.id.MatrixCardTextView51);
            mMatrixTextViews[4][1] = itemView.findViewById(R.id.MatrixCardTextView52);
            mMatrixTextViews[4][2] = itemView.findViewById(R.id.MatrixCardTextView53);
            mMatrixTextViews[4][3] = itemView.findViewById(R.id.MatrixCardTextView54);
            mMatrixTextViews[4][4] = itemView.findViewById(R.id.MatrixCardTextView55);

            mDeleteButton = itemView.findViewById(R.id.DeleteMatrixButton);
            mCopyButton = itemView.findViewById(R.id.CopyMatrixButton);
            mSubMatrixButton = itemView.findViewById(R.id.SubMatrixButton);
            mEditButton = itemView.findViewById(R.id.EditMatrixButton);

            mDeleteButton.setOnClickListener(this);
            mCopyButton.setOnClickListener(this);
            mSubMatrixButton.setOnClickListener(this);
            mEditButton.setOnClickListener(this);

        }

        @Override
        public void onClick(View view) {
            if (view == mDeleteButton) {
                matrixCardsInterface.deleteMatrix(getAdapterPosition(),mMatrixName.getText().toString());

            } else if (view == mCopyButton) {
                matrixCardsInterface.copyMatrix(getAdapterPosition());

            } else if (view == mSubMatrixButton) {
                matrixCardsInterface.subMatrix(getAdapterPosition());

            } else if (view == mEditButton) {
                matrixCardsInterface.editMatrix(getAdapterPosition());
            }
        }
    }
}
