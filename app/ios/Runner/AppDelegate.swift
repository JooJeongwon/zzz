import Flutter
import UIKit
import ActivityKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    private var currentActivity: Any? = nil
    private let heartbeatRepository = HeartbeatRepository()

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let controller = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(name: "com.joo.zzz.app/heartbeat",
                                           binaryMessenger: controller.binaryMessenger)
        
        channel.setMethodCallHandler({ [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }
            
            if call.method == "startHeartbeat" {
                guard let args = call.arguments as? [String: Any],
                      let baseUrl = args["baseUrl"] as? String,
                      let accessToken = args["accessToken"] as? String else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Missing baseUrl or accessToken", details: nil))
                    return
                }

                UIDevice.current.isBatteryMonitoringEnabled = true
                let rawBattery = UIDevice.current.batteryLevel
                let batteryLevel = rawBattery < 0 ? 100 : Int(rawBattery * 100)
                let isScreenOn = true
                let timestamp = Date().timeIntervalSince1970 * 1000 // ms

                let pendingLogs = self.heartbeatRepository.getAll()
                let hasPending = !pendingLogs.isEmpty
                
                let targetUrl: URL?
                var body: [String: Any] = [:]
                
                if hasPending {
                    guard let url = URL(string: "\(baseUrl)/users/heartbeat/batch") else {
                         result(FlutterError(code: "INVALID_URL", message: "Invalid URL", details: nil))
                         return
                    }
                    targetUrl = url
                    
                    var heartbeats: [[String: Any]] = []
                    for log in pendingLogs {
                        heartbeats.append([
                            "timestamp": log.value(forKey: "timestamp") as? Double ?? 0.0,
                            "batteryLevel": log.value(forKey: "batteryLevel") as? Int ?? 0,
                            "isScreenOn": log.value(forKey: "isScreenOn") as? Bool ?? false
                        ])
                    }
                    // Add current
                    heartbeats.append([
                        "timestamp": timestamp,
                        "batteryLevel": batteryLevel,
                        "isScreenOn": isScreenOn
                    ])
                    
                    body["heartbeats"] = heartbeats
                } else {
                    guard let url = URL(string: "\(baseUrl)/users/heartbeat") else {
                         result(FlutterError(code: "INVALID_URL", message: "Invalid URL", details: nil))
                         return
                    }
                    targetUrl = url
                    body = [
                        "batteryLevel": batteryLevel,
                        "isScreenOn": isScreenOn,
                        "timestamp": timestamp
                    ]
                }

                guard let finalUrl = targetUrl else { return }

                var request = URLRequest(url: finalUrl)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

                do {
                    request.httpBody = try JSONSerialization.data(withJSONObject: body, options: [])
                } catch {
                    // If serialization fails, we can't send, so save current to DB
                    self.heartbeatRepository.insert(timestamp: timestamp, batteryLevel: batteryLevel, isScreenOn: isScreenOn)
                    result(FlutterError(code: "JSON_ERROR", message: "Failed to encode body", details: nil))
                    return
                }

                print("Sending Heartbeat (Batch: \(hasPending)) to \(finalUrl.absoluteString)")

                let task = URLSession.shared.dataTask(with: request) { data, response, error in
                    if let error = error {
                        print("Heartbeat Error: \(error.localizedDescription). Saving to DB.")
                        self.heartbeatRepository.insert(timestamp: timestamp, batteryLevel: batteryLevel, isScreenOn: isScreenOn)
                        // Return success to Flutter because we handled it offline
                        result("Heartbeat Saved (Offline Mode)")
                        return
                    }

                    if let httpResponse = response as? HTTPURLResponse {
                        if (200...299).contains(httpResponse.statusCode) {
                            if hasPending {
                                self.heartbeatRepository.deleteAll()
                                print("Batch sent successfully. Cleared logs.")
                            }
                            result("Heartbeat Sent (Batch: \(hasPending))")
                        } else {
                            print("Heartbeat Failed: Status \(httpResponse.statusCode). Saving to DB.")
                            self.heartbeatRepository.insert(timestamp: timestamp, batteryLevel: batteryLevel, isScreenOn: isScreenOn)
                             // Return success to Flutter because we handled it offline
                            result("Heartbeat Saved (Server Error: \(httpResponse.statusCode))")
                        }
                    } else {
                        self.heartbeatRepository.insert(timestamp: timestamp, batteryLevel: batteryLevel, isScreenOn: isScreenOn)
                        result("Heartbeat Saved (No Response)")
                    }
                }
                task.resume()
                return
            }

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
        if let userDefaults = UserDefaults(suiteName: "group.com.joo.zzz") {
            userDefaults.set(status, forKey: "status")
            userDefaults.set(message, forKey: "message")
            userDefaults.set(Date().timeIntervalSince1970, forKey: "lastUpdated")
            WidgetCenter.shared.reloadAllTimelines()
        } else {
            print("Error: Could not access App Group 'group.com.joo.zzz'. Make sure it's enabled in Xcode capabilities.")
        }
    }
}
