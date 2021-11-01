package com.example.matscape.Activities;

import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import android.content.Intent;
import android.os.Bundle;
import android.widget.Toast;

import com.example.matscape.Fragments.MatrixFragment.EditMatrixFragment;
import com.example.matscape.R;

public class ChangeMatrixActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_change_matrix);

        Intent intent=getIntent();

        int fragmentId=intent.getIntExtra(HomeActivity.CHANGE_MATRIX_ACTIVITY_KEY,-1);
        Fragment fragment = null;
        switch (fragmentId){
            case 1:
                fragment=new EditMatrixFragment();
                break;

            case 2:
                Toast.makeText(this, "Sub Matrix Fragment", Toast.LENGTH_SHORT).show();
                break;
        }

        getSupportFragmentManager().beginTransaction().replace(R.id.ChangeMatrixActivityFrameLayout,fragment).commit();
    }
}