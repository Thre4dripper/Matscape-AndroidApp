package com.example.matscape.Activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.Toast;

import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import com.example.matscape.Fragments.MatrixFragment.EditMatrixFragment;
import com.example.matscape.R;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

public class ChangeMatrixActivity extends AppCompatActivity implements View.OnClickListener {

    ImageView mBackButton, mSaveButton;

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
    public void setupFragments(Intent receivedIntent) {

        int fragmentId = receivedIntent.getIntExtra(HomeActivity.CHANGE_MATRIX_ACTIVITY_KEY, -1);
        int matrixCardIndex = receivedIntent.getIntExtra(HomeActivity.MATRIX_CARD_POSITION_KEY, -1);

        Fragment fragment = null;
        switch (fragmentId) {
            case 1:
                fragment = new EditMatrixFragment(matrixCardIndex);
                break;

            case 2:
                Toast.makeText(this, "Sub Matrix Fragment", Toast.LENGTH_SHORT).show();
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
            if (EditMatrixFragment.isBackSafe) {
                super.onBackPressed();
            }
            //dialog box when something is changes to prevent accidental back
            else new MaterialAlertDialogBuilder(this)
                    .setMessage("Discard Changes")
                    .setPositiveButton("Yes", (dialogInterface, i) -> ChangeMatrixActivity.super.onBackPressed())
                    .setNegativeButton("No", (dialogInterface, i) -> dialogInterface.dismiss())
                    .show();

        } else if (view == mSaveButton) {
            if (EditMatrixFragment.isBackSafe) {
                EditMatrixFragment.SaveMatrix();
                super.onBackPressed();
            }
            //dialog box when something is changes to confirm changes
            else new MaterialAlertDialogBuilder(this)
                    .setMessage("Save Changes")
                    .setPositiveButton("Yes", (dialogInterface, i) -> {
                        ChangeMatrixActivity.super.onBackPressed();
                        EditMatrixFragment.SaveMatrix();
                    })
                    .setNegativeButton("No", (dialogInterface, i) -> dialogInterface.dismiss())
                    .show();


        }
    }
}