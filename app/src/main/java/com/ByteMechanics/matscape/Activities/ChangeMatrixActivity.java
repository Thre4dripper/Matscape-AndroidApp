package com.ByteMechanics.matscape.Activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import com.ByteMechanics.matscape.Constants.Constant;
import com.ByteMechanics.matscape.Controllers.ResultCardsController;
import com.ByteMechanics.matscape.Fragments.MatrixFragments.EditMatrixFragment;
import com.ByteMechanics.matscape.Fragments.MatrixFragments.SubMatrixFragment;
import com.ByteMechanics.matscape.R;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

public class ChangeMatrixActivity extends AppCompatActivity implements View.OnClickListener {

    ImageView mBackButton, mSaveButton;
    ImageView mHeaderIcon;
    TextView mHeaderTitle;
    int fragmentId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_change_matrix);

        mBackButton = findViewById(R.id.ChangeMatrixActivityBack);
        mSaveButton = findViewById(R.id.ChangeMatrixActivitySave);

        mHeaderIcon = findViewById(R.id.ChangeMatrixHeaderIcon);
        mHeaderTitle = findViewById(R.id.ChangeMatrixHeaderTitle);

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

        mHeaderIcon.setColorFilter(this.getResources().getColor(R.color.icon_color));
        Fragment fragment = new Fragment();
        switch (fragmentId) {
            case Constant.EDIT_MATRIX_FRAGMENT_ID:
                fragment = new EditMatrixFragment(matrixCardIndex);
                mHeaderIcon.setImageResource(R.drawable.ic_mat_card_edit);
                mHeaderTitle.setText(this.getString(R.string.text_edit_matrix));
                break;

            case Constant.SUB_MATRIX_FRAGMENT_ID:
                fragment = new SubMatrixFragment(matrixCardIndex, mSaveButton);
                mHeaderIcon.setImageResource(R.drawable.ic_mat_card_sub_matrix);
                mHeaderTitle.setText(this.getString(R.string.text_sub_matrix));
                break;
        }

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
                    .setMessage(this.getString(R.string.discard_changes))
                    .setPositiveButton(this.getString(R.string.yes), (dialogInterface, i) -> ChangeMatrixActivity.super.onBackPressed())
                    .setNegativeButton(this.getString(R.string.no), (dialogInterface, i) -> dialogInterface.dismiss())
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
                .setMessage(this.getString(R.string.save_changes))
                .setPositiveButton(this.getString(R.string.yes), (dialogInterface, i) -> {
                    if(EditMatrixFragment.SaveMatrix()) {
                        //updating result on matrix changes
                        ResultCardsController.HomeKeyboardInputControl(this, new EditText(this), null);
                        ChangeMatrixActivity.super.onBackPressed();
                    }
                })
                .setNegativeButton(this.getString(R.string.no), (dialogInterface, i) -> dialogInterface.dismiss())
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
                .setMessage(this.getString(R.string.discard_changes))
                .setPositiveButton(this.getString(R.string.yes), (dialogInterface, i) -> ChangeMatrixActivity.super.onBackPressed())
                .setNegativeButton(this.getString(R.string.no), (dialogInterface, i) -> dialogInterface.dismiss())
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
                .setMessage(this.getString(R.string.save_changes))
                .setPositiveButton(this.getString(R.string.yes), (dialogInterface, i) -> {
                    SubMatrixFragment.SaveMatrix();
                    //updating result on matrix changes
                    ResultCardsController.HomeKeyboardInputControl(this, new EditText(this), null);
                    ChangeMatrixActivity.super.onBackPressed();
                })
                .setNegativeButton(this.getString(R.string.no), (dialogInterface, i) -> dialogInterface.dismiss())
                .show();
    }
}