package com.example.matscape.Activities;


import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.ImageView;
import android.widget.Toast;

import com.example.matscape.Adapters.MatrixCardsRecyclerAdapter;
import com.example.matscape.R;
import com.example.matscape.dataModels.MatrixCards;
import com.google.android.material.navigation.NavigationView;

import java.util.ArrayList;
import java.util.List;

public class HomeActivity extends AppCompatActivity implements View.OnClickListener {

    private static final String TAG = "HomeActivity";
    //for navigation drawer
    DrawerLayout drawerLayout;
    NavigationView navigationView;
    Toolbar toolbar;
    ActionBarDrawerToggle toggle;

    //for matrix cards recycler view
    public  RecyclerView matrixCardsRecyclerView;
    public  MatrixCardsRecyclerAdapter cardsRecyclerAdapter;

    ImageView AddMatrixCardsButton;
    List<MatrixCards> matrixCardsList=new ArrayList<>();
    int counter=0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        toolbar=findViewById(R.id.Toolbar);
        AddMatrixCardsButton=findViewById(R.id.AddMatrixCardsButton);
        AddMatrixCardsButton.setOnClickListener(this);

        InitNavigationDrawer();
        InitMatrixCardsRecyclerView();
    }

    /**============================================ METHOD FOR NAVIGATION DRAWER =============================================**/
    public void InitNavigationDrawer(){
        drawerLayout=findViewById(R.id.DrawerLayout);
        navigationView=findViewById(R.id.HomeNavigationView);

        toggle=new ActionBarDrawerToggle(this,drawerLayout,toolbar,R.string.open,R.string.close);
        drawerLayout.addDrawerListener(toggle);
        toggle.syncState();

        navigationView.setNavigationItemSelectedListener(item -> {
            int navMenuItemId=item.getItemId();
            if(navMenuItemId==R.id.action_settings){
                Toast.makeText(HomeActivity.this, "settings Clicked", Toast.LENGTH_SHORT).show();

            }
            else if(navMenuItemId==R.id.action_htu){
                Toast.makeText(HomeActivity.this, "HTU Clicked", Toast.LENGTH_SHORT).show();

            }
            else if(navMenuItemId==R.id.action_feedback){
                Toast.makeText(HomeActivity.this, "feedback Clicked", Toast.LENGTH_SHORT).show();

            }
            else if(navMenuItemId==R.id.action_about){
                Toast.makeText(HomeActivity.this, "about Clicked", Toast.LENGTH_SHORT).show();

            }

            drawerLayout.closeDrawer(GravityCompat.START);
            return true;
        });

    }

    public void InitMatrixCardsRecyclerView(){
        matrixCardsRecyclerView=findViewById(R.id.MatrixCardsRecyclerView);
        cardsRecyclerAdapter=new MatrixCardsRecyclerAdapter(this,matrixCardsList);

        matrixCardsRecyclerView.setLayoutManager(new LinearLayoutManager(this,LinearLayoutManager.HORIZONTAL,false));
        matrixCardsRecyclerView.setAdapter(cardsRecyclerAdapter);
    }

    /**================================================== ADDING MATRIX CARDS ====================================================**/
    @Override
    public void onClick(View view) {
        //when Add Matrix button is clicked
        if (AddMatrixCardsButton.equals(view)) {

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
            }
            else Toast.makeText(this, "Matrix Limit Reached", Toast.LENGTH_SHORT).show();

        }
    }
}