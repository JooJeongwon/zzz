import CoreData
import Foundation

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
