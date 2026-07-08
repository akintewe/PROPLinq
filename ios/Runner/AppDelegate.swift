import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps with API key from Info.plist
    if let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
       let plist = NSDictionary(contentsOfFile: path),
       let apiKey = plist["GMSApiKey"] as? String {
      GMSServices.provideAPIKey(apiKey)
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // NOTE: Deliberately NOT overriding application(open:) or
  // continueUserActivity here. Per AppsFlyer support (ticket #1003139), the
  // AppsFlyer Flutter plugin v6.4.0+ handles URI-scheme and Universal Link
  // delivery automatically via swizzling. Manually forwarding to the SDK — or
  // overriding these delegate methods — interferes with that automatic
  // handling and was causing the app→Safari→App Store bounce.
}
