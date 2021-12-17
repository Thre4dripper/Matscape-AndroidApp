package com.example.matscape.Activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import com.example.matscape.Constants.Constant;
import com.example.matscape.Fragments.MatrixFragments.EditMatrixFragment;
import com.example.matscape.Fragments.MatrixFragments.SubMatrixFragment;
import com.example.matscape.R;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

public class ChangeMatrixActivity extends AppCompatActivity implements View.OnClickListener {

    ImageView mBackButton, mSaveButton;
    int fragmentId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_change_matrix);

        mBackButton = findViewById(R.id.ChangeMatrixActivityBack);
        mSaveButton = findViewById(R.id.ChangeMatrixActivitySave);

        mBackButton.setOnClickListener(this);
        mSaveButton.setOnClickListener(this);

        Intent receivedIntent = getIntent();
        setupFragments(receivedIntent);
    }

    /**
     * ============================================ METHOD FOR SETTING BOTH FRAGMENTS ===========================================
     **/
    public void setupFragments(@NonNull Intent receivedIntent) {

        fragmentId = receivedIntent.getIntExtra(Constant.CHANGE_MATRIX_ACTIVITY_KEY, -1);
        int matrixCardIndex = receivedIntent.getIntExtra(Constant.MATRIX_CARD_POSITION_KEY, -1);

        Fragment fragment = null;
        switch (fragmentId) {
            case Constant.EDIT_MATRIX_FRAGMENT_ID:
                fragment = new EditMatrixFragment(matrixCardIndex);
                break;

            case Constant.SUB_MATRIX_FRAGMENT_ID:
                fragment = new SubMatrixFragment(matrixCardIndex, mSaveButton);
                break;
        }

        assert fragment != null;
        getSupportFragmentManager().beginTransaction().replace(R.id.ChangeMatrixActivityFrameLayout, fragment).commit();
    }

    /**
     * ================================= ONCLICK FOR BACK AND SAVE BUTTONS FROM FRAGMENTS ==================================
     **/
    @Override
    public void onClick(View view) {
        if (view == mBackButton) {
            //branching back button for both fragments
            if (fragmentId == Constant.EDIT_MATRIX_FRAGMENT_ID) EditMatrixBack();
            else if (fragmentId == Constant.SUB_MATRIX_FRAGMENT_ID) SubMatrixBack();
        } else if (view == mSaveButton) {
            //branching save button for both fragments
            if (fragmentId == Constant.EDIT_MATRIX_FRAGMENT_ID) EditMatrixSave();
            else if (fragmentId == Constant.SUB_MATRIX_FRAGMENT_ID) SubMatrixSave();
        }

    }

    //handled phone's back button
    @Override
    public void onBackPressed() {
        onClick(mBackButton);
    }

    /**
     * ======================================= METHOD FOR HANDLING EDIT MATRIX BACK =======================================
     **/
    public void EditMatrixBack() {
            //firstly Numpad will hide on back press
        if (EditMatrixFragment.editNumpadCardView.getVisibility() == View.VISIBLE)
            EditMatrixFragment.editNumpadCardView.setVisibility(View.GONE);

            //then back safety will work
        else if (EditMatrixFragment.isEditMatrixBackSafe)
            super.onBackPressed();

            //then dialog box will display when something is changed, to prevent accidental back
        else new MaterialAlertDialogBuilder(this)
                    .setMessage("Discard Changes")
                    .setPositiveButton("Yes", (dialogInterface, i) -> ChangeMatrixActivity.super.onBackPressed())
                    .setNegativeButton("No", (dialogInterface, i) -> dialogInterface.dismiss())
                    .show();

    }

    /**
     * ======================================= METHOD FOR HANDLING EDIT MATRIX SAVE =======================================
     **/
    public void EditMatrixSave() {
        if (EditMatrixFragment.isEditMatrixBackSafe) {
            EditMatrixFragment.SaveMatrix();
            super.onBackPressed();
        }
        //dialog box when something is changes to confirm changes
        else new MaterialAlertDialogBuilder(this)
                .setMessage("Save Changes")
                .setPositiveButton("Yes", (dialogInterface, i) -> {
                    EditMatrixFragment.SaveMatrix();
                    ChangeMatrixActivity.super.onBackPressed();
                })
                .setNegativeButton("No", (dialogInterface, i) -> dialogInterface.dismiss())
                .show();
    }

    /**
     * ======================================= METHOD FOR HANDLING SUB MATRIX BACK =======================================
     **/
    public void SubMatrixBack() {
        if (SubMatrixFragment.isSubMatrixBackSafe) {
            super.onBackPressed();
        }
        //dialog box when something is changes to prevent accidental back
        else new MaterialAlertDialogBuilder(this)
                .setMessage("Discard Changes")
                .setPositiveButton("Yes", (dialogInterface, i) -> ChangeMatrixActivity.super.onBackPressed())
                .setNegativeButton("No", (dialogInterface, i) -> dialogInterface.dismiss())
                .show();
    }

    /**
     * ======================================= METHOD FOR HANDLING SUB MATRIX SAVE =======================================
     **/
    public void SubMatrixSave() {
        if (SubMatrixFragment.isSubMatrixBackSafe) {
            SubMatrixFragment.SaveMatrix();
            super.onBackPressed();
        }
        //dialog box when something is changes to confirm changes
        else new MaterialAlertDialogBuilder(this)
                .setMessage("Save Changes")
                .setPositiveButton("Yes", (dialogInterface, i) -> {
                    SubMatrixFragment.SaveMatrix();
                    ChangeMatrixActivity.super.onBackPressed();
                })
                .setNegativeButton("No", (dialogInterface, i) -> dialogInterface.dismiss())
                .show();
    }
}