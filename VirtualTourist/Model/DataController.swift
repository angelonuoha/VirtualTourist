//
//  DataController.swift
//  VirtualTourist
//
//  Created by Angel Onuoha on 1/24/20.
//  Copyright © 2020 Angel Onuoha. All rights reserved.
//

import Foundation
import CoreData

class DataController {
    let persistentContainer: NSPersistentContainer
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext!
    
    func configureContexts() {
        backgroundContext = persistentContainer.newBackgroundContext()
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    func load() {
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            self.configureContexts()
            
        }
    }
    
    func saveContext() {
        try? persistentContainer.viewContext.save()
    }
    
    
}
