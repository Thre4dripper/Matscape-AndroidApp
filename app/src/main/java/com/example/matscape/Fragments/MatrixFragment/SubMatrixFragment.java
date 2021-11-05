package com.example.matscape.Fragments.MatrixFragment;

import android.os.Bundle;

import androidx.fragment.app.Fragment;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.example.matscape.R;

public class SubMatrixFragment extends Fragment {

    private static final String TAG = "SubMatrixFragment";
    //boolean for checking changed information before returning back
    public static boolean isSubMatrixBackSafe=true;
    protected static int matrixCardIndex;

    public SubMatrixFragment(int matrixCardIndex) {
        SubMatrixFragment.matrixCardIndex=matrixCardIndex;
        SubMatrixFragment.isSubMatrixBackSafe=true;
    }

    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View fragmentView=inflater.inflate(R.layout.fragment_sub_matrix, container, false);
        return fragmentView;
    }
}