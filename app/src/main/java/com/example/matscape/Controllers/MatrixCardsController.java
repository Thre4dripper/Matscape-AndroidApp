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

    //this list is accessed by EditMatrixFragment
    public static List<MatrixCards> matrixCardsList = new ArrayList<>();
    public static int matrixCardCounter = 0;

    //this list is accessed by edit matrix name spinner
    public static List<String> remainingMatrixNamesList = new ArrayList<>();
    public static List<String> matrixNamesList=new ArrayList<>();

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
            Collections.swap(MatrixCardsController.matrixNamesList, fromPosition, toPosition);
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
    public static void addMatrixCards(Context context, int position, MatrixCards matrixCard, RecyclerView matrixCardsRecyclerView) {

        //matrices should be less than 26
        if (matrixCardCounter < 26) {

            //TODO needed to change matrix dimens and type through database when settings is implemented
            List<List<String>> matrix;
            int rows = 5, columns = 5;

            boolean copiedCard = matrixCard != null;

            //initialises variables when copied card is received
            if (copiedCard) {
                matrix = matrixCard.getMatrix();
                rows = matrixCard.getMatrixRows();
                columns = matrixCard.getMatrixColumns();
            } else {
                //null matrixCard received means New matrix is adding
                matrix = new ArrayList<>();
                for (int i = 0; i < 5; i++) {
                    matrix.add(new ArrayList<>());
                    for (int j = 0; j < 5; j++)
                        matrix.get(i).add("0");
                }
            }

            Collections.sort(remainingMatrixNamesList);
            matrixCardsList.add(position, new MatrixCards(remainingMatrixNamesList.get(0),
                    matrix,
                    rows,
                    columns,
                    matrixCardsRecyclerView.getHeight()
            ));

            matrixNamesList.add(remainingMatrixNamesList.get(0));
            remainingMatrixNamesList.remove(0);

            mMatrixCardsRecyclerAdapter.notifyItemInserted(position);

            matrixCardsRecyclerView.scrollToPosition(position);

            matrixCardCounter++;
        } else Toast.makeText(context, "Matrix Limit Reached", Toast.LENGTH_SHORT).show();
    }

    public static void setMatrixNamesList() {
        for (int i = 0; i < 26; i++)
            remainingMatrixNamesList.add(String.valueOf((char) (i + 65)));
    }
}
