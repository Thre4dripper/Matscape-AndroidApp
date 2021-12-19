package com.ByteMechanics.matscape.Fragments.NavigationFragments;

import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.RadioButton;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.ByteMechanics.matscape.R;
import com.google.android.material.button.MaterialButton;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;


public class FeedbackFragment extends Fragment {

    public static boolean isFeedbackBackSafe = true;
    //send button from parent Activity
    private final ImageView mSendButton;
    //for feedback content
    private String feedbackContent = "";

    //UI VIEWS
    private RadioButton mBugRadio, mFeatureRadio;
    private TextInputLayout mFeedbackLayout;
    private TextInputEditText mFeedbackField;
    private MaterialButton mJoinButton;

    //CONSTRUCTOR
    public FeedbackFragment(ImageView sendButton) {
        mSendButton = sendButton;
    }

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
        getFeedback();
        mSendButton.setOnClickListener(view1 -> sendFeedback());
    }

    /**
     * ======================================== METHOD FOR HANDLING RADIO BUTTONS ==========================================
     **/
    public void handleFeedbackRadios() {
        mBugRadio.setOnClickListener(view -> isFeedbackBackSafe = false);
        mFeatureRadio.setOnClickListener(view -> isFeedbackBackSafe = false);
    }

    /**
     * ============================================ METHOD FOR SENDING FEEDBACK ==============================================
     **/
    public void sendFeedback() {

        //feedback should not be empty
        if (!feedbackContent.isEmpty()) {
            Intent intent = new Intent(Intent.ACTION_SENDTO);

            intent.setData(Uri.parse("mailto:")); // only email apps should handle this

            intent.putExtra(Intent.EXTRA_EMAIL, new String[]{"ijlalahmad845@gmail.com"});

            if (mBugRadio.isChecked())
                intent.putExtra(Intent.EXTRA_SUBJECT, "Bug Encountered");
            else if (mFeatureRadio.isChecked())
                intent.putExtra(Intent.EXTRA_SUBJECT, "Feature Request");

            intent.putExtra(Intent.EXTRA_TEXT, feedbackContent);
            startActivity(intent);

        } else
            Toast.makeText(requireContext(), "Feedback Field is Empty", Toast.LENGTH_SHORT).show();
    }

    /**
     * ==================================== METHOD FOR GETTING FEEDBACK FROM FIELD =========================================
     **/
    public void getFeedback() {
        mFeedbackField.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {

            }

            @Override
            public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
                feedbackContent = charSequence.toString().trim();

                if (feedbackContent.equals(""))
                    mFeedbackLayout.setError("*Required");
                else
                    mFeedbackLayout.setError(null);
            }

            @Override
            public void afterTextChanged(Editable editable) {
                isFeedbackBackSafe = false;
            }
        });
    }

    /**
     * ====================================== METHOD JOIN BUTTON FOR TELEGRAM ================================================
     **/
    public void JoinTelegram() {
        mJoinButton.setOnClickListener(view -> {
            Uri uri = Uri.parse("https://t.me/joinchat/vL6zyE3Lig8yODVl"); // missing 'http://' will cause crashed
            Intent intent = new Intent(Intent.ACTION_VIEW, uri);
            startActivity(intent);
        });

    }
}