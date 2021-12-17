package com.example.matscape.Preferences;

import android.content.Context;
import android.content.SharedPreferences;

import androidx.annotation.NonNull;

public class Preferences {

    private static final String SHARED_PREFERENCE_FILE = "SettingsData";
    private static SharedPreferences sharedPreferences;

    public static void saveDimensions(@NonNull Context context, int rows, int columns) {
        sharedPreferences = context.getSharedPreferences(SHARED_PREFERENCE_FILE, Context.MODE_PRIVATE);

        SharedPreferences.Editor editor = sharedPreferences.edit();

        editor.putInt("DefaultRows", rows);
        editor.putInt("DefaultColumns", columns);

        editor.apply();
    }

    public static int getDefaultRows(@NonNull Context context) {
        sharedPreferences = context.getSharedPreferences(SHARED_PREFERENCE_FILE, Context.MODE_PRIVATE);
        return sharedPreferences.getInt("DefaultRows", 5);
    }

    public static int getDefaultColumns(@NonNull Context context) {
        sharedPreferences = context.getSharedPreferences(SHARED_PREFERENCE_FILE, Context.MODE_PRIVATE);
        return sharedPreferences.getInt("DefaultColumns", 5);
    }
}
