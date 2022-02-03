package com.ByteMechanics.matscape.Preferences;

import android.content.Context;
import android.content.SharedPreferences;

import androidx.annotation.NonNull;

public class Preferences {

    private static final String SHARED_PREFERENCE_FILE = "SettingsData";
    private static SharedPreferences sharedPreferences;

    /**
     * ==================================== FUNCTION FOR SAVING DEFAULT MATRIX DIMENSIONS ====================================
     **/
    public static void saveDimensions(@NonNull Context context, int rows, int columns) {
        sharedPreferences = context.getSharedPreferences(SHARED_PREFERENCE_FILE, Context.MODE_PRIVATE);

        SharedPreferences.Editor editor = sharedPreferences.edit();

        editor.putInt("DefaultRows", rows);
        editor.putInt("DefaultColumns", columns);

        editor.apply();
    }

    /**
     * ====================================== FUNCTION FOR GETTING DEFAULT MATRIX ROWS ======================================
     **/
    public static int getDefaultRows(@NonNull Context context) {
        sharedPreferences = context.getSharedPreferences(SHARED_PREFERENCE_FILE, Context.MODE_PRIVATE);
        return sharedPreferences.getInt("DefaultRows", 5);
    }

    /**
     * ==================================== FUNCTION FOR GETTING DEFAULT MATRIX COLUMNS ====================================
     **/
    public static int getDefaultColumns(@NonNull Context context) {
        sharedPreferences = context.getSharedPreferences(SHARED_PREFERENCE_FILE, Context.MODE_PRIVATE);
        return sharedPreferences.getInt("DefaultColumns", 5);
    }

    /**
     * ======================================= FUNCTION FOR SAVING DEFAULT MATRIX TYPE ========================================
     **/
    public static void saveMatrixType(@NonNull Context context, boolean isNullSelected) {
        sharedPreferences = context.getSharedPreferences(SHARED_PREFERENCE_FILE, Context.MODE_PRIVATE);

        SharedPreferences.Editor editor = sharedPreferences.edit();

        editor.putBoolean("DefaultMatrixType", isNullSelected);

        editor.apply();
    }

    /**
     * ====================================== FUNCTION FOR GETTING DEFAULT MATRIX TYPE ======================================
     **/
    public static boolean getDefaultMatrixType(@NonNull Context context) {
        sharedPreferences = context.getSharedPreferences(SHARED_PREFERENCE_FILE, Context.MODE_PRIVATE);
        return sharedPreferences.getBoolean("DefaultMatrixType", true);
    }

    /**
     * ========================================== FUNCTION FOR SAVING APP'S THEME STATE ========================================
     **/
    public static void saveThemeState(@NonNull Context context, boolean isDarkEnabled) {
        sharedPreferences = context.getSharedPreferences(SHARED_PREFERENCE_FILE, Context.MODE_PRIVATE);
        SharedPreferences.Editor editor = sharedPreferences.edit();

        editor.putBoolean("ThemeState", isDarkEnabled);
        editor.apply();
    }

    /**
     * =========================================== FUNCTION FOR GETTING APP'S THEME STATE =======================================
     **/
    public static boolean getThemeState(@NonNull Context context) {
        sharedPreferences = context.getSharedPreferences(SHARED_PREFERENCE_FILE, Context.MODE_PRIVATE);
        return sharedPreferences.getBoolean("ThemeState", false);
    }
}
