package com.example.matscape.Fragments.MatrixFragment;

import android.os.Bundle;
import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.SeekBar;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;

import com.example.matscape.Controllers.MatrixCardsController;
import com.example.matscape.R;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

import java.util.Collections;
import java.util.List;

public class EditMatrixFragment extends Fragment implements View.OnFocusChangeListener,
        AdapterView.OnItemClickListener, SeekBar.OnSeekBarChangeListener {

    private static final String TAG = "EditMatrixFragment";
    //boolean for checking changed information before returning back
    //TODO back check to be handled
    public static boolean isBackSafe = true;
    TextInputLayout[][] matrixFieldLayouts = new TextInputLayout[5][5];
    TextInputEditText[][] matrixFields = new TextInputEditText[5][5];
    AutoCompleteTextView mNamesSpinner;

    SeekBar mRowsSeekbar, mColumnsSeekbar;
    int rows, columns;
    /*
    Only position is req for getting all the information from matrix cards
     */
    int matrixCardIndex;

    String currentMatrixName;

    //CONSTRUCTOR
    public EditMatrixFragment(int matrixCardIndex) {
        this.matrixCardIndex = matrixCardIndex;
    }


    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View view = inflater.inflate(R.layout.fragment_matrix_edit, container, false);
        mNamesSpinner = view.findViewById(R.id.MatrixNamesSpinner);
        mRowsSeekbar = view.findViewById(R.id.EditMatrixRowsSeekbar);
        mColumnsSeekbar = view.findViewById(R.id.EditMatrixColumnsSeekBar);

        BindMatrixFields(view);

        setMatrixElements(matrixCardIndex);

        return view;
    }


    /**
     * ======================================= OVERRIDE METHOD FOR MATERIAL FIELDS ======================================
     **/
    @Override
    public void onFocusChange(View view, boolean b) {

        for (int i = 0; i < 5; i++) {
            for (int j = 0; j < 5; j++)
                if (view == matrixFields[i][j]) {
                    if (b)
                        matrixFieldLayouts[i][j].setHint((i + 1) + "" + (j + 1));
                    else if (TextUtils.isEmpty(matrixFields[i][j].getText()))
                        matrixFieldLayouts[i][j].setHint("0");
                    break;
                }
        }
    }


    /**
     * ============================================ OVERRIDE METHOD FOR SPINNER  =============================================
     **/
    @Override
    public void onItemClick(AdapterView<?> adapterView, View view, int i, long l) {
        /*
         * All Operations are working directly on Original Names List in MatrixCardsController
         *
         * 1 - Removed selected name from Names List
         * 2 - Added previously selected name in Names List
         * 3 - Sorted List Alphabetically
         * 4 - Updated currentName Variable
         * 5 - Updated Matrix Name in CardsList Too
         * 6 - Notified Matrix Cards RecyclerAdapter to reflect back changes in the Recycler View
         */
        MatrixCardsController.matrixNamesList.remove(i);
        MatrixCardsController.matrixNamesList.add(currentMatrixName);

        Collections.sort(MatrixCardsController.matrixNamesList);

        currentMatrixName = mNamesSpinner.getText().toString();

        MatrixCardsController.matrixCardsList.get(matrixCardIndex).setMatrixName(currentMatrixName);
        MatrixCardsController.mMatrixCardsRecyclerAdapter.notifyItemChanged(matrixCardIndex);
    }

    /**
     * ============================================ OVERRIDE METHOD FOR SEEKBARS =================================================
     **/
    @Override
    public void onProgressChanged(SeekBar seekBar, int i, boolean b) {

        if (seekBar == mRowsSeekbar) rows = mRowsSeekbar.getProgress() + 1;
        else if (seekBar == mColumnsSeekbar) columns = mColumnsSeekbar.getProgress() + 1;

        changeMatrixSize();
    }

    @Override
    public void onStartTrackingTouch(SeekBar seekBar) {

    }

    @Override
    public void onStopTrackingTouch(SeekBar seekBar) {

    }


    /**
     * =================================== METHOD FOR INITIALISING TEXT FIELDS AND LAYOUTS ====================================
     **/
    public void BindMatrixFields(@NonNull View view) {

        matrixFieldLayouts[0][0] = view.findViewById(R.id.ChangeMatrixLayout11);
        matrixFieldLayouts[0][1] = view.findViewById(R.id.ChangeMatrixLayout12);
        matrixFieldLayouts[0][2] = view.findViewById(R.id.ChangeMatrixLayout13);
        matrixFieldLayouts[0][3] = view.findViewById(R.id.ChangeMatrixLayout14);
        matrixFieldLayouts[0][4] = view.findViewById(R.id.ChangeMatrixLayout15);
        matrixFieldLayouts[1][0] = view.findViewById(R.id.ChangeMatrixLayout21);
        matrixFieldLayouts[1][1] = view.findViewById(R.id.ChangeMatrixLayout22);
        matrixFieldLayouts[1][2] = view.findViewById(R.id.ChangeMatrixLayout23);
        matrixFieldLayouts[1][3] = view.findViewById(R.id.ChangeMatrixLayout24);
        matrixFieldLayouts[1][4] = view.findViewById(R.id.ChangeMatrixLayout25);
        matrixFieldLayouts[2][0] = view.findViewById(R.id.ChangeMatrixLayout31);
        matrixFieldLayouts[2][1] = view.findViewById(R.id.ChangeMatrixLayout32);
        matrixFieldLayouts[2][2] = view.findViewById(R.id.ChangeMatrixLayout33);
        matrixFieldLayouts[2][3] = view.findViewById(R.id.ChangeMatrixLayout34);
        matrixFieldLayouts[2][4] = view.findViewById(R.id.ChangeMatrixLayout35);
        matrixFieldLayouts[3][0] = view.findViewById(R.id.ChangeMatrixLayout41);
        matrixFieldLayouts[3][1] = view.findViewById(R.id.ChangeMatrixLayout42);
        matrixFieldLayouts[3][2] = view.findViewById(R.id.ChangeMatrixLayout43);
        matrixFieldLayouts[3][3] = view.findViewById(R.id.ChangeMatrixLayout44);
        matrixFieldLayouts[3][4] = view.findViewById(R.id.ChangeMatrixLayout45);
        matrixFieldLayouts[4][0] = view.findViewById(R.id.ChangeMatrixLayout51);
        matrixFieldLayouts[4][1] = view.findViewById(R.id.ChangeMatrixLayout52);
        matrixFieldLayouts[4][2] = view.findViewById(R.id.ChangeMatrixLayout53);
        matrixFieldLayouts[4][3] = view.findViewById(R.id.ChangeMatrixLayout54);
        matrixFieldLayouts[4][4] = view.findViewById(R.id.ChangeMatrixLayout55);


        matrixFields[0][0] = view.findViewById(R.id.ChangeMatrixField11);
        matrixFields[0][1] = view.findViewById(R.id.ChangeMatrixField12);
        matrixFields[0][2] = view.findViewById(R.id.ChangeMatrixField13);
        matrixFields[0][3] = view.findViewById(R.id.ChangeMatrixField14);
        matrixFields[0][4] = view.findViewById(R.id.ChangeMatrixField15);
        matrixFields[1][0] = view.findViewById(R.id.ChangeMatrixField21);
        matrixFields[1][1] = view.findViewById(R.id.ChangeMatrixField22);
        matrixFields[1][2] = view.findViewById(R.id.ChangeMatrixField23);
        matrixFields[1][3] = view.findViewById(R.id.ChangeMatrixField24);
        matrixFields[1][4] = view.findViewById(R.id.ChangeMatrixField25);
        matrixFields[2][0] = view.findViewById(R.id.ChangeMatrixField31);
        matrixFields[2][1] = view.findViewById(R.id.ChangeMatrixField32);
        matrixFields[2][2] = view.findViewById(R.id.ChangeMatrixField33);
        matrixFields[2][3] = view.findViewById(R.id.ChangeMatrixField34);
        matrixFields[2][4] = view.findViewById(R.id.ChangeMatrixField35);
        matrixFields[3][0] = view.findViewById(R.id.ChangeMatrixField41);
        matrixFields[3][1] = view.findViewById(R.id.ChangeMatrixField42);
        matrixFields[3][2] = view.findViewById(R.id.ChangeMatrixField43);
        matrixFields[3][3] = view.findViewById(R.id.ChangeMatrixField44);
        matrixFields[3][4] = view.findViewById(R.id.ChangeMatrixField45);
        matrixFields[4][0] = view.findViewById(R.id.ChangeMatrixField51);
        matrixFields[4][1] = view.findViewById(R.id.ChangeMatrixField52);
        matrixFields[4][2] = view.findViewById(R.id.ChangeMatrixField53);
        matrixFields[4][3] = view.findViewById(R.id.ChangeMatrixField54);
        matrixFields[4][4] = view.findViewById(R.id.ChangeMatrixField55);

        for (int i = 0; i < 5; i++)
            for (int j = 0; j < 5; j++) {
                matrixFields[i][j].setOnFocusChangeListener(this);
                matrixFields[i][j].setShowSoftInputOnFocus(false);
            }
    }

    /**
     * ===================================== METHOD FOR SETTING MATRIX ELEMENTS TO FIELDS =====================================
     **/
    public void setMatrixElements(int matrixPosition) {

        List<List<String>> matrixElementsList = MatrixCardsController.matrixCardsList.get(matrixPosition).getMatrix();

        //Omitting zeroes
        for (int i = 0; i < 5; i++) {
            for (int j = 0; j < 5; j++) {
                if (!matrixElementsList.get(i).get(j).equals("0"))
                    matrixFields[i][j].setText(matrixElementsList.get(i).get(j));
            }
        }

        setMatrixName(matrixPosition);
    }

    /**
     * ==================================== METHOD FOR SETTING MATRIX NAMES TO SPINNER ========================================
     **/
    public void setMatrixName(int matrixPosition) {

        currentMatrixName = MatrixCardsController.matrixCardsList.get(matrixPosition).getMatrixName();
        mNamesSpinner.setText(currentMatrixName);

        ArrayAdapter<String> namesAdapter = new ArrayAdapter<>(getContext(), android.R.layout.simple_list_item_1, MatrixCardsController.matrixNamesList);
        mNamesSpinner.setAdapter(namesAdapter);
        mNamesSpinner.setOnItemClickListener(this);

        setSeekBars(matrixPosition);
    }

    /**
     * =================================================== METHOD FOR SETTING SEEKBARS  ============================================
     **/
    public void setSeekBars(int matrixPosition) {
        rows = MatrixCardsController.matrixCardsList.get(matrixPosition).getMatrixRows();
        columns = MatrixCardsController.matrixCardsList.get(matrixPosition).getMatrixColumns();

        mRowsSeekbar.setProgress(rows - 1);
        mColumnsSeekbar.setProgress(columns - 1);

        changeMatrixSize();

        mRowsSeekbar.setOnSeekBarChangeListener(this);
        mColumnsSeekbar.setOnSeekBarChangeListener(this);
    }

    /**
     * ================================================ METHOD FOR CHANGING MATRIX SIZE  ===========================================
     **/
    public void changeMatrixSize() {

        //resetting visibility
        for (int i = 0; i < 5; i++) {
            for (int j = 0; j < 5; j++) {
                matrixFieldLayouts[i][j].setVisibility(View.GONE);
                matrixFields[i][j].setVisibility(View.GONE);
            }
        }

        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < columns; j++) {
                matrixFieldLayouts[i][j].setVisibility(View.VISIBLE);
                matrixFields[i][j].setVisibility(View.VISIBLE);
            }
        }
    }
}