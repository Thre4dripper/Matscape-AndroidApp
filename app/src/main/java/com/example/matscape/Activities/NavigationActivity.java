package com.example.matscape.Activities;

import android.content.Intent;
import android.graphics.Color;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import com.example.matscape.Fragments.NavigationFragments.AboutFragment;
import com.example.matscape.Fragments.NavigationFragments.FeedbackFragment;
import com.example.matscape.Fragments.NavigationFragments.HTUFragment;
import com.example.matscape.Fragments.NavigationFragments.SettingsFragment;
import com.example.matscape.R;

public class NavigationActivity extends AppCompatActivity implements View.OnClickListener {

    ImageView mBackButton, mSaveButton;
    ImageView mHeaderIcon;
    TextView mHeaderTitle;
    int fragmentId;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_navigation);

        mBackButton = findViewById(R.id.NavigationActivityBack);
        mSaveButton = findViewById(R.id.NavigationActivitySave);

        mHeaderIcon=findViewById(R.id.NavHeaderIcon);
        mHeaderTitle=findViewById(R.id.NavHeaderTitle);

        mBackButton.setOnClickListener(this);
        mSaveButton.setOnClickListener(this);

        Intent receivedIntent=getIntent();
        setupFragments(receivedIntent);
    }

    public void setupFragments(Intent receivedIntent){
        fragmentId=receivedIntent.getIntExtra(HomeActivity.NAVIGATION_FRAGMENT_KEY,-1);

        mHeaderIcon.setColorFilter(this.getResources().getColor(R.color.blue_black));
        Fragment fragment = null;
        switch (fragmentId){
            case 1:
                fragment=new SettingsFragment();
                mHeaderIcon.setImageResource(R.drawable.ic_nav_settings);
                mHeaderTitle.setText(this.getString(R.string.action_settings));
                break;
            case 2:
                fragment=new HTUFragment();
                mHeaderIcon.setImageResource(R.drawable.ic_nav_htu);
                mHeaderTitle.setText(this.getString(R.string.action_htu));
                break;
            case 3:
                fragment=new FeedbackFragment();
                mHeaderIcon.setImageResource(R.drawable.ic_nav_feedback);
                mHeaderTitle.setText(this.getString(R.string.action_feedback));
                break;
            case 4:
                fragment = new AboutFragment();
                mHeaderIcon.setImageResource(R.drawable.ic_nav_about);
                mHeaderTitle.setText(this.getString(R.string.action_about));
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