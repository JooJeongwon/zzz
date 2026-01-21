import Flutter
import UIKit
import ActivityKit
import WidgetKit
import CoreData
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {
    
    private var currentActivity: Any? = nil
    private let heartbeatRepository = HeartbeatRepository()
    private let heartbeatTaskId = "com.joo.zzz.heartbeat"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        // Register Background Task
        BGTaskScheduler.shared.register(forTaskWithIdentifier: heartbeatTaskId, using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }
        
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

                // Save credentials for background tasks
                UserDefaults.standard.set(baseUrl, forKey: "heartbeat_base_url")
                UserDefaults.standard.set(accessToken, forKey: "heartbeat_access_token")

                self.performHeartbeat(baseUrl: baseUrl, accessToken: accessToken) { success, message in
                    result(message)
                }
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
    
    override func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleAppRefresh()
    }
    
    // MARK: - Background Tasks
    
    private func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: heartbeatTaskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes later
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("Background Task Scheduled: \(heartbeatTaskId)")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    private func handleAppRefresh(task: BGAppRefreshTask) {
        scheduleAppRefresh() // Schedule the next one
        
        task.expirationHandler = {
            // Cancel operations if time runs out
        }
        
        guard let baseUrl = UserDefaults.standard.string(forKey: "heartbeat_base_url"),
              let accessToken = UserDefaults.standard.string(forKey: "heartbeat_access_token") else {
            print("Missing credentials for background heartbeat")
            task.setTaskCompleted(success: false)
            return
        }
        
        print("Executing background heartbeat...")
        performHeartbeat(baseUrl: baseUrl, accessToken: accessToken) { success, msg in
            print("Background heartbeat result: \(msg)")
            task.setTaskCompleted(success: success)
        }
    }
    
    // MARK: - Heartbeat Logic
    
    private func performHeartbeat(baseUrl: String, accessToken: String, completion: @escaping (Bool, String) -> Void) {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let rawBattery = UIDevice.current.batteryLevel
        let batteryLevel = rawBattery < 0 ? 100 : Int(rawBattery * 100)
        let isScreenOn = UIScreen.main.brightness > 0.0 // Approximation for background check
        let timestamp = Date().timeIntervalSince1970 * 1000 // ms

        let pendingLogs = self.heartbeatRepository.getAll()
        let hasPending = !pendingLogs.isEmpty
        
        let targetUrl: URL?
        var body: [String: Any] = [:]
        
        if hasPending {
            guard let url = URL(string: "\(baseUrl)/users/heartbeat/batch") else {
                 completion(false, "Invalid URL")
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
                 completion(false, "Invalid URL")
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
            self.heartbeatRepository.insert(timestamp: timestamp, batteryLevel: batteryLevel, isScreenOn: isScreenOn)
            completion(false, "JSON Error")
            return
        }

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Heartbeat Error: \(error.localizedDescription). Saving to DB.")
                self.heartbeatRepository.insert(timestamp: timestamp, batteryLevel: batteryLevel, isScreenOn: isScreenOn)
                completion(false, "Heartbeat Saved (Offline Mode)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if (200...299).contains(httpResponse.statusCode) {
                    if hasPending {
                        self.heartbeatRepository.deleteAll()
                    }
                    completion(true, "Heartbeat Sent (Batch: \(hasPending))")
                } else {
                    self.heartbeatRepository.insert(timestamp: timestamp, batteryLevel: batteryLevel, isScreenOn: isScreenOn)
                    completion(false, "Heartbeat Saved (Server Error: \(httpResponse.statusCode))")
                }
            } else {
                self.heartbeatRepository.insert(timestamp: timestamp, batteryLevel: batteryLevel, isScreenOn: isScreenOn)
                completion(false, "Heartbeat Saved (No Response)")
            }
        }
        task.resume()
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

// MARK: - CoreDataStack & HeartbeatRepository Merged
// Merged here because these files were not correctly added to the Xcode project target, causing build failures.

class CoreDataStack {
    static let shared = CoreDataStack()

    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "HeartbeatModel", managedObjectModel: self.managedObjectModel)
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        }
        return container
    }()

    // Programmatically define the model to avoid touching project.pbxproj
    lazy var managedObjectModel: NSManagedObjectModel = {
        let model = NSManagedObjectModel()
        
        let entity = NSEntityDescription()
        entity.name = "HeartbeatLog"
        entity.managedObjectClassName = NSStringFromClass(NSManagedObject.self)
        
        let timestampAttr = NSAttributeDescription()
        timestampAttr.name = "timestamp"
        timestampAttr.attributeType = .doubleAttributeType
        timestampAttr.isOptional = false
        
        let batteryAttr = NSAttributeDescription()
        batteryAttr.name = "batteryLevel"
        batteryAttr.attributeType = .integer16AttributeType
        batteryAttr.isOptional = false
        
        let screenAttr = NSAttributeDescription()
        screenAttr.name = "isScreenOn"
        screenAttr.attributeType = .booleanAttributeType
        screenAttr.isOptional = false
        
        entity.properties = [timestampAttr, batteryAttr, screenAttr]
        
        model.entities = [entity]
        return model
    }()

    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("CoreData Save Error: \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

class HeartbeatRepository {
    private let context = CoreDataStack.shared.context

    func insert(timestamp: Double, batteryLevel: Int, isScreenOn: Bool) {
        let entity = NSEntityDescription.insertNewObject(forEntityName: "HeartbeatLog", into: context)
        entity.setValue(timestamp, forKey: "timestamp")
        entity.setValue(Int16(batteryLevel), forKey: "batteryLevel")
        entity.setValue(isScreenOn, forKey: "isScreenOn")
        
        CoreDataStack.shared.saveContext()
        print("Saved heartbeat to CoreData: \(timestamp)")
    }

    func getAll() -> [NSManagedObject] {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "HeartbeatLog")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: true)]
        
        do {
            return try context.fetch(fetchRequest)
        } catch {
            print("Failed to fetch heartbeats: \(error)")
            return []
        }
    }

    func deleteAll() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "HeartbeatLog")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try context.execute(deleteRequest)
            CoreDataStack.shared.saveContext()
            print("Cleared all heartbeat logs from CoreData")
        } catch {
            print("Failed to delete heartbeats: \(error)")
        }
    }
}