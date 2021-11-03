package com.example.matscape.Activities;

import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.Toast;

import com.example.matscape.Fragments.MatrixFragment.EditMatrixFragment;
import com.example.matscape.R;

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

        Intent receivedIntent=getIntent();
        setupFragments(receivedIntent);
    }

    /**============================================ METHOD FOR SETTING BOTH FRAGMENTS ===========================================**/
    public void setupFragments(Intent receivedIntent){

        int fragmentId=receivedIntent.getIntExtra(HomeActivity.CHANGE_MATRIX_ACTIVITY_KEY,-1);
        int matrixCardIndex=receivedIntent.getIntExtra(HomeActivity.MATRIX_CARD_POSITION_KEY, -1);

        Fragment fragment = null;
        switch (fragmentId){
            case 1:
                fragment=new EditMatrixFragment(matrixCardIndex);
                break;

            case 2:
                Toast.makeText(this, "Sub Matrix Fragment", Toast.LENGTH_SHORT).show();
                break;
        }

        assert fragment != null;
        getSupportFragmentManager().beginTransaction().replace(R.id.ChangeMatrixActivityFrameLayout,fragment).commit();
    }

    /**================================= ONCLICK FOR BACK AND SAVE BUTTONS FROM FRAGMENTS ================================== **/
    @Override
    public void onClick(View view) {
        if(view==mBackButton)
        {
            if(EditMatrixFragment.isBackSafe)
                super.onBackPressed();
            //TODO dialog box to be added for prompting when back pressed
            else
                Toast.makeText(this, "Dialog to be added", Toast.LENGTH_SHORT).show();
        }
    }
}