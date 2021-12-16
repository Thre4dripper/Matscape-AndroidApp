package com.example.matscape.Fragments.NavigationFragments;

import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.fragment.app.Fragment;

import com.example.matscape.R;
import com.google.android.material.slider.Slider;

import java.util.Locale;


public class SettingsFragment extends Fragment implements Slider.OnChangeListener {

    private static final String TAG = "SettingsFragment";
    public static int rows = 5, columns = 5;
    private static Slider mRowSlider, mColumnSlider;
    private static final ImageView[][] prevMatrix=new ImageView[5][5];

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View view = inflater.inflate(R.layout.fragment_nav_settings, container, false);

        mRowSlider = view.findViewById(R.id.NavRowSlider);
        mColumnSlider = view.findViewById(R.id.NavColumnSlider);
        setSliderLabels();
        BindPreviewMatrixFields(view);
        changePreviewMatrixSize();

        return view;
    }

    public void setSliderLabels() {
        mRowSlider.setLabelFormatter(value -> String.format(Locale.ENGLISH, "Rows: %.0f", value));
        mColumnSlider.setLabelFormatter(value -> String.format(Locale.ENGLISH, "Columns: %.0f", value));

        mRowSlider.setValue(rows);
        mColumnSlider.setValue(columns);

        mRowSlider.addOnChangeListener(this);
        mColumnSlider.addOnChangeListener(this);
    }

    public void BindPreviewMatrixFields(@NonNull View view){
        prevMatrix[0][0]=view.findViewById(R.id.SettingsMatrixPrev11);
        prevMatrix[0][1]=view.findViewById(R.id.SettingsMatrixPrev12);
        prevMatrix[0][2]=view.findViewById(R.id.SettingsMatrixPrev13);
        prevMatrix[0][3]=view.findViewById(R.id.SettingsMatrixPrev14);
        prevMatrix[0][4]=view.findViewById(R.id.SettingsMatrixPrev15);
        prevMatrix[1][0]=view.findViewById(R.id.SettingsMatrixPrev21);
        prevMatrix[1][1]=view.findViewById(R.id.SettingsMatrixPrev22);
        prevMatrix[1][2]=view.findViewById(R.id.SettingsMatrixPrev23);
        prevMatrix[1][3]=view.findViewById(R.id.SettingsMatrixPrev24);
        prevMatrix[1][4]=view.findViewById(R.id.SettingsMatrixPrev25);
        prevMatrix[2][0]=view.findViewById(R.id.SettingsMatrixPrev31);
        prevMatrix[2][1]=view.findViewById(R.id.SettingsMatrixPrev32);
        prevMatrix[2][2]=view.findViewById(R.id.SettingsMatrixPrev33);
        prevMatrix[2][3]=view.findViewById(R.id.SettingsMatrixPrev34);
        prevMatrix[2][4]=view.findViewById(R.id.SettingsMatrixPrev35);
        prevMatrix[3][0]=view.findViewById(R.id.SettingsMatrixPrev41);
        prevMatrix[3][1]=view.findViewById(R.id.SettingsMatrixPrev42);
        prevMatrix[3][2]=view.findViewById(R.id.SettingsMatrixPrev43);
        prevMatrix[3][3]=view.findViewById(R.id.SettingsMatrixPrev44);
        prevMatrix[3][4]=view.findViewById(R.id.SettingsMatrixPrev45);
        prevMatrix[4][0]=view.findViewById(R.id.SettingsMatrixPrev51);
        prevMatrix[4][1]=view.findViewById(R.id.SettingsMatrixPrev52);
        prevMatrix[4][2]=view.findViewById(R.id.SettingsMatrixPrev53);
        prevMatrix[4][3]=view.findViewById(R.id.SettingsMatrixPrev54);
        prevMatrix[4][4]=view.findViewById(R.id.SettingsMatrixPrev55);

    }

    @Override
    public void onValueChange(@NonNull Slider slider, float value, boolean fromUser) {
        if (slider == mRowSlider)
            rows = (int) value;
        else if (slider == mColumnSlider)
            columns = (int) value;

        changePreviewMatrixSize();
    }

    public void changePreviewMatrixSize() {

        //resetting visibility
        for (int i = 0; i < 5; i++) {
            for (int j = 0; j < 5; j++) {
                prevMatrix[i][j].setVisibility(View.GONE);
            }
        }

        for (int i = 0; i < rows; i++) {
            for (int j = 0; j < columns; j++) {
                prevMatrix[i][j].setVisibility(View.VISIBLE);
            }
        }
    }
}