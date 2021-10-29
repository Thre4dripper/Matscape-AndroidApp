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
import java.util.List;

public class HomeActivity extends AppCompatActivity implements View.OnClickListener {

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

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mToolbar = findViewById(R.id.Toolbar);
        addMatrixCardsButton = findViewById(R.id.AddMatrixCardsButton);
        addMatrixCardsButton.setOnClickListener(this);

        InitNavigationDrawer();
        InitMatrixCardsRecyclerView();
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
                Toast.makeText(HomeActivity.this, "settings Clicked", Toast.LENGTH_SHORT).show();

            } else if (navMenuItemId == R.id.action_htu) {
                Toast.makeText(HomeActivity.this, "HTU Clicked", Toast.LENGTH_SHORT).show();

            } else if (navMenuItemId == R.id.action_feedback) {
                Toast.makeText(HomeActivity.this, "feedback Clicked", Toast.LENGTH_SHORT).show();

            } else if (navMenuItemId == R.id.action_about) {
                Toast.makeText(HomeActivity.this, "about Clicked", Toast.LENGTH_SHORT).show();

            }

            mDrawerLayout.closeDrawer(GravityCompat.START);
            return true;
        });

    }

    public void InitMatrixCardsRecyclerView() {
        matrixCardsRecyclerView = findViewById(R.id.MatrixCardsRecyclerView);
        cardsRecyclerAdapter = new MatrixCardsRecyclerAdapter(this, matrixCardsList);

        matrixCardsRecyclerView.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));
        matrixCardsRecyclerView.setAdapter(cardsRecyclerAdapter);
    }

    @Override
    public void onClick(View view) {
        //when Add Matrix button is clicked
        if (addMatrixCardsButton.equals(view)) addMatrixCards();

    }

    /**
     * ================================================== ADDING MATRIX CARDS ====================================================
     **/
    public void addMatrixCards() {
        //matrices should be less than 26
        if (counter < 26) {
            matrixCardsList.add(new MatrixCards(null,
                    null,
                    0,
                    0,
                    0.0,
                    matrixCardsRecyclerView.getHeight()
            ));

            cardsRecyclerAdapter.notifyItemInserted(counter);
            matrixCardsRecyclerView.scrollToPosition(counter);

            counter++;
        } else Toast.makeText(this, "Matrix Limit Reached", Toast.LENGTH_SHORT).show();
    }

}