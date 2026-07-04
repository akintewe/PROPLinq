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

  // Forward URL-scheme and Universal Link opens to the Flutter plugins
  // (AppsFlyer + app_links) exactly once via super. Do NOT call the AppsFlyer
  // SDK directly here as well — double-processing the userActivity makes the
  // SDK re-open the resolved OneLink URL in Safari.
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    return super.application(app, open: url, options: options)
  }

  override func application(
    _ application: UIApplication,
    continue userActivity: NSUserActivity,
    restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
  ) -> Bool {
    // Let the Flutter plugins (AppsFlyer + app_links) process the Universal Link.
    super.application(application, continue: userActivity, restorationHandler: restorationHandler)

    // CRITICAL: both plugins return `false` from their continueUserActivity
    // handlers. If the aggregate delegate result is `false` for a web-browsing
    // activity, iOS assumes the app did NOT handle the link and opens it in
    // Safari as a fallback — which then hits AppsFlyer's store redirect and
    // bounces to the App Store. Returning `true` here claims the link so iOS
    // does not open Safari. The app has already handled it internally.
    if userActivity.activityType == NSUserActivityTypeBrowsingWeb {
      return true
    }
    return false
  }
}
