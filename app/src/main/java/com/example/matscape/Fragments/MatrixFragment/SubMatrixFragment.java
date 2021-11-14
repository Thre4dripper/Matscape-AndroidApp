package com.example.matscape.Fragments.MatrixFragment;

import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.CheckBox;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;

import com.example.matscape.Controllers.MatrixCardsController;
import com.example.matscape.R;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

import java.util.ArrayList;
import java.util.List;

public class SubMatrixFragment extends Fragment implements View.OnClickListener {

    private static final String TAG = "SubMatrixFragment";
    //local variables for controlling active matrix elements
    private static final List<Integer> activeRows = new ArrayList<>();
    private static final List<Integer> activeColumns = new ArrayList<>();
    //boolean for checking changed information before returning back
    public static boolean isSubMatrixBackSafe = true;
    protected static int rows, columns;
    protected static int matrixCardIndex;
    //UI Elements
    static TextInputLayout[][] matrixFieldLayouts = new TextInputLayout[5][5];
    static TextInputEditText[][] matrixFields = new TextInputEditText[5][5];
    static CheckBox[] mRowCheckBoxes = new CheckBox[5];
    static CheckBox[] mColumnCheckBoxes = new CheckBox[5];
    //Local variables for manipulating active matrix elements for sub matrix
    private int clickedRow = -1, clickedColumn = -1;

    public SubMatrixFragment(int matrixCardIndex) {
        SubMatrixFragment.matrixCardIndex = matrixCardIndex;
        SubMatrixFragment.isSubMatrixBackSafe = true;
        activeRows.clear();
        activeColumns.clear();

    }

    public static void SaveMatrix() {
        List<List<String>> matrix = new ArrayList<>();

        //getting matrix elements from textFields
        int itr = 0;
        for (int i = 0; i < rows; i++) {
            if (activeRows.get(i) == 0)
                continue;

            matrix.add(new ArrayList<>());
            for (int j = 0; j < columns; j++) {
                if (activeColumns.get(j) == 1) {
                    if (!TextUtils.isEmpty(matrixFields[i][j].getText()))
                        matrix.get(itr).add(String.valueOf(matrixFields[i][j].getText()));
                    else
                        matrix.get(itr).add("0");
                }
            }
            itr++;

        }

        MatrixCardsController.matrixCardsList.get(matrixCardIndex).setMatrixRows(matrix.size());
        MatrixCardsController.matrixCardsList.get(matrixCardIndex).setMatrixColumns(matrix.get(0).size());
        MatrixCardsController.matrixCardsList.get(matrixCardIndex).setMatrix(matrix);

        MatrixCardsController.mMatrixCardsRecyclerAdapter.notifyItemChanged(matrixCardIndex);
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View fragmentView = inflater.inflate(R.layout.fragment_sub_matrix, container, false);

        BindMatrixFields(fragmentView);
        BindCheckBoxes(fragmentView);

        setMatrixElements(matrixCardIndex);
        return fragmentView;
    }

    /**
     * ========================================== OVERRIDE METHOD FOR CHECKBOX CLICKS ===========================================
     **/
    @Override
    public void onClick(View view) {
        isSubMatrixBackSafe=false;
        for (int i = 0; i < 5; i++) {
            if (view == mRowCheckBoxes[i]) {
                clickedRow = i;

                //setting active rows based on its checkbox status
                if (mRowCheckBoxes[i].isChecked())
                    activeRows.set(i, 1);
                else activeRows.set(i, 0);

                createSubMatrix(clickedRow, clickedColumn, mRowCheckBoxes[i].isChecked(), null, 0);
            } else if (view == mColumnCheckBoxes[i]) {
                clickedColumn = i;

                //setting active columns based on its checkbox status
                if (mColumnCheckBoxes[i].isChecked())
                    activeColumns.set(i, 1);
                else activeColumns.set(i, 0);

                createSubMatrix(clickedRow, clickedColumn, null, mColumnCheckBoxes[i].isChecked(), 1);
            }
        }

    }

    /**
     * =================================== METHOD FOR INITIALISING TEXT FIELDS AND LAYOUTS ====================================
     **/
    public void BindMatrixFields(@NonNull View view) {

        matrixFieldLayouts[0][0] = view.findViewById(R.id.SubMatrixLayout11);
        matrixFieldLayouts[0][1] = view.findViewById(R.id.SubMatrixLayout12);
        matrixFieldLayouts[0][2] = view.findViewById(R.id.SubMatrixLayout13);
        matrixFieldLayouts[0][3] = view.findViewById(R.id.SubMatrixLayout14);
        matrixFieldLayouts[0][4] = view.findViewById(R.id.SubMatrixLayout15);
        matrixFieldLayouts[1][0] = view.findViewById(R.id.SubMatrixLayout21);
        matrixFieldLayouts[1][1] = view.findViewById(R.id.SubMatrixLayout22);
        matrixFieldLayouts[1][2] = view.findViewById(R.id.SubMatrixLayout23);
        matrixFieldLayouts[1][3] = view.findViewById(R.id.SubMatrixLayout24);
        matrixFieldLayouts[1][4] = view.findViewById(R.id.SubMatrixLayout25);
        matrixFieldLayouts[2][0] = view.findViewById(R.id.SubMatrixLayout31);
        matrixFieldLayouts[2][1] = view.findViewById(R.id.SubMatrixLayout32);
        matrixFieldLayouts[2][2] = view.findViewById(R.id.SubMatrixLayout33);
        matrixFieldLayouts[2][3] = view.findViewById(R.id.SubMatrixLayout34);
        matrixFieldLayouts[2][4] = view.findViewById(R.id.SubMatrixLayout35);
        matrixFieldLayouts[3][0] = view.findViewById(R.id.SubMatrixLayout41);
        matrixFieldLayouts[3][1] = view.findViewById(R.id.SubMatrixLayout42);
        matrixFieldLayouts[3][2] = view.findViewById(R.id.SubMatrixLayout43);
        matrixFieldLayouts[3][3] = view.findViewById(R.id.SubMatrixLayout44);
        matrixFieldLayouts[3][4] = view.findViewById(R.id.SubMatrixLayout45);
        matrixFieldLayouts[4][0] = view.findViewById(R.id.SubMatrixLayout51);
        matrixFieldLayouts[4][1] = view.findViewById(R.id.SubMatrixLayout52);
        matrixFieldLayouts[4][2] = view.findViewById(R.id.SubMatrixLayout53);
        matrixFieldLayouts[4][3] = view.findViewById(R.id.SubMatrixLayout54);
        matrixFieldLayouts[4][4] = view.findViewById(R.id.SubMatrixLayout55);


        matrixFields[0][0] = view.findViewById(R.id.SubMatrixField11);
        matrixFields[0][1] = view.findViewById(R.id.SubMatrixField12);
        matrixFields[0][2] = view.findViewById(R.id.SubMatrixField13);
        matrixFields[0][3] = view.findViewById(R.id.SubMatrixField14);
        matrixFields[0][4] = view.findViewById(R.id.SubMatrixField15);
        matrixFields[1][0] = view.findViewById(R.id.SubMatrixField21);
        matrixFields[1][1] = view.findViewById(R.id.SubMatrixField22);
        matrixFields[1][2] = view.findViewById(R.id.SubMatrixField23);
        matrixFields[1][3] = view.findViewById(R.id.SubMatrixField24);
        matrixFields[1][4] = view.findViewById(R.id.SubMatrixField25);
        matrixFields[2][0] = view.findViewById(R.id.SubMatrixField31);
        matrixFields[2][1] = view.findViewById(R.id.SubMatrixField32);
        matrixFields[2][2] = view.findViewById(R.id.SubMatrixField33);
        matrixFields[2][3] = view.findViewById(R.id.SubMatrixField34);
        matrixFields[2][4] = view.findViewById(R.id.SubMatrixField35);
        matrixFields[3][0] = view.findViewById(R.id.SubMatrixField41);
        matrixFields[3][1] = view.findViewById(R.id.SubMatrixField42);
        matrixFields[3][2] = view.findViewById(R.id.SubMatrixField43);
        matrixFields[3][3] = view.findViewById(R.id.SubMatrixField44);
        matrixFields[3][4] = view.findViewById(R.id.SubMatrixField45);
        matrixFields[4][0] = view.findViewById(R.id.SubMatrixField51);
        matrixFields[4][1] = view.findViewById(R.id.SubMatrixField52);
        matrixFields[4][2] = view.findViewById(R.id.SubMatrixField53);
        matrixFields[4][3] = view.findViewById(R.id.SubMatrixField54);
        matrixFields[4][4] = view.findViewById(R.id.SubMatrixField55);

        for (int i = 0; i < 5; i++)
            for (int j = 0; j < 5; j++) {
                matrixFields[i][j].setShowSoftInputOnFocus(false);
            }
    }

    /**
     * ============================================ METHOD FOR INITIALISING CHECKBOXES ===========================================
     **/
    public void BindCheckBoxes(@NonNull View view) {
        mRowCheckBoxes[0] = view.findViewById(R.id.SubMatrixCheckR1);
        mRowCheckBoxes[1] = view.findViewById(R.id.SubMatrixCheckR2);
        mRowCheckBoxes[2] = view.findViewById(R.id.SubMatrixCheckR3);
        mRowCheckBoxes[3] = view.findViewById(R.id.SubMatrixCheckR4);
        mRowCheckBoxes[4] = view.findViewById(R.id.SubMatrixCheckR5);

        mColumnCheckBoxes[0] = view.findViewById(R.id.SubMatrixCheckC1);
        mColumnCheckBoxes[1] = view.findViewById(R.id.SubMatrixCheckC2);
        mColumnCheckBoxes[2] = view.findViewById(R.id.SubMatrixCheckC3);
        mColumnCheckBoxes[3] = view.findViewById(R.id.SubMatrixCheckC4);
        mColumnCheckBoxes[4] = view.findViewById(R.id.SubMatrixCheckC5);

        //settings on click
        for (int i = 0; i < 5; i++) {
            mRowCheckBoxes[i].setOnClickListener(this);
            mColumnCheckBoxes[i].setOnClickListener(this);
        }
    }

    /**
     * ===================================== METHOD FOR SETTING MATRIX ELEMENTS TO FIELDS =====================================
     **/
    public void setMatrixElements(int matrixPosition) {

        rows = MatrixCardsController.matrixCardsList.get(matrixPosition).getMatrixRows();
        columns = MatrixCardsController.matrixCardsList.get(matrixPosition).getMatrixColumns();

        List<List<String>> matrixElementsList = MatrixCardsController.matrixCardsList.get(matrixPosition).getMatrix();

        //Omitting zeroes
        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < columns; j++) {
                if (!matrixElementsList.get(i).get(j).equals("0")) {
                    matrixFields[i][j].setText(matrixElementsList.get(i).get(j));
                    //hint should be displayed over non-zero values
                    matrixFieldLayouts[i][j].setHint((i + 1) + "" + (j + 1));
                }

            }
        }

        //initially all rows and columns are active
        for (int i = 0; i < rows; i++)
            activeRows.add(1);
        for (int i = 0; i < columns; i++)
            activeColumns.add(1);

        changeMatrixSize();

    }


    /*
     * ============================================= CONTROL OF EDIT MATRIX UI STARTS HERE ==========================================
     */

    /**
     * ================================================ METHOD FOR CHANGING MATRIX SIZE  ===========================================
     **/
    public void changeMatrixSize() {

        //resetting visibility of matrix elements fields
        for (int i = 0; i < 5; i++) {
            for (int j = 0; j < 5; j++) {
                matrixFieldLayouts[i][j].setVisibility(View.GONE);
                matrixFields[i][j].setVisibility(View.GONE);

                mRowCheckBoxes[i].setVisibility(View.GONE);
                mColumnCheckBoxes[j].setVisibility(View.GONE);

            }
        }

        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < columns; j++) {
                matrixFieldLayouts[i][j].setVisibility(View.VISIBLE);
                matrixFields[i][j].setVisibility(View.VISIBLE);

                mRowCheckBoxes[i].setVisibility(View.VISIBLE);
                mColumnCheckBoxes[j].setVisibility(View.VISIBLE);

            }
        }

    }

    /**
     * ================================================ METHOD FOR CREATING SUB MATRIX  ===========================================
     **/
    public void createSubMatrix(int clickedRow, int clickedColumn, Boolean isRowChecked, Boolean isColumnChecked, int type) {

        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < columns; j++) {
                //when rows is unchecked then only all rows gets disabled
                //OR check for each columns if it is active or not
                if (clickedRow == i && type == 0 && (activeColumns.get(j).equals(1) || !isRowChecked)) {
                    matrixFields[i][j].setEnabled(isRowChecked);
                    matrixFieldLayouts[i][j].setEnabled(isRowChecked);
                }
                //when columns is unchecked then only all columns gets disabled
                //OR check for each rows if it is active or not
                else if (clickedColumn == j && type == 1 && (activeRows.get(i).equals(1) || !isColumnChecked)) {
                    matrixFields[i][j].setEnabled(isColumnChecked);
                    matrixFieldLayouts[i][j].setEnabled(isColumnChecked);
                }
            }
        }


    }
}