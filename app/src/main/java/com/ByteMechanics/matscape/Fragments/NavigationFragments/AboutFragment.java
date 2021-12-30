package com.ByteMechanics.matscape.Fragments.NavigationFragments;

import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import android.text.method.LinkMovementMethod;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import com.ByteMechanics.matscape.R;


public class AboutFragment extends Fragment {

    TextView mTnC,mPP;

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View view = inflater.inflate(R.layout.fragment_nav_about, container, false);;
        return view;
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        mTnC=view.findViewById(R.id.AboutTnc);
        mPP=view.findViewById(R.id.AboutPP);

        mTnC.setMovementMethod(LinkMovementMethod.getInstance());
        mPP.setMovementMethod(LinkMovementMethod.getInstance());
    }
}