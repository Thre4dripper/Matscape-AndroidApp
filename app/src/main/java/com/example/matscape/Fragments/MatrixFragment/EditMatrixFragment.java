package com.example.matscape.Fragments.MatrixFragment;

import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.AdapterView;
import android.widget.ArrayAdapter;
import android.widget.AutoCompleteTextView;
import android.widget.ImageView;
import android.widget.SeekBar;

import androidx.annotation.NonNull;
import androidx.cardview.widget.CardView;
import androidx.fragment.app.Fragment;

import com.example.matscape.Controllers.MatrixCardsController;
import com.example.matscape.R;
import com.google.android.material.button.MaterialButton;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Objects;

public class EditMatrixFragment extends Fragment implements View.OnFocusChangeListener,
        AdapterView.OnItemClickListener, SeekBar.OnSeekBarChangeListener, View.OnClickListener {

    private static final String TAG = "EditMatrixFragment";
    //boolean for checking changed information before returning back
    public static boolean isEditMatrixBackSafe = true;
    protected static int rows, columns;
    protected static int matrixCardIndex;
    protected static String currentMatrixName;

    //UI Elements
    static TextInputLayout[][] matrixFieldLayouts = new TextInputLayout[5][5];
    static TextInputEditText[][] matrixFields = new TextInputEditText[5][5];
    static MaterialButton[] numpadMaterialButtons = new MaterialButton[12];
    private ImageView numpadUp, numpadDown, numpadLeft, numpadRight, numpadBackSpace;
    private AutoCompleteTextView mNamesSpinner;
    private SeekBar mRowsSeekbar, mColumnsSeekbar;
    //TODO numpad visibility will be controlled by this
    public static CardView editNumpadCardView;

    //Local variables for manipulating matrix element Focus
    private int currentRow=-1, currentColumn=-1;

    //CONSTRUCTOR
    public EditMatrixFragment(int matrixCardIndex) {
        EditMatrixFragment.matrixCardIndex = matrixCardIndex;
        EditMatrixFragment.isEditMatrixBackSafe = true;
    }

    /**
     * =============================================== METHOD FOR SAVE CHANGES ==================================================
     **/
    public static void SaveMatrix() {
        List<List<String>> matrix = new ArrayList<>();

        //getting matrix elements from textFields
        for (int i = 0; i < rows; i++) {
            matrix.add(new ArrayList<>());
            for (int j = 0; j < columns; j++) {

                //0 will be added i case of empty fields
                if (!TextUtils.isEmpty(matrixFields[i][j].getText()))
                    matrix.get(i).add(String.valueOf(matrixFields[i][j].getText()));
                else
                    matrix.get(i).add("0");
            }
        }

        MatrixCardsController.matrixCardsList.get(matrixCardIndex).setMatrixName(currentMatrixName);
        MatrixCardsController.matrixCardsList.get(matrixCardIndex).setMatrixRows(rows);
        MatrixCardsController.matrixCardsList.get(matrixCardIndex).setMatrixColumns(columns);
        MatrixCardsController.matrixCardsList.get(matrixCardIndex).setMatrix(matrix);

        MatrixCardsController.mMatrixCardsRecyclerAdapter.notifyItemChanged(matrixCardIndex);
    }

    /**
     * =============================================== ON CREATE VIEW ==================================================
     **/
    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View fragmentView = inflater.inflate(R.layout.fragment_matrix_edit, container, false);
        mNamesSpinner = fragmentView.findViewById(R.id.MatrixNamesSpinner);
        mRowsSeekbar = fragmentView.findViewById(R.id.EditMatrixRowsSeekbar);
        mColumnsSeekbar = fragmentView.findViewById(R.id.EditMatrixColumnsSeekBar);
        editNumpadCardView = fragmentView.findViewById(R.id.EditNumpadCardView);
        BindMatrixFields(fragmentView);

        //inflating numpad explicitly in the parent cardView and passing that numpad view to bind its children
        View editNumpadView = inflater.inflate(R.layout.numpad_edit_matrix, editNumpadCardView, true);
        BindNumpadButtons(editNumpadView);

        setSeekBars(matrixCardIndex);
        setMatrixElements(matrixCardIndex);

        return fragmentView;
    }

    /**
     * ======================================= OVERRIDE METHOD FOR MATERIAL FIELDS ======================================
     **/
    @Override
    public void onFocusChange(View view, boolean b) {

        for (int i = 0; i < 5; i++) {
            for (int j = 0; j < 5; j++)
                if (view == matrixFields[i][j]) {
                    if (b) {
                        matrixFieldLayouts[i][j].setHint((i + 1) + "" + (j + 1));
                        currentRow = i;
                        currentColumn = j;
                    } else if (TextUtils.isEmpty(matrixFields[i][j].getText()))
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

        //TODO fix this bug of changing name even when back
        MatrixCardsController.matrixCardsList.get(matrixCardIndex).setMatrixName(currentMatrixName);
        MatrixCardsController.mMatrixCardsRecyclerAdapter.notifyItemChanged(matrixCardIndex);

        //matrix name is changed
        isEditMatrixBackSafe = false;
    }

    /**
     * ============================================ OVERRIDE METHOD FOR SEEKBARS =================================================
     **/
    @Override
    public void onProgressChanged(SeekBar seekBar, int progress, boolean b) {

        //matrix size changed
        isEditMatrixBackSafe = false;

        if (seekBar == mRowsSeekbar) rows = progress + 1;
        else if (seekBar == mColumnsSeekbar) columns = progress + 1;

        changeMatrixSize();
    }

    @Override
    public void onStartTrackingTouch(SeekBar seekBar) {

    }

    @Override
    public void onStopTrackingTouch(SeekBar seekBar) {

    }

    /**
     * =========================================== OVERRIDE METHOD FOR NUMPAD BUTTONS ===========================================
     **/
    @Override
    public void onClick(View view) {

        if (view == numpadUp) {
            currentRow--;
            moveFocus();
        } else if (view == numpadDown) {
            currentRow++;
            moveFocus();
        } else if (view == numpadLeft) {
            currentColumn--;
            moveFocus();
        } else if (view == numpadRight) {
            currentColumn++;
            moveFocus();
        } else {
            //matrix elements changed
            isEditMatrixBackSafe = false;

            int cursorPosition = matrixFields[currentRow][currentColumn].getSelectionStart();
            String currentText = Objects.requireNonNull(matrixFields[currentRow][currentColumn].getText()).toString();

            //'.' button Onclick
            if (view == numpadMaterialButtons[9]) {

                matrixFields[currentRow][currentColumn].setText(String.format("%s0%s",
                        currentText.substring(0, cursorPosition),
                        currentText.substring(cursorPosition)));

                matrixFields[currentRow][currentColumn].setSelection(cursorPosition + 1);
            }
            //'0' button Onclick
            else if (view == numpadMaterialButtons[10] &&
                    !Objects.requireNonNull(matrixFields[currentRow][currentColumn].getText()).toString().contains(".")) {

                matrixFields[currentRow][currentColumn].setText(String.format("%s.%s",
                        currentText.substring(0, cursorPosition),
                        currentText.substring(cursorPosition)));

                matrixFields[currentRow][currentColumn].setSelection(cursorPosition + 1);
            }
            //'-' button Onclick
            else if (view == numpadMaterialButtons[11]
                    && (TextUtils.isEmpty(matrixFields[currentRow][currentColumn].getText()) || cursorPosition == 0)) {

                matrixFields[currentRow][currentColumn].setText(String.format("%s-%s",
                        currentText.substring(0, cursorPosition),
                        currentText.substring(cursorPosition)));

                matrixFields[currentRow][currentColumn].setSelection(cursorPosition + 1);
            }
            //BackSpace Onclick
            else if (view == numpadBackSpace) {
                if (cursorPosition > 0) {
                    matrixFields[currentRow][currentColumn].setText(String.format("%s%s",
                            currentText.substring(0, cursorPosition - 1),
                            currentText.substring(cursorPosition)));

                    matrixFields[currentRow][currentColumn].setSelection(cursorPosition - 1);
                } else {
                    currentColumn--;
                    moveFocus();
                }

            }
            //'1-9' buttons Onclick
            else for (int i = 0; i < 9; i++) {
                    if (view == numpadMaterialButtons[i]) {

                        matrixFields[currentRow][currentColumn].setText(String.format("%s%s%s",
                                currentText.substring(0, cursorPosition), i + 1,
                                currentText.substring(cursorPosition)));

                        matrixFields[currentRow][currentColumn].setSelection(cursorPosition + 1);
                    }
                }


        }

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
     * ======================================== METHOD FOR INITIALISING NUMPAD BUTTONS =========================================
     **/
    public void BindNumpadButtons(@NonNull View view) {

        numpadMaterialButtons[0] = view.findViewById(R.id.EditNumpad1);
        numpadMaterialButtons[1] = view.findViewById(R.id.EditNumpad2);
        numpadMaterialButtons[2] = view.findViewById(R.id.EditNumpad3);
        numpadMaterialButtons[3] = view.findViewById(R.id.EditNumpad4);
        numpadMaterialButtons[4] = view.findViewById(R.id.EditNumpad5);
        numpadMaterialButtons[5] = view.findViewById(R.id.EditNumpad6);
        numpadMaterialButtons[6] = view.findViewById(R.id.EditNumpad7);
        numpadMaterialButtons[7] = view.findViewById(R.id.EditNumpad8);
        numpadMaterialButtons[8] = view.findViewById(R.id.EditNumpad9);
        numpadMaterialButtons[9] = view.findViewById(R.id.EditNumpad0);
        numpadMaterialButtons[10] = view.findViewById(R.id.EditNumpadDot);
        numpadMaterialButtons[11] = view.findViewById(R.id.EditNumpadMinus);

        numpadUp = view.findViewById(R.id.EditNumpadUp);
        numpadLeft = view.findViewById(R.id.EditNumpadLeft);
        numpadRight = view.findViewById(R.id.EditNumpadRight);
        numpadDown = view.findViewById(R.id.EditNumpadDown);
        numpadBackSpace = view.findViewById(R.id.EditNumpadBackSpace);

        for (int i = 0; i < 12; i++)
            numpadMaterialButtons[i].setOnClickListener(this);

        numpadUp.setOnClickListener(this);
        numpadLeft.setOnClickListener(this);
        numpadRight.setOnClickListener(this);
        numpadDown.setOnClickListener(this);
        numpadBackSpace.setOnClickListener(this);

    }

    /**
     * ===================================== METHOD FOR SETTING MATRIX ELEMENTS TO FIELDS =====================================
     **/
    public void setMatrixElements(int matrixPosition) {

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

        setMatrixNameSpinner(matrixPosition);

    }

    /**
     * ==================================== METHOD FOR SETTING MATRIX NAMES TO SPINNER ========================================
     **/
    public void setMatrixNameSpinner(int matrixPosition) {

        currentMatrixName = MatrixCardsController.matrixCardsList.get(matrixPosition).getMatrixName();
        mNamesSpinner.setText(currentMatrixName);

        ArrayAdapter<String> namesAdapter = new ArrayAdapter<>(getContext(), android.R.layout.simple_list_item_1, MatrixCardsController.matrixNamesList);
        mNamesSpinner.setAdapter(namesAdapter);
        mNamesSpinner.setOnItemClickListener(this);
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

    /*
     * ============================================= CONTROL OF EDIT MATRIX UI STARTS HERE ==========================================
     */
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

    /**
     * ================================================ METHOD FOR MOVING FOCUS  ===========================================
     **/
    public void moveFocus() {

        Log.d(TAG, "moveFocus: "+currentRow+" "+currentColumn);
        //when nothing is selected , first field should be selected for right and down key
        if((currentRow==-1 && currentColumn==0) || (currentRow==0 && currentColumn==-1))
            matrixFieldLayouts[0][0].requestFocus();

        //these conditions will also take care of the collision of above condition
        //when user is at 1st field, last field gets selected on left and up key, though above condition is also true for that
        //eg. current col = -1 and current row  = 0 when left is pressed
        if (currentColumn > columns - 1) {

            currentColumn = 0;
            currentRow++;

            if (currentRow > rows - 1)
                currentRow = 0;
        } else if (currentColumn < 0) {

            currentRow--;
            currentColumn = columns - 1;

            if (currentRow < 0)
                currentRow = rows - 1;
        } else if (currentRow > rows - 1) {

            currentColumn++;
            currentRow = 0;

            if (currentColumn > columns - 1)
                currentColumn = 0;
        } else if (currentRow < 0) {

            currentColumn--;
            currentRow = rows - 1;

            if (currentColumn < 0)
                currentColumn = columns - 1;
        }
        matrixFieldLayouts[currentRow][currentColumn].requestFocus();
    }
}