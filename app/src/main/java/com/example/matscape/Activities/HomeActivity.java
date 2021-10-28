package com.example.matscape.Activities;

import androidx.annotation.NonNull;
import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;

import android.os.Bundle;
import android.view.MenuItem;
import android.widget.Toast;

import com.example.matscape.R;
import com.google.android.material.navigation.NavigationView;

public class HomeActivity extends AppCompatActivity {

    //For navigation drawer
    DrawerLayout drawerLayout;
    NavigationView navigationView;
    Toolbar toolbar;
    ActionBarDrawerToggle toggle;


    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        toolbar=findViewById(R.id.Toolbar);
        InitNavigationDrawer();
    }

    /**============================================ METHOD FOT NAVIGATION DRAWER =============================================**/
    public void InitNavigationDrawer(){
        drawerLayout=findViewById(R.id.DrawerLayout);
        navigationView=findViewById(R.id.HomeNavigationView);

        toggle=new ActionBarDrawerToggle(this,drawerLayout,toolbar,R.string.open,R.string.close);
        drawerLayout.addDrawerListener(toggle);
        toggle.syncState();

        navigationView.setNavigationItemSelectedListener(new NavigationView.OnNavigationItemSelectedListener() {
            @Override
            public boolean onNavigationItemSelected(@NonNull MenuItem item) {
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
            }
        });

    }

}