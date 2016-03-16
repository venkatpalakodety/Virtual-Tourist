//
//  Pin.swift
//  Virtual Tourist
//
//  Created by Venkata Palakodety on 12/28/15.
//  Copyright © 2015 Venkata Palakodety. All rights reserved.
//

// 1. Import Foundation and CoreData
import Foundation
import CoreData

@objc(Pin)

// 2. Make Pin a subclass of NSManagedObject
class Pin: NSManagedObject{
    
    struct Keys {
        static let Latitude = "latitude"
        static let Longitude = "longitude"
        static let Photos = "photos"
    }
    
    // 3. We are promoting these three from simple properties, to Core Data attributes
    @NSManaged var latitude:Double
    @NSManaged var longitude:Double
    @NSManaged var photos: [Photo]
    
    // 4. Include this standard Core Data init method.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    /**
     * 5. The two argument init method
     *
     * The Two argument Init method. The method has two goals:
     *  - insert the new Pin into a Core Data Managed Object Context
     *  - initialze the Pin's properties from a dictionary
     */
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Get the entity associated with the "Pin" type.  This is an object that contains
        // the information from the Virtual_Tourist.xcdatamodeld file.
        let entity =  NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Pin class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity,insertIntoManagedObjectContext: context)
        
        // After the Core Data work has been taken care of we can init the properties from the
        // dictionary.
        latitude = dictionary[Keys.Latitude] as! Double
        longitude = dictionary[Keys.Longitude] as! Double
    }
}
