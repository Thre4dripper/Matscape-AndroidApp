package com.example.matscape.Fragments.MatrixFragment;

import android.os.Bundle;

import androidx.fragment.app.Fragment;

import android.text.TextUtils;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;

import com.example.matscape.R;
import com.google.android.material.textfield.TextInputEditText;
import com.google.android.material.textfield.TextInputLayout;

public class EditMatrixFragment extends Fragment implements View.OnFocusChangeListener {

    private static final String TAG = "EditMatrixFragment";

    TextInputLayout[][] matrixFieldLayouts=new TextInputLayout[5][5];
    TextInputEditText[][] matrixFields=new TextInputEditText[5][5];


    @Override
    public View onCreateView(LayoutInflater inflater, ViewGroup container,
                             Bundle savedInstanceState) {
        // Inflate the layout for this fragment
        View view=inflater.inflate(R.layout.fragment_matrix_edit, container, false);

        matrixFieldLayouts[0][0]=view.findViewById(R.id.ChangeMatrixLayout11);
        matrixFieldLayouts[0][1]=view.findViewById(R.id.ChangeMatrixLayout12);
        matrixFieldLayouts[0][2]=view.findViewById(R.id.ChangeMatrixLayout13);
        matrixFieldLayouts[0][3]=view.findViewById(R.id.ChangeMatrixLayout14);
        matrixFieldLayouts[0][4]=view.findViewById(R.id.ChangeMatrixLayout15);
        matrixFieldLayouts[1][0]=view.findViewById(R.id.ChangeMatrixLayout21);
        matrixFieldLayouts[1][1]=view.findViewById(R.id.ChangeMatrixLayout22);
        matrixFieldLayouts[1][2]=view.findViewById(R.id.ChangeMatrixLayout23);
        matrixFieldLayouts[1][3]=view.findViewById(R.id.ChangeMatrixLayout24);
        matrixFieldLayouts[1][4]=view.findViewById(R.id.ChangeMatrixLayout25);
        matrixFieldLayouts[2][0]=view.findViewById(R.id.ChangeMatrixLayout31);
        matrixFieldLayouts[2][1]=view.findViewById(R.id.ChangeMatrixLayout32);
        matrixFieldLayouts[2][2]=view.findViewById(R.id.ChangeMatrixLayout33);
        matrixFieldLayouts[2][3]=view.findViewById(R.id.ChangeMatrixLayout34);
        matrixFieldLayouts[2][4]=view.findViewById(R.id.ChangeMatrixLayout35);
        matrixFieldLayouts[3][0]=view.findViewById(R.id.ChangeMatrixLayout41);
        matrixFieldLayouts[3][1]=view.findViewById(R.id.ChangeMatrixLayout42);
        matrixFieldLayouts[3][2]=view.findViewById(R.id.ChangeMatrixLayout43);
        matrixFieldLayouts[3][3]=view.findViewById(R.id.ChangeMatrixLayout44);
        matrixFieldLayouts[3][4]=view.findViewById(R.id.ChangeMatrixLayout45);
        matrixFieldLayouts[4][0]=view.findViewById(R.id.ChangeMatrixLayout51);
        matrixFieldLayouts[4][1]=view.findViewById(R.id.ChangeMatrixLayout52);
        matrixFieldLayouts[4][2]=view.findViewById(R.id.ChangeMatrixLayout53);
        matrixFieldLayouts[4][3]=view.findViewById(R.id.ChangeMatrixLayout54);
        matrixFieldLayouts[4][4]=view.findViewById(R.id.ChangeMatrixLayout55);


        matrixFields[0][0]=view.findViewById(R.id.ChangeMatrixField11);
        matrixFields[0][1]=view.findViewById(R.id.ChangeMatrixField12);
        matrixFields[0][2]=view.findViewById(R.id.ChangeMatrixField13);
        matrixFields[0][3]=view.findViewById(R.id.ChangeMatrixField14);
        matrixFields[0][4]=view.findViewById(R.id.ChangeMatrixField15);
        matrixFields[1][0]=view.findViewById(R.id.ChangeMatrixField21);
        matrixFields[1][1]=view.findViewById(R.id.ChangeMatrixField22);
        matrixFields[1][2]=view.findViewById(R.id.ChangeMatrixField23);
        matrixFields[1][3]=view.findViewById(R.id.ChangeMatrixField24);
        matrixFields[1][4]=view.findViewById(R.id.ChangeMatrixField25);
        matrixFields[2][0]=view.findViewById(R.id.ChangeMatrixField31);
        matrixFields[2][1]=view.findViewById(R.id.ChangeMatrixField32);
        matrixFields[2][2]=view.findViewById(R.id.ChangeMatrixField33);
        matrixFields[2][3]=view.findViewById(R.id.ChangeMatrixField34);
        matrixFields[2][4]=view.findViewById(R.id.ChangeMatrixField35);
        matrixFields[3][0]=view.findViewById(R.id.ChangeMatrixField41);
        matrixFields[3][1]=view.findViewById(R.id.ChangeMatrixField42);
        matrixFields[3][2]=view.findViewById(R.id.ChangeMatrixField43);
        matrixFields[3][3]=view.findViewById(R.id.ChangeMatrixField44);
        matrixFields[3][4]=view.findViewById(R.id.ChangeMatrixField45);
        matrixFields[4][0]=view.findViewById(R.id.ChangeMatrixField51);
        matrixFields[4][1]=view.findViewById(R.id.ChangeMatrixField52);
        matrixFields[4][2]=view.findViewById(R.id.ChangeMatrixField53);
        matrixFields[4][3]=view.findViewById(R.id.ChangeMatrixField54);
        matrixFields[4][4]=view.findViewById(R.id.ChangeMatrixField55);

        for(int i=0;i<5;i++)
            for(int j=0;j<5;j++)
                    matrixFields[i][j].setOnFocusChangeListener(this);

        return view;
    }

    @Override
    public void onFocusChange(View view, boolean b) {

        for(int i=0;i<5;i++){
            for(int j=0;j<5;j++)
                if(view==matrixFields[i][j]) {
                    if(b)
                        matrixFieldLayouts[i][j].setHint((i+1)+""+(j+1));
                    else if(TextUtils.isEmpty(matrixFields[i][j].getText()))
                        matrixFieldLayouts[i][j].setHint("0");
                }
        }
    }
}