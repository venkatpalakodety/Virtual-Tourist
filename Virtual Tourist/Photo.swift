//
//  Photo.swift
//  Virtual Tourist
//
//  Created by Venkata Palakodety on 12/28/15.
//  Copyright © 2015 Venkata Palakodety. All rights reserved.
//

// 1. Import Foundation, CoreData and UIKit
import Foundation
import CoreData
import UIKit

@objc(Photo)

// 2. Make Photo a subclass of NSManagedObject
class Photo: NSManagedObject {
    struct Keys {
        static let Id = "id"
        static let Path = "path"
        static let Location = "location"
    }
    
    // 3. We are promoting these three from simple properties, to Core Data attributes
    @NSManaged var id:String
    @NSManaged var path:String
    @NSManaged var pin:Pin?
    
    // 4. Include this standard Core Data init method.
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    /**
     * 5. The two argument init method
     *
     * The Two argument Init method. The method has two goals:
     *  - insert the new Photo into a Core Data Managed Object Context
     *  - initialze the Photo's properties from a dictionary
     */
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Get the entity associated with the "Photo" type.  This is an object that contains
        // the information from the Virtual_Tourist.xcdatamodeld file.
        let entity =  NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        // Now we can call an init method that we have inherited from NSManagedObject. Remember that
        // the Photo class is a subclass of NSManagedObject. This inherited init method does the
        // work of "inserting" our object into the context that was passed in as a parameter
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // After the Core Data work has been taken care of we can init the properties from the
        // dictionary.
        path = dictionary[Keys.Path] as! String
        id = dictionary[Keys.Id] as! String
    }
    
    var pinImage: UIImage? {
        
        get {
            return Flickr.Caches.imagecache.imageWithIdentifier(path)
        }
        
        set {
            self.sharedContext.performBlockAndWait({
                Flickr.Caches.imagecache.storeImage(newValue, withIdentifier: self.path)
            })
        }
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
        
}
