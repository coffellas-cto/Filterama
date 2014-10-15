//
//  PersistenceManager.swift
//  Filterama
//
//  Created by Alex G on 14.10.14.
//  Copyright (c) 2014 Alexey Gordiyenko. All rights reserved.
//

import Foundation
import CoreData

class PersistenceManager {
    
    // MARK: Class Variables
    
    class var manager: PersistenceManager {
        struct Static {
            static var instance: PersistenceManager?
            static var token: dispatch_once_t = 0
        }
        dispatch_once(&Static.token) {
            Static.instance = PersistenceManager()
        }
        return Static.instance!
    }
    
    // MARK: Public Properties
    
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as NSURL
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = NSBundle.mainBundle().URLForResource("Filterama", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Filterama.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError.errorWithDomain("YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext! = {
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: Private Methods
    private func fetchObjectsWithEntityName(name: String, predicate: NSPredicate? = nil) -> [AnyObject]? {
        var request = NSFetchRequest(entityName: name)
        if predicate != nil {
            request.predicate = predicate
        }
        var error: NSError?
        var retVal = managedObjectContext.executeFetchRequest(request, error: &error)
        if error == nil {
            return retVal
        }
        
        println(error?.localizedDescription)
        return nil
    }
    
    // MARK: Public Methods
    
    func fetchFilters() -> [Filter]? {
        return fetchObjectsWithEntityName("Filter") as? [Filter]
    }
    
    func populateFilters() {
        for i: Int16 in 0..<2 {
            var newFilter = NSEntityDescription.insertNewObjectForEntityForName("Filter", inManagedObjectContext: managedObjectContext) as Filter
            newFilter.idx = i
            
            switch i {
            case 0:
                newFilter.name = "CISepiaTone"
                newFilter.friendlyName = "Sepia"
            case 1:
                newFilter.name = "CIGaussianBlur"
                newFilter.friendlyName = "Blur"
            default:
                break
            }
        }
        
        saveContext()
    }
    
    func saveContext() {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }

}
