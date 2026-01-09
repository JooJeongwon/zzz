import Flutter
import UIKit
import ActivityKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    private var currentActivity: Any? = nil

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "com.example.zzz/native",
                                           binaryMessenger: controller.binaryMessenger)
        
        channel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }
            
            if #available(iOS 16.1, *) {
                self.handleActivityMethodCall(call, result: result)
            } else {
                // Live Activities are not supported on this version
                if call.method == "startLiveActivity" || call.method == "updateLiveActivity" || call.method == "stopLiveActivity" {
                    result(FlutterError(code: "UNSUPPORTED_VERSION", message: "iOS 16.1+ required for Live Activities", details: nil))
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    @available(iOS 16.1, *)
    private func handleActivityMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startLiveActivity":
            guard let args = call.arguments as? [String: Any],
                  let status = args["status"] as? String,
                  let message = args["message"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing status or message", details: nil))
                return
            }
            startLiveActivity(status: status, message: message)
            result(nil)
            
        case "updateLiveActivity":
            guard let args = call.arguments as? [String: Any],
                  let status = args["status"] as? String,
                  let message = args["message"] as? String else {
                result(FlutterError(code: "INVALID_ARGS", message: "Missing status or message", details: nil))
                return
            }
            updateLiveActivity(status: status, message: message)
            result(nil)
            
        case "stopLiveActivity":
            stopLiveActivity()
            result(nil)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    @available(iOS 16.1, *)
    private func startLiveActivity(status: String, message: String) {
        // Save to Shared Defaults for Home Screen Widget
        saveToSharedDefaults(status: status, message: message)

        // End existing activity if any
        if currentActivity != nil {
            stopLiveActivity()
        }
        
        let attributes = ZZZActivityAttributes(characterName: "MyPet") // Could be dynamic
        let contentState = ZZZActivityAttributes.ContentState(status: status, message: message)
        
        do {
            let activity = try Activity<ZZZActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: nil)
            )
            self.currentActivity = activity
            print("Live Activity started: \(activity.id)")
        } catch {
            print("Error requesting Live Activity: \(error.localizedDescription)")
        }
    }
    
    @available(iOS 16.1, *)
    private func updateLiveActivity(status: String, message: String) {
        // Save to Shared Defaults for Home Screen Widget
        saveToSharedDefaults(status: status, message: message)

        guard let activity = currentActivity as? Activity<ZZZActivityAttributes> else {
            print("No active Live Activity to update")
            return
        }
        
        let contentState = ZZZActivityAttributes.ContentState(status: status, message: message)
        
        Task {
            await activity.update(using: contentState)
            print("Live Activity updated")
        }
    }
    
    @available(iOS 16.1, *)
    private func stopLiveActivity() {
        // Clear Shared Defaults (or set to Offline)
        saveToSharedDefaults(status: "OFFLINE", message: "연결 끊김")

        guard let activity = currentActivity as? Activity<ZZZActivityAttributes> else { return }
        
        Task {
            await activity.end(dismissalPolicy: .immediate)
            self.currentActivity = nil
            print("Live Activity ended")
        }
    }

    private func saveToSharedDefaults(status: String, message: String) {
        if let userDefaults = UserDefaults(suiteName: "group.com.example.zzz") {
            userDefaults.set(status, forKey: "status")
            userDefaults.set(message, forKey: "message")
            userDefaults.set(Date().timeIntervalSince1970, forKey: "lastUpdated")
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            print("Error: Could not access App Group 'group.com.example.zzz'. Make sure it's enabled in Xcode capabilities.")
        }
    }
}
