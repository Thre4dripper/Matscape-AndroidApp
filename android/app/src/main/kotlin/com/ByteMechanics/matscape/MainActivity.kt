package com.ByteMechanics.matscape

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Tells Dart where the app's private files live (see lib/app/storage.dart).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "matscape/storage")
            .setMethodCallHandler { call, result ->
                if (call.method == "dataDir") result.success(filesDir.absolutePath)
                else result.notImplemented()
            }
    }
}
