package com.example.matscape.Controllers;

import android.content.Context;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.Adapters.MatrixCardsRecyclerAdapter;
import com.example.matscape.dataModels.MatrixCards;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class MatrixCardsController {
    private static final String TAG = "MatrixCardsController";


    public static MatrixCardsRecyclerAdapter mMatrixCardsRecyclerAdapter;

    public static List<MatrixCards> matrixCardsList = new ArrayList<>();
    public static int matrixCardCounter = 0;
    public static List<String> matrixNamesList = new ArrayList<>();

    /**
     * ===================================== CALLBACK FOR DRAGGING MATRIX CARDS ===========================================
     **/
    public static ItemTouchHelper.SimpleCallback callbackMatrixCards = new ItemTouchHelper.SimpleCallback(
            ItemTouchHelper.LEFT | ItemTouchHelper.RIGHT,
            0) {

        @Override
        public boolean isLongPressDragEnabled() {
            return false;
        }

        @Override
        public boolean onMove(@NonNull RecyclerView recyclerView, @NonNull RecyclerView.ViewHolder viewHolder, @NonNull RecyclerView.ViewHolder target) {

            int fromPosition = viewHolder.getAdapterPosition();
            int toPosition = target.getAdapterPosition();

            Collections.swap(MatrixCardsController.matrixCardsList, fromPosition, toPosition);
            mMatrixCardsRecyclerAdapter.notifyItemMoved(fromPosition, toPosition);

            return true;
        }

        @Override
        public void onSwiped(@NonNull RecyclerView.ViewHolder viewHolder, int direction) {

        }
    };

    /**
     * ================================================== ADDING MATRIX CARDS ====================================================
     **/
    public static void addMatrixCards(Context context, int position, List<List<String>> receivedMatrix, RecyclerView matrixCardsRecyclerView) {

        //matrices should be less than 26
        if (matrixCardCounter < 26) {

            boolean copiedMatrix = receivedMatrix != null;
            //null matrix received means New matrix is adding
            if (!copiedMatrix) {
                receivedMatrix = new ArrayList<>();

                for (int i = 0; i < 5; i++) {
                    receivedMatrix.add(new ArrayList<>());
                    for (int j = 0; j < 5; j++)
                        receivedMatrix.get(i).add("0");
                }
            }

            Collections.sort(matrixNamesList);
            matrixCardsList.add(position, new MatrixCards(matrixNamesList.get(0),
                    receivedMatrix,
                    5,
                    5,
                    14,
                    matrixCardsRecyclerView.getHeight()
            ));

            matrixNamesList.remove(0);
            mMatrixCardsRecyclerAdapter.notifyItemInserted(position);

                matrixCardsRecyclerView.scrollToPosition(position);

            matrixCardCounter++;
        } else Toast.makeText(context, "Matrix Limit Reached", Toast.LENGTH_SHORT).show();
    }

    public static void setMatrixNamesList() {
        for (int i = 0; i < 26; i++)
            matrixNamesList.add(String.valueOf((char) (i + 65)));
    }
}
