package com.ByteMechanics.matscape.Activities;

import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.appcompat.app.ActionBarDrawerToggle;
import androidx.appcompat.app.AppCompatActivity;
import androidx.appcompat.app.AppCompatDelegate;
import androidx.appcompat.widget.Toolbar;
import androidx.cardview.widget.CardView;
import androidx.core.content.ContextCompat;
import androidx.core.view.GravityCompat;
import androidx.drawerlayout.widget.DrawerLayout;
import androidx.recyclerview.widget.DividerItemDecoration;
import androidx.recyclerview.widget.ItemTouchHelper;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.ByteMechanics.matscape.Adapters.MatrixCardsRecyclerAdapter;
import com.ByteMechanics.matscape.Adapters.ResultCardsRecyclerAdapter;
import com.ByteMechanics.matscape.Constants.Constant;
import com.ByteMechanics.matscape.Controllers.MatrixCardsController;
import com.ByteMechanics.matscape.Controllers.ResultCardsController;
import com.ByteMechanics.matscape.R;
import com.ByteMechanics.matscape.models.MatrixCards;
import com.ByteMechanics.matscape.models.ResultCards;
import com.google.android.material.button.MaterialButton;
import com.google.android.material.navigation.NavigationView;

import java.util.Collections;

public class HomeActivity extends AppCompatActivity implements View.OnClickListener,
        MatrixCardsRecyclerAdapter.MatrixCardsInterface,
        ResultCardsRecyclerAdapter.ResultCardsInterface {

    //completed all todos in development branch
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

    //Home page direct Views
    private ImageView addMatrixCardsButton;
    private ImageView addResultCardsButton;
    private TextView matricesCount;

    //for blocking back button for accidental clicks
    private boolean doubleBackToExitPressedOnce = false;

    //for hint layouts
    private LinearLayout mMatrixCardsHintLayout;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_home);

        mToolbar = findViewById(R.id.Toolbar);
        addMatrixCardsButton = findViewById(R.id.addMatrixCardButton);
        addResultCardsButton = findViewById(R.id.addResultCardButton);
        matricesCount=findViewById(R.id.MatricesCount);
        homeNumpadCardView = findViewById(R.id.HomeNumpadCardView);
        mMatrixCardsHintLayout = findViewById(R.id.MatrixCardsHintLayout);

        addMatrixCardsButton.setOnClickListener(this);
        addResultCardsButton.setOnClickListener(this);

        matricesCount.setText(this.getString(R.string.total_matrices,MatrixCardsController.matrixCardCounter));
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
                intent.putExtra(Constant.NAVIGATION_FRAGMENT_KEY, Constant.NAV_SETTINGS_FRAGMENT_ID);
                startActivity(intent);

            } else if (navMenuItemId == R.id.action_htu) {
                Intent intent = new Intent(this, NavigationActivity.class);
                intent.putExtra(Constant.NAVIGATION_FRAGMENT_KEY, Constant.NAV_HTU_FRAGMENT_ID);
                startActivity(intent);

            } else if (navMenuItemId == R.id.action_feedback) {
                Intent intent = new Intent(this, NavigationActivity.class);
                intent.putExtra(Constant.NAVIGATION_FRAGMENT_KEY, Constant.NAV_FEEDBACK_FRAGMENT_ID);
                startActivity(intent);

            } else if (navMenuItemId == R.id.action_about) {
                Intent intent = new Intent(this, NavigationActivity.class);
                intent.putExtra(Constant.NAVIGATION_FRAGMENT_KEY, Constant.NAV_ABOUT_FRAGMENT_ID);
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

        //adding initial card
        if (ResultCardsController.resultCardCounter == 0)
            onClick(addResultCardsButton);
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
            ResultCardsRecyclerAdapter.ViewHolder.InitKeyboard(this, view);

        //when Add Matrix button is clicked
        if (addMatrixCardsButton.equals(view)) {
            MatrixCardsController.addMatrixCards(this,
                    MatrixCardsController.matrixCardCounter,
                    null,
                    mMatrixCardsRecyclerView
            );

            //hiding hint layout
            if (MatrixCardsController.matrixCardCounter != 0)
                mMatrixCardsHintLayout.setVisibility(View.GONE);

            //updating result cards
            ResultCardsController.HomeKeyboardInputControl(this,new EditText(this),null);

            //updating matrices count
            matricesCount.setText(this.getString(R.string.total_matrices,MatrixCardsController.matrixCardCounter));

        } else if (addResultCardsButton.equals(view)) {
            ResultCardsController.addResultCards(this,
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
            ResultCardsRecyclerAdapter.ViewHolder.MatrixCardsOnClick(this, position);
    }

    @Override
    public void deleteMatrix(int position, String deletedName) {

        if (position != RecyclerView.NO_POSITION) {
            MatrixCardsController.matrixCardsList.remove(position);
            MatrixCardsController.NamesList.remove(position);
            MatrixCardsController.remainingNamesList.add(deletedName);
            MatrixCardsController.matrixCardCounter--;
            MatrixCardsController.mMatrixCardsRecyclerAdapter.notifyItemRemoved(position);

            //sorting Names List after adding 'deletedName' name from Matrix Cards
            Collections.sort(MatrixCardsController.remainingNamesList);

            //showing hint layout
            if (MatrixCardsController.matrixCardCounter == 0)
                new Handler(Looper.getMainLooper()).postDelayed(() -> mMatrixCardsHintLayout.setVisibility(View.VISIBLE), 200);

            //updating result cards
            ResultCardsController.HomeKeyboardInputControl(this,new EditText(this),null);

            //updating matrices count
            matricesCount.setText(this.getString(R.string.total_matrices,MatrixCardsController.matrixCardCounter));
        }
    }

    @Override
    public void copyMatrix(int position) {

        MatrixCards copiedCard = MatrixCardsController.matrixCardsList.get(position);
        MatrixCardsController.addMatrixCards(this, position + 1, copiedCard, mMatrixCardsRecyclerView);
    }

    @Override
    public void subMatrix(int position) {
        Intent intent = new Intent(this, ChangeMatrixActivity.class);
        intent.putExtra(Constant.CHANGE_MATRIX_ACTIVITY_KEY, Constant.SUB_MATRIX_FRAGMENT_ID);
        intent.putExtra(Constant.MATRIX_CARD_POSITION_KEY, position);
        startActivity(intent);
    }

    @Override
    public void editMatrix(int position) {
        Intent intent = new Intent(this, ChangeMatrixActivity.class);
        intent.putExtra(Constant.CHANGE_MATRIX_ACTIVITY_KEY, Constant.EDIT_MATRIX_FRAGMENT_ID);
        intent.putExtra(Constant.MATRIX_CARD_POSITION_KEY, position);
        startActivity(intent);
    }


    /**
     * ======================================== OVERRIDE METHODS FOR RESULT CARDS ================================================
     **/

    @Override
    public void deleteResult(int position) {
        if (position != RecyclerView.NO_POSITION) {
            ResultCardsController.resultCardsList.remove(position);
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemRemoved(position);
            ResultCardsController.resultCardCounter--;

            //selected card position must be updated on card removal
            //CARD removed before selected card
            if (position < ResultCardsController.selectedCard)
                ResultCardsController.selectedCard--;

                //selected card is itself removed
            else if (position == ResultCardsController.selectedCard) {

                //when selected card removed is last card prev card gets selected, && size>0
                if (position == ResultCardsController.resultCardsList.size() && ResultCardsController.resultCardsList.size() != 0) {
                    ResultCardsController.selectedCard--;
                    clickedCard(ResultCardsController.selectedCard, 1);
                }
                //otherwise next card gets selected
                else if (position < ResultCardsController.resultCardsList.size())
                    clickedCard(ResultCardsController.selectedCard, 1);

            }

            if (ResultCardsController.resultCardCounter == 0)
                onClick(addResultCardsButton);
        }
    }

    @Override
    public void copyResult(int position) {
        ResultCards resultCard = ResultCardsController.resultCardsList.get(position);
        ResultCardsController.addResultCards(this,position + 1, resultCard, mResultCardsRecyclerView);
    }

    @Override
    public void addResultMatrix(int position) {
        ResultCards resultCard = ResultCardsController.resultCardsList.get(position);

        //result card should not be empty
        if (resultCard.getResultMatrix() != null) {
            MatrixCards matrixCard = new MatrixCards(null,
                    resultCard.getResultMatrix(),
                    resultCard.getMatrixRows(),
                    resultCard.getMatrixColumns(),
                    0);

            MatrixCardsController.addMatrixCards(this, MatrixCardsController.matrixCardCounter, matrixCard, mMatrixCardsRecyclerView);

            //showing hint layout
            if (MatrixCardsController.matrixCardCounter != 0)
                mMatrixCardsHintLayout.setVisibility(View.GONE);
        } else
            Toast.makeText(this, getString(R.string.toast_empty_result_card), Toast.LENGTH_SHORT).show();

    }

    @Override
    public void clickedCard(int clickedCard, int from) {

        //'from' specifies from where this function is called '0' for click and '1' for manual call when a card is removed
        if (clickedCard != ResultCardsController.selectedCard || from == 1) {

            //removing color from previous selected card
            ResultCardsController.resultCardsList.get(ResultCardsController.selectedCard).setHighlightedColor(
                    "#" + Integer.toHexString(ContextCompat.getColor(this, R.color.white))
            );
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(ResultCardsController.selectedCard);

            //setting color to newly selected card
            ResultCardsController.resultCardsList.get(clickedCard).setHighlightedColor(
                    "#" + Integer.toHexString(ContextCompat.getColor(this, R.color.selected_card_color))
                    );
            ResultCardsController.mResultCardsRecyclerAdapter.notifyItemChanged(clickedCard);

            ResultCardsController.selectedCard = clickedCard;
        }
    }

    @Override
    public void onBackPressed() {

        //first home numpad will get vanished then double click back functionality execute
        if (homeNumpadCardView.getVisibility() == View.VISIBLE)
            homeNumpadCardView.setVisibility(View.GONE);
        else {
            if (doubleBackToExitPressedOnce) {
                super.onBackPressed();
                return;
            }

            this.doubleBackToExitPressedOnce = true;
            Toast.makeText(this, getString(R.string.toast_home_back_safety), Toast.LENGTH_SHORT).show();

            new Handler(Looper.getMainLooper()).postDelayed(() -> doubleBackToExitPressedOnce = false, 2000);
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();

        //Reset Matrix Cards View Model
        MatrixCardsController.matrixCardsList.clear();
        MatrixCardsController.matrixCardCounter = 0;
        MatrixCardsController.NamesList.clear();
        MatrixCardsController.remainingNamesList.clear();

        //Reset Result Cards View Model
        ResultCardsController.resultCardsList.clear();
        ResultCardsController.resultCardCounter = ResultCardsController.selectedCard = 0;
        ResultCardsController.isNthPowerButtonPressed = false;
    }
}