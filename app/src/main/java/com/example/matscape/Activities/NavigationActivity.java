package com.example.matscape.Activities;

import androidx.appcompat.app.AppCompatActivity;
import androidx.fragment.app.Fragment;

import android.content.Intent;
import android.os.Bundle;
import android.widget.FrameLayout;

import com.example.matscape.Fragments.AboutFragment;
import com.example.matscape.Fragments.FeedbackFragment;
import com.example.matscape.Fragments.HTUFragment;
import com.example.matscape.Fragments.SettingsFragment;
import com.example.matscape.R;

public class NavigationActivity extends AppCompatActivity {


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_navigation);

        Intent intent=getIntent();
        int fragmentId=intent.getIntExtra(HomeActivity.NAVIGATION_FRAGMENT_KEY,-1);

        Fragment fragment=null;
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
        getSupportFragmentManager().beginTransaction().replace(R.id.NavigationFrameLayout,fragment).commit();
    }
}