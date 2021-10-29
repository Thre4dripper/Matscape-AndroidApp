package com.example.matscape.Activities;


import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.Toast;

import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.Adapters.MatrixCardsRecyclerAdapter;
import com.example.matscape.R;
import com.example.matscape.dataModels.MatrixCards;
import com.google.android.material.navigation.NavigationView;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class HomeActivity extends AppCompatActivity implements View.OnClickListener, MatrixCardsRecyclerAdapter.MatrixCardsInterface {

    private static final String TAG = "HomeActivity";
    //for navigation drawer
    DrawerLayout mDrawerLayout;
    NavigationView mNavigationView;
    Toolbar mToolbar;
    ActionBarDrawerToggle mToggle;

    //for matrix cards recycler view
    RecyclerView matrixCardsRecyclerView;
    MatrixCardsRecyclerAdapter cardsRecyclerAdapter;

    ImageView addMatrixCardsButton;
    List<MatrixCards> matrixCardsList = new ArrayList<>();
    int counter = 0;
    List<String> matrixNamesList=new ArrayList<>();

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mToolbar = findViewById(R.id.Toolbar);
        addMatrixCardsButton = findViewById(R.id.AddMatrixCardsButton);
        addMatrixCardsButton.setOnClickListener(this);

        InitNavigationDrawer();
        InitMatrixCardsRecyclerView();

        setMatrixNamesList();
    }

    /**
     * ============================================ METHOD FOR NAVIGATION DRAWER =============================================
     **/
    public void InitNavigationDrawer() {
        mDrawerLayout = findViewById(R.id.DrawerLayout);
        mNavigationView = findViewById(R.id.HomeNavigationView);

        mToggle = new ActionBarDrawerToggle(this, mDrawerLayout, mToolbar, R.string.open, R.string.close);
        mDrawerLayout.addDrawerListener(mToggle);
        mToggle.syncState();

        mNavigationView.setNavigationItemSelectedListener(item -> {
            int navMenuItemId = item.getItemId();
            if (navMenuItemId == R.id.action_settings) {
                Toast.makeText(HomeActivity.this, "action_settings Clicked", Toast.LENGTH_SHORT).show();

            } else if (navMenuItemId == R.id.action_htu) {
                Toast.makeText(HomeActivity.this, "HTU Clicked", Toast.LENGTH_SHORT).show();

            } else if (navMenuItemId == R.id.action_feedback) {
                Toast.makeText(HomeActivity.this, "feedback Clicked", Toast.LENGTH_SHORT).show();

            } else if (navMenuItemId == R.id.action_about) {
                Toast.makeText(HomeActivity.this, "action_about Clicked", Toast.LENGTH_SHORT).show();

            }

            mDrawerLayout.closeDrawer(GravityCompat.START);
            return true;
        });

    }

    public void InitMatrixCardsRecyclerView() {
        matrixCardsRecyclerView = findViewById(R.id.MatrixCardsRecyclerView);
        cardsRecyclerAdapter = new MatrixCardsRecyclerAdapter(this, matrixCardsList,this);

        matrixCardsRecyclerView.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        matrixCardsRecyclerView.setAdapter(cardsRecyclerAdapter);
    }

    @Override
    public void onClick(View view) {
        //when Add Matrix button is clicked
        if (addMatrixCardsButton.equals(view)) addMatrixCards();

    }

    @Override
    public void deleteMatrix(int position,String deletedName) {
        matrixCardsList.remove(position);
        matrixNamesList.add(deletedName);
        counter--;

        cardsRecyclerAdapter.notifyItemRemoved(position);
    }

    @Override
    public void copyMatrix(int position) {

    }

    @Override
    public void subMatrix(int position) {

    }

    @Override
    public void editMatrix(int position) {

    }

    /**
     * ================================================== ADDING MATRIX CARDS ====================================================
     **/
    public void addMatrixCards() {
        //matrices should be less than 26
        if (counter < 26) {
            List<List<String>> matrix=new ArrayList<>();

            for(int i=0;i<5;i++){
                matrix.add(new ArrayList<>());
                for(int j=0;j<5;j++)
                    matrix.get(i).add("0");
            }

            Collections.sort(matrixNamesList);

            matrixCardsList.add(new MatrixCards(matrixNamesList.get(0),
                    matrix,
                    5,
                    5,
                    14,
                    matrixCardsRecyclerView.getHeight()
            ));

            matrixNamesList.remove(0);

            cardsRecyclerAdapter.notifyItemInserted(counter);
            matrixCardsRecyclerView.scrollToPosition(counter);

            counter++;
        } else Toast.makeText(this, "Matrix Limit Reached", Toast.LENGTH_SHORT).show();
    }


    public void setMatrixNamesList() {
        for(int i=0;i<26;i++)
            matrixNamesList.add(String.valueOf((char)(i+65)));
    }
}