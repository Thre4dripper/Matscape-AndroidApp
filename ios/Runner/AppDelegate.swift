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
      let files = FileManager.default
      let support = files.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
      switch call.method {
      case "dataDir":
        // Included in the user's iCloud backup.
        try? files.createDirectory(at: support, withIntermediateDirectories: true)
        result(support.path)
      case "localDir":
        // Never backed up: what belongs to this one device, such as its sync
        // id. A restored phone must not reuse it.
        var local = support.appendingPathComponent("Local", isDirectory: true)
        try? files.createDirectory(at: local, withIntermediateDirectories: true)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try? local.setResourceValues(values)
        result(local.path)
      case "deviceName":
        result(UIDevice.current.name)
      case "beginBackground":
        // A little time after leaving the app, so a sync that started then
        // can finish instead of being suspended halfway.
        var task: UIBackgroundTaskIdentifier = .invalid
        task = UIApplication.shared.beginBackgroundTask(withName: "Matscape sync") {
          UIApplication.shared.endBackgroundTask(task)
          task = .invalid
        }
        result(task.rawValue)
      case "endBackground":
        if let raw = call.arguments as? Int {
          UIApplication.shared.endBackgroundTask(UIBackgroundTaskIdentifier(rawValue: raw))
        }
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
