package com.example.matscape.Activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import com.example.matscape.Fragments.NavigationFragments.AboutFragment;
import com.example.matscape.Fragments.NavigationFragments.FeedbackFragment;
import com.example.matscape.Fragments.NavigationFragments.HTUFragment;
import com.example.matscape.Fragments.NavigationFragments.SettingsFragment;
import com.example.matscape.R;

public class NavigationActivity extends AppCompatActivity implements View.OnClickListener {

    ImageView mBackButton, mSaveButton;
    int fragmentId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_navigation);

        mBackButton = findViewById(R.id.NavigationActivityBack);
        mSaveButton = findViewById(R.id.NavigationActivitySave);

        mBackButton.setOnClickListener(this);
        mSaveButton.setOnClickListener(this);

        Intent receivedIntent=getIntent();
        setupFragments(receivedIntent);
    }

    public void setupFragments(Intent receivedIntent){
        fragmentId=receivedIntent.getIntExtra(HomeActivity.NAVIGATION_FRAGMENT_KEY,-1);

        Fragment fragment = null;
        switch (fragmentId){
            case 1:
                fragment=new SettingsFragment();
                break;
            case 2:
                fragment=new HTUFragment();
                break;
            case 3:
                fragment=new FeedbackFragment();
                break;
            case 4:
                fragment = new AboutFragment();
                break;

        }

        assert fragment != null;
        getSupportFragmentManager().beginTransaction().replace(R.id.NavigationFrameLayout,fragment).commit();
    }

    /**
     * ================================= ONCLICK FOR BACK AND SAVE BUTTONS FROM FRAGMENTS ==================================
     **/
    @Override
    public void onClick(View view) {
        if(view==mBackButton)
            super.onBackPressed();
        else if(view==mSaveButton)
            super.onBackPressed();
    }

    @Override
    public void onBackPressed() {
        onClick(mBackButton);
    }
}