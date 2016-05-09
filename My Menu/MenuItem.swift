//
//  MenuItem.swift
//  My Menu
//
//  Created by Michael Miller on 4/9/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import Foundation
import CoreData

class MenuItem: NSManagedObject {
    
    @NSManaged var itemDescription: String?
    @NSManaged var notes: String?
    @NSManaged var myRating: Int16
    @NSManaged var timesOrdered: Int16
    @NSManaged var title: String
    @NSManaged var dateAdded: NSDate
    
    @NSManaged var restaurant: Restaurant
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(title: String, restaurant: Restaurant, itemDescription: String?, notes: String?, myRating: Int16, timesOrdered: Int16, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("MenuItem", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.title = title
        self.itemDescription = itemDescription
        self.notes = notes
        self.myRating = myRating
        self.timesOrdered = timesOrdered
        self.restaurant = restaurant
        
        //date stamp added so that sorting on "Most Recently Added" can by accomplished
        dateAdded = NSDate()
    }
    
}
