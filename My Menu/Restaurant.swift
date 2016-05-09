//
//  Restaurant.swift
//  My Menu
//
//  Created by Michael Miller on 4/9/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import Foundation
import CoreData
import MapKit

class Restaurant: NSManagedObject, MKAnnotation {
    
    //because the icon image is so small, it was saved within the persistent store rather than in the documents directory
    @NSManaged var iconPhoto: NSData?
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var placeID: String
    @NSManaged var subtitle: String?
    @NSManaged var title: String?
    @NSManaged var dateAdded: NSDate
    @NSManaged var url: String?
    
    @NSManaged var menuItems: [MenuItem]?
    
    var averageItemRating: Double?  //valued that isn't persisted, but is set when table gets loaded in order to enable this value to be sorted on
    
    //enables class to conform to MKAnnotation protocol; computed property since its type can't be persisted
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    //computed (non-persisted) property that returns the number of menu items assocatiated with this restaurant
    var menuItemCount: Int {
        if let items = menuItems {
            return items.count
        } else {
            return 0
        }
    }
    
    //computed (non-persisted) property that returns the total number of times all of the menu items assocatiated with this restaurant have been collectively ordered
    var totalItemsOrdered: Int {
        if let items = menuItems {
            var count = 0
            for item in items {
                count += Int(item.timesOrdered)
            }
            return count
        } else {
            return 0
        }
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(placeID: String, title: String?, subtitle: String?, latitude: Double, longitude: Double, url: String?, iconPhoto: NSData?, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Restaurant", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        self.placeID = placeID
        self.title = title
        self.subtitle = subtitle
        self.latitude = latitude
        self.longitude = longitude
        self.url = url
        self.iconPhoto = iconPhoto
        
        //date stamp added so that sorting on "Most Recently Added" can by accomplished
        dateAdded = NSDate()
    }
}