package com.ByteMechanics.matscape.Controllers;

import android.content.Context;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.RecyclerView;

import com.ByteMechanics.matscape.Adapters.MatrixCardsRecyclerAdapter;
import com.ByteMechanics.matscape.Preferences.Preferences;
import com.ByteMechanics.matscape.models.MatrixCards;

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
    public static List<String> remainingNamesList = new ArrayList<>();
    public static List<String> NamesList = new ArrayList<>();

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
            Collections.swap(MatrixCardsController.NamesList, fromPosition, toPosition);
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

            List<List<String>> matrix;
            int rows = Preferences.getDefaultRows(context);
            int columns = Preferences.getDefaultColumns(context);
            boolean isNullMatrixType = Preferences.getDefaultMatrixType(context);

            //initialises variables when copied card is received
            if (matrixCard != null) {
                matrix = matrixCard.getMatrix();
                rows = matrixCard.getMatrixRows();
                columns = matrixCard.getMatrixColumns();
            } else {
                //null matrixCard received means New matrix is adding
                matrix = new ArrayList<>();

                if (isNullMatrixType)
                    for (int i = 0; i < rows; i++) {
                        matrix.add(new ArrayList<>());
                        for (int j = 0; j < columns; j++)
                            matrix.get(i).add("0");
                    }
                else
                    for (int i = 0; i < rows; i++) {
                        matrix.add(new ArrayList<>());
                        for (int j = 0; j < columns; j++)
                            if (i == j)
                                matrix.get(i).add("1");
                            else
                                matrix.get(i).add("0");
                    }
            }

            Collections.sort(remainingNamesList);
            matrixCardsList.add(position, new MatrixCards(remainingNamesList.get(0),
                    matrix,
                    rows,
                    columns,
                    matrixCardsRecyclerView.getHeight()
            ));

            NamesList.add(position, remainingNamesList.get(0));
            remainingNamesList.remove(0);

            mMatrixCardsRecyclerAdapter.notifyItemInserted(position);

            matrixCardsRecyclerView.scrollToPosition(position);

            matrixCardCounter++;
        } else Toast.makeText(context, "Matrix Limit Reached", Toast.LENGTH_SHORT).show();
    }

    public static void setMatrixNamesList() {
        for (int i = 0; i < 26; i++)
            remainingNamesList.add(String.valueOf((char) (i + 65)));
    }
}
