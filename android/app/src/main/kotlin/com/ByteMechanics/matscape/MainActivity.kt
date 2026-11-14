package com.ByteMechanics.matscape

import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Tells Dart where the app's private files live (see lib/app/storage.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "matscape/storage")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    // Backed up with the user's Google account by Android.
                    "dataDir" -> result.success(filesDir.absolutePath)
                    // Never backed up: what belongs to this one device, such
                    // as its sync id. A restored phone must not reuse it.
                    "localDir" -> result.success(noBackupFilesDir.absolutePath)
                    // The name the user gave the device, else its model.
                    "deviceName" -> result.success(
                        Settings.Global.getString(contentResolver, Settings.Global.DEVICE_NAME)
                            ?.takeIf { it.isNotBlank() } ?: Build.MODEL
                    )
                    else -> result.notImplemented()
                }
            }
    }
}
