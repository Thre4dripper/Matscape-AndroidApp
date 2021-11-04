package com.example.matscape.Activities;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;

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
import com.example.matscape.dataModels.MatrixCards;
import com.example.matscape.dataModels.ResultCards;
import com.google.android.material.navigation.NavigationView;

import java.util.Collections;
import java.util.List;

public class HomeActivity extends AppCompatActivity implements View.OnClickListener,
        MatrixCardsRecyclerAdapter.MatrixCardsInterface,
        ResultCardsRecyclerAdapter.ResultCardsInterface {

    private static final String TAG = "HomeActivity";

    public static final String NAVIGATION_FRAGMENT_KEY="navigationFragmentKey";
    public static final String CHANGE_MATRIX_ACTIVITY_KEY="changeMatrixActivityKey";
    public static final String MATRIX_CARD_POSITION_KEY ="matrixElementsSendingKey";

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
    ImageView addResultCardsButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_home);

        mToolbar = findViewById(R.id.Toolbar);
        addMatrixCardsButton = findViewById(R.id.addMatrixCardButton);
        addResultCardsButton = findViewById(R.id.addResultCardButton);

        addMatrixCardsButton.setOnClickListener(this);
        addResultCardsButton.setOnClickListener(this);

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
                Intent intent=new Intent(this,NavigationActivity.class);
                intent.putExtra(NAVIGATION_FRAGMENT_KEY,1);
                startActivity(intent);

            } else if (navMenuItemId == R.id.action_htu) {
                Intent intent=new Intent(this,NavigationActivity.class);
                intent.putExtra(NAVIGATION_FRAGMENT_KEY,2);
                startActivity(intent);

            } else if (navMenuItemId == R.id.action_feedback) {
                Intent intent=new Intent(this,NavigationActivity.class);
                intent.putExtra(NAVIGATION_FRAGMENT_KEY,3);
                startActivity(intent);

            } else if (navMenuItemId == R.id.action_about) {
                Intent intent=new Intent(this,NavigationActivity.class);
                intent.putExtra(NAVIGATION_FRAGMENT_KEY,4);
                startActivity(intent);

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

        ResultCardsController.mResultCardsRecyclerAdapter = new ResultCardsRecyclerAdapter(getApplicationContext(),
                ResultCardsController.resultCardsList,
                resultCardsTouchHelper,
                this
                );

        mResultCardsRecyclerView.setAdapter(ResultCardsController.mResultCardsRecyclerAdapter);
        mResultCardsRecyclerView.addItemDecoration(new DividerItemDecoration(this, DividerItemDecoration.VERTICAL));

        resultCardsTouchHelper.attachToRecyclerView(mResultCardsRecyclerView);
    }


    @Override
    public void onClick(View view) {
        //when Add Matrix button is clicked
        if (addMatrixCardsButton.equals(view)) {
            MatrixCardsController.addMatrixCards(this,
                    MatrixCardsController.matrixCardCounter,
                    null,
                    mMatrixCardsRecyclerView
            );
        } else if(addResultCardsButton.equals(view)){
            ResultCardsController.addResultCards(this,
                    ResultCardsController.resultCardCounter,
                    null,
                    mResultCardsRecyclerView);
        }


    }

    /**======================================== OVERRIDE METHODS FOR MATRIX CARDS ================================================**/
    @Override
    public void deleteMatrix(int position, String deletedName) {
      /*  new MaterialAlertDialogBuilder(this)
                .setMessage("Do you want to Delete this Matrix")
                .setPositiveButton("Yes", (dialogInterface, i) -> {*/

        //TODO bug here on multiple rapid touches
        MatrixCardsController.matrixCardsList.remove(position);
        MatrixCardsController.matrixNamesList.add(deletedName);
        MatrixCardsController.matrixCardCounter--;
        MatrixCardsController.mMatrixCardsRecyclerAdapter.notifyItemRemoved(position);

        //sorting Names List after adding 'deletedName' name from Matrix Cards
        Collections.sort(MatrixCardsController.matrixNamesList);
          /*      })
                .setNegativeButton("No", (dialogInterface, i) -> {
                    dialogInterface.dismiss();
                })
        .show();
*/

    }

    @Override
    public void copyMatrix(int position) {

        MatrixCards copiedCard = MatrixCardsController.matrixCardsList.get(position);
        MatrixCardsController.addMatrixCards(this, position + 1, copiedCard, mMatrixCardsRecyclerView);
    }

    @Override
    public void subMatrix(int position) {

    }

    @Override
    public void editMatrix(int position) {
        Intent intent=new Intent(this,ChangeMatrixActivity.class);
        intent.putExtra(CHANGE_MATRIX_ACTIVITY_KEY,1);
        Bundle bundle=new Bundle();
        intent.putExtra(MATRIX_CARD_POSITION_KEY, position);
        startActivity(intent);
    }


    /**======================================== OVERRIDE METHODS FOR RESULT CARDS ================================================**/

    @Override
    public void deleteResult(int position) {
            ResultCardsController.resultCardsList.remove(position);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemRemoved(position);
            ResultCardsController.resultCardCounter--;
    }

    @Override
    public void copyResult(int position) {
            ResultCards resultCard=ResultCardsController.resultCardsList.get(position);
            ResultCardsController.addResultCards(this,position+1,resultCard,mResultCardsRecyclerView);
    }
}