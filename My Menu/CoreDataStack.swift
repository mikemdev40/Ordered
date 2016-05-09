//
//  CoreDataStack.swift
//  Virtual Tourist
//
//  Created by Michael Miller on 3/26/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    static let sharedInstance = CoreDataStack()
    
    //since the managed object context is the only component of the core data stack that the app will need to access directly, the other components are initiated as part of the lazy initialization of the context
    lazy var managedObjectContext: NSManagedObjectContext = {
        
        //part of this coding block inspired by the Core Data Programming Guide: https://developer.apple.com/library/tvos/documentation/Cocoa/Conceptual/CoreData/InitializingtheCoreDataStack.html#//apple_ref/doc/uid/TP40001075-CH4-SW1
        
        guard let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd") else {
            fatalError("Error loading the model from the bundle")
        }
        
        guard let managedObjectModel = NSManagedObjectModel(contentsOfURL: modelURL) else {
            fatalError("Error initializing the managed object model")
        }
        
        let persistentCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        
        context.persistentStoreCoordinator = persistentCoordinator
        
        //the undo manager is being added because in order to use the rollback() method on the managed object context, which removes all changes from the context (the desired case for when a user makes changes but then decides to cancel the changes)
        let undoManager = NSUndoManager()
        context.undoManager = undoManager

        //default value, but added for emphasis as to highlight that there is a constraint on the Restaurant entity, namely the placeID (a unique identifier returned by google)
        context.mergePolicy = NSErrorMergePolicy
        
        let urlForDocDirectory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first
        let urlForSQLDB = urlForDocDirectory?.URLByAppendingPathComponent("DataModel.sqlite")
        
        do {
            try persistentCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: urlForSQLDB, options: nil)
        } catch {
            fatalError("Error adding persistent store")
        }
        
        return context
    }()
    
    private init() {}
}