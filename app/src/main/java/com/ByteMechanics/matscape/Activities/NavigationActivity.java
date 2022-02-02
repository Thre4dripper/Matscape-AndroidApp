package com.ByteMechanics.matscape.Activities;

import android.content.Intent;
import android.content.res.ColorStateList;
import android.graphics.Color;
import android.graphics.ColorFilter;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.content.ContextCompat;
import androidx.core.graphics.drawable.DrawableCompat;
import androidx.fragment.app.Fragment;

import com.ByteMechanics.matscape.Constants.Constant;
import com.ByteMechanics.matscape.Fragments.NavigationFragments.AboutFragment;
import com.ByteMechanics.matscape.Fragments.NavigationFragments.FeedbackFragment;
import com.ByteMechanics.matscape.Fragments.NavigationFragments.HTUFragment;
import com.ByteMechanics.matscape.Fragments.NavigationFragments.SettingsFragment;
import com.ByteMechanics.matscape.R;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

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

        mHeaderIcon = findViewById(R.id.NavHeaderIcon);
        mHeaderTitle = findViewById(R.id.NavHeaderTitle);

        mBackButton.setOnClickListener(this);
        mSaveButton.setOnClickListener(this);

        Intent receivedIntent = getIntent();
        setupFragments(receivedIntent);
    }

    public void setupFragments(@NonNull Intent receivedIntent) {
        fragmentId = receivedIntent.getIntExtra(Constant.NAVIGATION_FRAGMENT_KEY, -1);

        mHeaderIcon.setColorFilter(this.getResources().getColor(R.color.icon_color));
        Fragment fragment = new Fragment();
        switch (fragmentId) {
            case Constant.NAV_SETTINGS_FRAGMENT_ID:
                fragment = new SettingsFragment();
                mHeaderIcon.setImageResource(R.drawable.ic_nav_settings);
                mHeaderTitle.setText(this.getString(R.string.action_settings));
                break;
            case Constant.NAV_HTU_FRAGMENT_ID:
                fragment = new HTUFragment();
                mHeaderIcon.setImageResource(R.drawable.ic_nav_htu);
                mHeaderTitle.setText(this.getString(R.string.action_htu));
                mSaveButton.setVisibility(View.GONE);
                break;
            case Constant.NAV_FEEDBACK_FRAGMENT_ID:
                fragment = new FeedbackFragment(mSaveButton);
                mHeaderIcon.setImageResource(R.drawable.ic_nav_feedback);
                mHeaderTitle.setText(this.getString(R.string.action_feedback));
                mSaveButton.setImageResource(R.drawable.ic_send);
                break;
            case Constant.NAV_ABOUT_FRAGMENT_ID:
                fragment = new AboutFragment();
                mHeaderIcon.setImageResource(R.drawable.ic_nav_about);
                mHeaderTitle.setText(this.getString(R.string.action_about));
                mSaveButton.setVisibility(View.GONE);
                break;

        }

        getSupportFragmentManager().beginTransaction().replace(R.id.NavigationFrameLayout, fragment).commit();
    }

    /**
     * ================================= ONCLICK FOR BACK AND SAVE BUTTONS FROM FRAGMENTS ==================================
     **/
    @Override
    public void onClick(View view) {
        if (view == mBackButton)
            switch (fragmentId) {
                case Constant.NAV_SETTINGS_FRAGMENT_ID:
                    SettingsBack();
                    break;
                case Constant.NAV_HTU_FRAGMENT_ID:
                case Constant.NAV_ABOUT_FRAGMENT_ID:
                    super.onBackPressed();
                    break;
                case Constant.NAV_FEEDBACK_FRAGMENT_ID:
                    FeedbackBack();
                    break;
            }
        else if (view == mSaveButton)
            switch (fragmentId) {
                case Constant.NAV_SETTINGS_FRAGMENT_ID:
                    SettingsSave();
                    break;
                case Constant.NAV_HTU_FRAGMENT_ID:
                case Constant.NAV_ABOUT_FRAGMENT_ID:
                    super.onBackPressed();
                    break;
            }
    }

    @Override
    public void onBackPressed() {
        onClick(mBackButton);
    }

    /**
     * ======================================= METHOD FOR HANDLING SETTINGS BACK =======================================
     **/
    public void SettingsBack() {
        //back safety
        if (SettingsFragment.isSettingsBackSafe)
            super.onBackPressed();

            //then dialog box will display when something is changed, to prevent accidental back
        else new MaterialAlertDialogBuilder(this)
                .setMessage(this.getString(R.string.discard_changes))
                .setPositiveButton(this.getString(R.string.yes), (dialogInterface, i) -> NavigationActivity.super.onBackPressed())
                .setNegativeButton(this.getString(R.string.no), (dialogInterface, i) -> dialogInterface.dismiss())
                .show();
    }

    /**
     * ======================================== METHOD FOR HANDLING SETTINGS SAVE ======================================
     **/
    public void SettingsSave() {
        if (SettingsFragment.isSettingsBackSafe) {
            SettingsFragment.SaveSettings(this);
            super.onBackPressed();
        }
        //dialog box when something is changes to confirm changes
        else new MaterialAlertDialogBuilder(this)
                .setMessage(this.getString(R.string.save_changes))
                .setPositiveButton(this.getString(R.string.yes), (dialogInterface, i) -> {
                    SettingsFragment.SaveSettings(this);
                    NavigationActivity.super.onBackPressed();
                })
                .setNegativeButton(this.getString(R.string.no), (dialogInterface, i) -> dialogInterface.dismiss())
                .show();
    }

    /**
     * ======================================= METHOD FOR HANDLING FEEDBACK'S BACK =======================================
     **/
    public void FeedbackBack() {
        //back safety
        if (FeedbackFragment.isFeedbackBackSafe)
            super.onBackPressed();

            //then dialog box will display when something is changed, to prevent accidental back
        else new MaterialAlertDialogBuilder(this)
                .setMessage(this.getString(R.string.discard_feedback))
                .setPositiveButton(this.getString(R.string.yes), (dialogInterface, i) -> NavigationActivity.super.onBackPressed())
                .setNegativeButton(this.getString(R.string.no), (dialogInterface, i) -> dialogInterface.dismiss())
                .show();
    }
}