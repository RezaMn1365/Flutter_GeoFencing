import UIKit
import Flutter
import GoogleMaps //add for maps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    GMSServices.provideAPIKey("AIzaSyBtwK_fT-9RPMFfordZ8aLbBB0YEFb4rpA")  //ios google map api
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
