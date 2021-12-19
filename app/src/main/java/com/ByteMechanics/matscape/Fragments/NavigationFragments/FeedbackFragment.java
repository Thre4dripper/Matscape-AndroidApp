package com.ByteMechanics.matscape.Fragments.NavigationFragments;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.RadioButton;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.ByteMechanics.matscape.R;
import com.google.android.material.button.MaterialButton;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;


public class FeedbackFragment extends Fragment {

    public static boolean isFeedbackBackSafe = true;
    private RadioButton mBugRadio, mFeatureRadio;
    private TextInputLayout mFeedbackLayout;
    private TextInputEditText mFeedbackField;
    private MaterialButton mJoinButton;
    private boolean isBugRadioSelected = true;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        return inflater.inflate(R.layout.fragment_nav_feedback, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        isFeedbackBackSafe = true;

        mBugRadio = view.findViewById(R.id.ReportBug);
        mFeatureRadio = view.findViewById(R.id.RequestFeature);
        mFeedbackLayout = view.findViewById(R.id.FeedbackLayout);
        mFeedbackField = view.findViewById(R.id.FeedbackField);
        mJoinButton = view.findViewById(R.id.FeedbackJoinButton);

        handleFeedbackRadios();
        JoinTelegram();
    }

    public void handleFeedbackRadios() {
        mBugRadio.setOnClickListener(view -> {
            isBugRadioSelected = true;
            isFeedbackBackSafe = false;
        });
        mFeatureRadio.setOnClickListener(view -> {
            isBugRadioSelected = false;
            isFeedbackBackSafe = false;
        });
    }

    public void JoinTelegram() {
        mJoinButton.setOnClickListener(view -> {
            Uri uri = Uri.parse("https://t.me/joinchat/vL6zyE3Lig8yODVl"); // missing 'http://' will cause crashed
            Intent intent = new Intent(Intent.ACTION_VIEW, uri);
            startActivity(intent);
        });

    }
}