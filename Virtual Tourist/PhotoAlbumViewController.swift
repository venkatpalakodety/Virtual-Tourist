//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Venkata Palakodety on 12/28/15.
//  Copyright © 2015 Venkata Palakodety. All rights reserved.
//

import UIKit
import MapKit
import CoreData
import Foundation

class PhotoAlbumViewController: UIViewController, UICollectionViewDelegate,  MKMapViewDelegate, UICollectionViewDataSource ,NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    
    @IBOutlet weak var newCollectionButton: UIButton!
    
    var latitude: Double!
    var longitude: Double!
    var pin : Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "OK", style: .Plain, target: self, action: "closePage")
        
        photoCollectionView.delegate = self
        photoCollectionView.dataSource = self
        do {
            // Fetch the results and show the gallery.
            try fetchedResultsController.performFetch()
        } catch{ }
        fetchedResultsController.delegate = self
        
        let coor = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude), span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        
        mapView.setRegion(coor, animated: true)
        
        let geoLoc = CLLocationCoordinate2D(latitude: self.latitude, longitude: self.longitude)
        let annotation = MKPointAnnotation()
        annotation.coordinate = geoLoc
        mapView.addAnnotation(annotation)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func closePage() {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        var error : NSError?
        let fetchRequest = NSFetchRequest(entityName: "Photo")
        fetchRequest.predicate = NSPredicate(format: "pin == %@", self.pin)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
            managedObjectContext: self.sharedContext,
            sectionNameKeyPath: nil,
            cacheName: nil)
        
        return fetchedResultsController
        
    }()
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultsController.sections![section]
        
        if(sectionInfo.numberOfObjects == 0)
        {
            newCollectionButton.setTitle("No Photos Found for this location.", forState: UIControlState.Disabled)
            newCollectionButton.enabled = false
        }
        else
        {
            newCollectionButton.setTitle("New Collection", forState: UIControlState.Normal)
        }
        return sectionInfo.numberOfObjects
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("imageCell", forIndexPath: indexPath) as! PhotoAlbumViewCell
        let photo = fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
        
        configureCell(cell, photo: photo)
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath:NSIndexPath)
    {
        self.sharedContext.performBlockAndWait({
            let photo = self.fetchedResultsController.objectAtIndexPath(indexPath) as! Photo
            let manager = NSFileManager.defaultManager()
            let filePath = Flickr.Caches.imagecache.pathForIdentifier(photo.path)
            do {
                try manager.removeItemAtPath(filePath)
            } catch { }
            self.sharedContext.deleteObject(photo)
            CoreDataStackManager.sharedInstance().saveContext()
        })
        
    }
    
    func configureCell(cell: PhotoAlbumViewCell , photo: Photo){
        
        self.sharedContext.performBlockAndWait({
            if let image = NSKeyedUnarchiver.unarchiveObjectWithFile(Flickr.Caches.imagecache.pathForIdentifier(photo.path)) as? UIImage {
                cell.downloading.hidden = true
                cell.downloading.stopAnimating()
                cell.imageView!.image = image
            } else {
                cell.downloading.hidden = false
                cell.downloading.startAnimating()
                
                _ = Flickr.sharedInstance().taskForImage(photo.path){ data, error in
                    if let error = error {
                        print("Photo download error: \(error)")
                    }
                    if let data = data {
                        let image = UIImage(data: data)
                        photo.pinImage = image
                        self.sharedContext.performBlockAndWait({
                            NSKeyedArchiver.archiveRootObject(image!,toFile: Flickr.Caches.imagecache.pathForIdentifier(photo.path))
                        })
                        dispatch_async(dispatch_get_main_queue()) {
                            cell.downloading.hidden = true
                            cell.downloading.stopAnimating()
                            cell.imageView!.image = image
                        }
                    }
                }
            }
        })
        
    }
    
    var recordedChanges = [ (NSFetchedResultsChangeType,NSIndexPath)]()
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        recordedChanges = []
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        switch type {
        case .Insert:
            recordedChanges.append((.Insert,newIndexPath!))
        case .Delete:
            recordedChanges.append((.Delete,indexPath!))
        default:
            return
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        photoCollectionView.performBatchUpdates({
            for (type,index) in self.recordedChanges {
                switch type {
                case .Insert:
                    self.photoCollectionView.insertItemsAtIndexPaths([index])
                case .Delete:
                    self.photoCollectionView.deleteItemsAtIndexPaths([index])
                default:
                    continue
                }
            }
            }, completion: {done in
                dispatch_async(dispatch_get_main_queue(), {
                    self.newCollectionButton.enabled = true
                })
        })
    }

    @IBAction func newCollection(sender: AnyObject) {
        
        newCollectionButton.enabled = false
        self.sharedContext.performBlockAndWait({
            if let photos = self.fetchedResultsController.fetchedObjects as? [Photo] {
                for photo in photos {
                    self.sharedContext.deleteObject(photo)
                    photo.pinImage = nil
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        })
        Flickr.sharedInstance().flickrSearch(self.latitude, longitude: self.longitude){ (success, Photos ,errorString) in
            if success {
                if let Photos = Photos {
                    for photo in Photos {
                        
                        let dictionary: [String : AnyObject] = [
                            Photo.Keys.Id : photo[Flickr.Constants.ID]!,
                            Photo.Keys.Path : photo[Flickr.Constants.URL]! ,
                        ]
                        self.sharedContext.performBlockAndWait({
                            let pic = Photo(dictionary: dictionary, context: self.sharedContext)
                            pic.pin = self.pin
                            
                            CoreDataStackManager.sharedInstance().saveContext()
                        })
                    }
                    self.newCollectionButton.enabled = true
                    self.photoCollectionView?.reloadData()
                }
            } else {
                
            }
        }
    }

}
