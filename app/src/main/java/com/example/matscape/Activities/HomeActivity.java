package com.example.matscape.Activities;


import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import android.os.Bundle;
import android.view.View;
import android.widget.Toast;

import com.example.matscape.Adapters.MatrixCardsRecyclerAdapter;
import com.example.matscape.R;
import com.google.android.material.navigation.NavigationView;

public class HomeActivity extends AppCompatActivity {

    //for navigation drawer
    DrawerLayout drawerLayout;
    NavigationView navigationView;
    Toolbar toolbar;
    ActionBarDrawerToggle toggle;

    //for matrix cards recycler view
    public  RecyclerView matrixCardsRecyclerView;
    public  MatrixCardsRecyclerAdapter cardsRecyclerAdapter;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        toolbar=findViewById(R.id.Toolbar);
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
        cardsRecyclerAdapter=new MatrixCardsRecyclerAdapter(this);

        matrixCardsRecyclerView.setLayoutManager(new LinearLayoutManager(this,LinearLayoutManager.HORIZONTAL,false));
        matrixCardsRecyclerView.setAdapter(cardsRecyclerAdapter);
    }
}