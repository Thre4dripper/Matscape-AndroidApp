package com.example.matscape.Activities;


import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.recyclerview.widget.DividerItemDecoration;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.matscape.Adapters.MatrixCardsRecyclerAdapter;
import com.example.matscape.Adapters.ResultCardsRecyclerAdapter;
import com.example.matscape.Controllers.MatrixCardsController;
import com.example.matscape.Controllers.ResultCardsController;
import com.example.matscape.R;
import com.google.android.material.navigation.NavigationView;

import java.util.List;

public class HomeActivity extends AppCompatActivity implements View.OnClickListener, MatrixCardsRecyclerAdapter.MatrixCardsInterface {

    private static final String TAG = "HomeActivity";
    //for navigation drawer
    DrawerLayout mDrawerLayout;
    NavigationView mNavigationView;
    Toolbar mToolbar;
    ActionBarDrawerToggle mToggle;

    //for matrix cards recycler view
    public  static RecyclerView mMatrixCardsRecyclerView;
    ImageView addMatrixCardsButton;


    //for result cards recycler view
    public static RecyclerView mResultCardsRecyclerView;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        mToolbar = findViewById(R.id.Toolbar);
        addMatrixCardsButton = findViewById(R.id.AddMatrixCardsButton);
        addMatrixCardsButton.setOnClickListener(this);

        InitNavigationDrawer();

        InitMatrixCardsRecyclerView();
        InitResultCardsRecyclerView();
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

    /**
     * ===================================== METHOD FOR INITIALISING MATRIX CARDS RECYCLER VIEW ==============================
     **/
    public void InitMatrixCardsRecyclerView() {
        mMatrixCardsRecyclerView = findViewById(R.id.MatrixCardsRecyclerView);
        mMatrixCardsRecyclerView.setLayoutManager(new LinearLayoutManager(this, LinearLayoutManager.HORIZONTAL, false));

        ItemTouchHelper matrixCardsTouchHelper = new ItemTouchHelper(MatrixCardsController.callbackMatrixCards);

        MatrixCardsController.mMatrixCardsRecyclerAdapter = new MatrixCardsRecyclerAdapter(getApplicationContext(),
                MatrixCardsController.matrixCardsList,
                matrixCardsTouchHelper,
                this
        );

        mMatrixCardsRecyclerView.setAdapter(MatrixCardsController.mMatrixCardsRecyclerAdapter);
        matrixCardsTouchHelper.attachToRecyclerView(mMatrixCardsRecyclerView);

        MatrixCardsController.setMatrixNamesList();
    }

    /**
     * ===================================== METHOD FOR INITIALISING RESULT CARDS RECYCLER VIEW ==============================
     **/
    public void InitResultCardsRecyclerView() {
        mResultCardsRecyclerView = findViewById(R.id.ResultCardsRecyclerView);
        mResultCardsRecyclerView.setLayoutManager(new LinearLayoutManager(this));

        ItemTouchHelper resultCardsTouchHelper = new ItemTouchHelper(ResultCardsController.callbackResultCards);

        ResultCardsController.mResultCardsRecyclerAdapter = new ResultCardsRecyclerAdapter(this, resultCardsTouchHelper);
        mResultCardsRecyclerView.setAdapter(ResultCardsController.mResultCardsRecyclerAdapter);
        mResultCardsRecyclerView.addItemDecoration(new DividerItemDecoration(this, DividerItemDecoration.VERTICAL));

        resultCardsTouchHelper.attachToRecyclerView(mResultCardsRecyclerView);
    }


    @Override
    public void onClick(View view) {
        //when Add Matrix button is clicked
        if (addMatrixCardsButton.equals(view))
            MatrixCardsController.addMatrixCards(this, MatrixCardsController.matrixCardCounter, null,
                mMatrixCardsRecyclerView
        );

    }

    /**======================================== OVERRIDE METHODS FOR MATRIX CARDS ================================================**/
    @Override
    public void deleteMatrix(int position, String deletedName) {
      /*  new MaterialAlertDialogBuilder(this)
                .setMessage("Do you want to Delete this Matrix")
                .setPositiveButton("Yes", (dialogInterface, i) -> {*/

        //BUG
        MatrixCardsController.matrixCardsList.remove(position);
        MatrixCardsController.matrixNamesList.add(deletedName);
        MatrixCardsController.matrixCardCounter--;
        MatrixCardsController.mMatrixCardsRecyclerAdapter.notifyItemRemoved(position);
          /*      })
                .setNegativeButton("No", (dialogInterface, i) -> {
                    dialogInterface.dismiss();
                })
        .show();
*/

    }

    @Override
    public void copyMatrix(int position) {

        List<List<String>> originalMatrix = MatrixCardsController.matrixCardsList.get(position).getMatrix();
        MatrixCardsController.addMatrixCards(this, position + 1, originalMatrix,
                mMatrixCardsRecyclerView
        );

    }

    @Override
    public void subMatrix(int position) {

    }

    @Override
    public void editMatrix(int position) {

    }


}