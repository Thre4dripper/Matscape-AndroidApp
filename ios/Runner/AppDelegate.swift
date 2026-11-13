import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // Tells Dart where the app's private files live (see lib/app/storage.dart).
    let storage = FlutterMethodChannel(
      name: "matscape/storage",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    storage.setMethodCallHandler { call, result in
      guard call.method == "dataDir" else {
        result(FlutterMethodNotImplemented)
        return
      }
      let dir = FileManager.default.urls(
        for: .applicationSupportDirectory, in: .userDomainMask)[0]
      try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
      result(dir.path)
    }
  }
}
