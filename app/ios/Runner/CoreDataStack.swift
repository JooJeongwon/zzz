import CoreData

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
