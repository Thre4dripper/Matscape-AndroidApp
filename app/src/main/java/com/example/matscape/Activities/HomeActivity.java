package com.example.matscape.Activities;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.ImageView;

import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.widget.Toolbar;
import androidx.cardview.widget.CardView;
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
import com.example.matscape.models.MatrixCards;
import com.example.matscape.models.ResultCards;
import com.google.android.material.button.MaterialButton;
import com.google.android.material.navigation.NavigationView;

import java.util.Collections;

public class HomeActivity extends AppCompatActivity implements View.OnClickListener,
        MatrixCardsRecyclerAdapter.MatrixCardsInterface,
        ResultCardsRecyclerAdapter.ResultCardsInterface {

    public static final String NAVIGATION_FRAGMENT_KEY = "navigationFragmentKey";
    public static final String CHANGE_MATRIX_ACTIVITY_KEY = "changeMatrixActivityKey";
    public static final String MATRIX_CARD_POSITION_KEY = "matrixElementsSendingKey";

    public static final int EDIT_MATRIX_FRAGMENT_ID = 1;
    public static final int SUB_MATRIX_FRAGMENT_ID = 2;
    private static final String TAG = "HomeActivity";
    //for matrix cards recycler view
    public static RecyclerView mMatrixCardsRecyclerView;
    //for result cards recycler view
    public static RecyclerView mResultCardsRecyclerView;
    //for HomeScreen Keyboard
    public static MaterialButton[] numpadButtons = new MaterialButton[10];
    public static MaterialButton plusButton, minusButton, multiplyButton, divideButton;
    public static MaterialButton dotButton, bracketOpen, bracketClose;
    public static CardView[] matOperationButtons = new CardView[10];
    public static CardView moveCursorLeft, moveCursorRight, backSpaceButton;
    public static CardView homeNumpadCardView;
    //for navigation drawer
    private DrawerLayout mDrawerLayout;
    private Toolbar mToolbar;
    private ImageView addMatrixCardsButton;
    private ImageView addResultCardsButton;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_home);

        mToolbar = findViewById(R.id.Toolbar);
        addMatrixCardsButton = findViewById(R.id.addMatrixCardButton);
        addResultCardsButton = findViewById(R.id.addResultCardButton);
        homeNumpadCardView = findViewById(R.id.HomeNumpadCardView);

        addMatrixCardsButton.setOnClickListener(this);
        addResultCardsButton.setOnClickListener(this);

        InitNavigationDrawer();

        InitMatrixCardsRecyclerView();
        InitResultCardsRecyclerView();

        InitHomeKeyboard();
    }

    /**
     * ============================================ METHOD FOR NAVIGATION DRAWER =============================================
     **/
    public void InitNavigationDrawer() {
        mDrawerLayout = findViewById(R.id.DrawerLayout);
        NavigationView mNavigationView = findViewById(R.id.HomeNavigationView);

        ActionBarDrawerToggle mToggle = new ActionBarDrawerToggle(this, mDrawerLayout, mToolbar, R.string.open, R.string.close);
        mDrawerLayout.addDrawerListener(mToggle);
        mToggle.syncState();

        mNavigationView.setNavigationItemSelectedListener(item -> {
            int navMenuItemId = item.getItemId();
            if (navMenuItemId == R.id.action_settings) {
                Intent intent = new Intent(this, NavigationActivity.class);
                intent.putExtra(NAVIGATION_FRAGMENT_KEY, 1);
                startActivity(intent);

            } else if (navMenuItemId == R.id.action_htu) {
                Intent intent = new Intent(this, NavigationActivity.class);
                intent.putExtra(NAVIGATION_FRAGMENT_KEY, 2);
                startActivity(intent);

            } else if (navMenuItemId == R.id.action_feedback) {
                Intent intent = new Intent(this, NavigationActivity.class);
                intent.putExtra(NAVIGATION_FRAGMENT_KEY, 3);
                startActivity(intent);

            } else if (navMenuItemId == R.id.action_about) {
                Intent intent = new Intent(this, NavigationActivity.class);
                intent.putExtra(NAVIGATION_FRAGMENT_KEY, 4);
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

    public void InitHomeKeyboard() {
        View view = LayoutInflater.from(this).inflate(R.layout.numpad_home, homeNumpadCardView, true);

        numpadButtons[0] = view.findViewById(R.id.HomeNumpad0);
        numpadButtons[1] = view.findViewById(R.id.HomeNumpad1);
        numpadButtons[2] = view.findViewById(R.id.HomeNumpad2);
        numpadButtons[3] = view.findViewById(R.id.HomeNumpad3);
        numpadButtons[4] = view.findViewById(R.id.HomeNumpad4);
        numpadButtons[5] = view.findViewById(R.id.HomeNumpad5);
        numpadButtons[6] = view.findViewById(R.id.HomeNumpad6);
        numpadButtons[7] = view.findViewById(R.id.HomeNumpad7);
        numpadButtons[8] = view.findViewById(R.id.HomeNumpad8);
        numpadButtons[9] = view.findViewById(R.id.HomeNumpad9);

        for (int i = 0; i < 10; i++)
            numpadButtons[i].setOnClickListener(this);

        plusButton = view.findViewById(R.id.HomeNumpadAdd);
        minusButton = view.findViewById(R.id.HomeNumpadMinus);
        multiplyButton = view.findViewById(R.id.HomeNumpadX);
        divideButton = view.findViewById(R.id.HomeNumpadDivide);

        plusButton.setOnClickListener(this);
        minusButton.setOnClickListener(this);
        multiplyButton.setOnClickListener(this);
        divideButton.setOnClickListener(this);

        dotButton = view.findViewById(R.id.HomeNumpadDot);
        bracketOpen = view.findViewById(R.id.HomeNumpadBracketOpen);
        bracketClose = view.findViewById(R.id.HomeNumpadBracketClose);

        dotButton.setOnClickListener(this);
        bracketOpen.setOnClickListener(this);
        bracketClose.setOnClickListener(this);

        matOperationButtons[0] = view.findViewById(R.id.detButton);
        matOperationButtons[1] = view.findViewById(R.id.transButton);
        matOperationButtons[2] = view.findViewById(R.id.squareButton);
        matOperationButtons[3] = view.findViewById(R.id.cubeButton);
        matOperationButtons[4] = view.findViewById(R.id.nthButton);
        matOperationButtons[5] = view.findViewById(R.id.inverseButton);
        matOperationButtons[6] = view.findViewById(R.id.traceButton);
        matOperationButtons[7] = view.findViewById(R.id.adjButton);
        matOperationButtons[8] = view.findViewById(R.id.minorsButton);
        matOperationButtons[9] = view.findViewById(R.id.cofButton);

        for (int i = 0; i < 10; i++)
            matOperationButtons[i].setOnClickListener(this);

        moveCursorLeft = view.findViewById(R.id.MoveCursorLeft);
        moveCursorRight = view.findViewById(R.id.MoveCursorRight);
        backSpaceButton = view.findViewById(R.id.HomeBackspaceButton);

        moveCursorLeft.setOnClickListener(this);
        moveCursorRight.setOnClickListener(this);
        backSpaceButton.setOnClickListener(this);
    }

    @Override
    public void onClick(View view) {

        //sending Home Keyboard OnClicks to ResultCardsController for Click Handling
        if (ResultCardsController.resultCardCounter > 0)
            ResultCardsRecyclerAdapter.ViewHolder.InitKeyboard(view);

        //when Add Matrix button is clicked
        if (addMatrixCardsButton.equals(view)) {
            MatrixCardsController.addMatrixCards(this,
                    MatrixCardsController.matrixCardCounter,
                    null,
                    mMatrixCardsRecyclerView
            );
        } else if (addResultCardsButton.equals(view)) {
            ResultCardsController.addResultCards(
                    ResultCardsController.resultCardCounter,
                    null,
                    mResultCardsRecyclerView);
        }

    }

    /**
     * ======================================== OVERRIDE METHODS FOR MATRIX CARDS ================================================
     **/
    @Override
    public void clickCard(int position) {
        if (ResultCardsController.resultCardCounter > 0)
            ResultCardsRecyclerAdapter.ViewHolder.MatrixCardsOnClick(position);
    }

    @Override
    public void deleteMatrix(int position, String deletedName) {
      /*  new MaterialAlertDialogBuilder(this)
                .setMessage("Do you want to Delete this Matrix")
                .setPositiveButton("Yes", (dialogInterface, i) -> {*/

        //TODO bug here on multiple rapid touches
        MatrixCardsController.matrixCardsList.remove(position);
        MatrixCardsController.matrixNamesList.remove(position);
        MatrixCardsController.remainingMatrixNamesList.add(deletedName);
        MatrixCardsController.matrixCardCounter--;
        MatrixCardsController.mMatrixCardsRecyclerAdapter.notifyItemRemoved(position);

        //sorting Names List after adding 'deletedName' name from Matrix Cards
        Collections.sort(MatrixCardsController.remainingMatrixNamesList);
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
        Intent intent = new Intent(this, ChangeMatrixActivity.class);
        intent.putExtra(CHANGE_MATRIX_ACTIVITY_KEY, SUB_MATRIX_FRAGMENT_ID);
        intent.putExtra(MATRIX_CARD_POSITION_KEY, position);
        startActivity(intent);
    }

    @Override
    public void editMatrix(int position) {
        Intent intent = new Intent(this, ChangeMatrixActivity.class);
        intent.putExtra(CHANGE_MATRIX_ACTIVITY_KEY, EDIT_MATRIX_FRAGMENT_ID);
        intent.putExtra(MATRIX_CARD_POSITION_KEY, position);
        startActivity(intent);
    }


    /**
     * ======================================== OVERRIDE METHODS FOR RESULT CARDS ================================================
     **/

    @Override
    public void deleteResult(int position) {
        ResultCardsController.resultCardsList.remove(position);
        ResultCardsController.mResultCardsRecyclerAdapter.notifyItemRemoved(position);
        ResultCardsController.resultCardCounter--;

        //selected card position must be updated on card removal
        //CARD removed before selected card
        if (position < ResultCardsController.selectedCard)
            ResultCardsController.selectedCard--;

            //selected card is itself removed
        else if (position == ResultCardsController.selectedCard) {

            //when last card is selected and is removed
            if (position == ResultCardsController.resultCardsList.size() - 1) {
                clickedCard(ResultCardsController.selectedCard, 1);
                ResultCardsController.selectedCard = 0;
            }
            //otherwise next card gets selected
            else if (position < ResultCardsController.resultCardsList.size())
                clickedCard(ResultCardsController.selectedCard, 1);

        }


        Log.d(TAG, "deleteResult: " + ResultCardsController.resultCardCounter + "," + ResultCardsController.selectedCard);

    }

    @Override
    public void copyResult(int position) {
        ResultCards resultCard = ResultCardsController.resultCardsList.get(position);
        ResultCardsController.addResultCards(position + 1, resultCard, mResultCardsRecyclerView);
    }

    @Override
    public void clickedCard(int clickedCard, int from) {

        //TODO BUG HERE when deleting selected card from bottom to top
        //'from' specifies from where this function is called '0' for click and '1' for manual call when a card is removed
        if (clickedCard != ResultCardsController.selectedCard || from == 1) {

            //removing color from previous selected card
            ResultCardsController.resultCardsList.get(ResultCardsController.selectedCard).setHighlightedColor("#FFFFFF");
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(ResultCardsController.selectedCard);

            //setting color to newly selected card
            ResultCardsController.resultCardsList.get(clickedCard).setHighlightedColor("#2196F3");
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(clickedCard);

            ResultCardsController.selectedCard = clickedCard;
        }
    }

    @Override
    public void onBackPressed() {
        homeNumpadCardView.setVisibility(View.GONE);
    }
}