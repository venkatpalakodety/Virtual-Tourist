//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Venkata Palakodety on 12/28/15.
//  Copyright © 2015 Venkata Palakodety. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate, NSFetchedResultsControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!

    var pressRecognizer: UILongPressGestureRecognizer? = nil
    var pins : [Pin]!
    var PinToBeAdded : Pin!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        mapView.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        fetchedResultsController.delegate = self
        pressRecognizer = UILongPressGestureRecognizer(target: self, action: "addPinToMap:")
        let lat = NSUserDefaults.standardUserDefaults().doubleForKey("latitude")
        let long = NSUserDefaults.standardUserDefaults().doubleForKey("longitude")
        let latD = NSUserDefaults.standardUserDefaults().doubleForKey("latitudeDelta")
        let longD = NSUserDefaults.standardUserDefaults().doubleForKey("longitudeDelta")
        let coor = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: long), span: MKCoordinateSpan(latitudeDelta: latD, longitudeDelta: longD))
        if(lat != 0.0){
            mapView.setRegion(coor, animated: true)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        view.addGestureRecognizer(pressRecognizer!)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        view.removeGestureRecognizer(pressRecognizer!)
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        NSUserDefaults.standardUserDefaults().setDouble(self.mapView.region.center.latitude, forKey: "latitude")
        NSUserDefaults.standardUserDefaults().setDouble(self.mapView.region.center.longitude, forKey: "longitude")
        NSUserDefaults.standardUserDefaults().setDouble(self.mapView.region.span.latitudeDelta, forKey: "latitudeDelta")
        NSUserDefaults.standardUserDefaults().setDouble(self.mapView.region.span.longitudeDelta, forKey: "longitudeDelta")
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
        
    }
    
    lazy var fetchedResultsController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true)]
        self.sharedContext.performBlockAndWait({
            do {
                let results = try self.sharedContext.executeFetchRequest(fetchRequest)
                var annotations = [MKPointAnnotation]()
                let pin = results as! [Pin]
                self.pins = pin
                
                for dictionary in pin {
                    let lat = CLLocationDegrees(dictionary.latitude as Double)
                    let long = CLLocationDegrees(dictionary.longitude as Double)
                    let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
                    var annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate
                    annotations.append(annotation)
                }
                
                self.mapView.addAnnotations(annotations)
            } catch {
                print("Unable to fetch tourist locations: \(error)")
            }
            
        })
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.enabled = true
            pinView!.draggable = true
            pinView!.pinTintColor = UIColor.redColor()
        } else {
            pinView!.annotation = annotation
        }
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        self.sharedContext.performBlockAndWait({
            for pin in self.pins {
                if pin.latitude == view.annotation!.coordinate.latitude && pin.longitude == view.annotation!.coordinate.longitude {
                    let controller = self.storyboard!.instantiateViewControllerWithIdentifier("PhotoAlbum") as! PhotoAlbumViewController
                    controller.pin = pin
                    controller.latitude = pin.latitude
                    controller.longitude = pin.longitude
                    let nav = UINavigationController()
                    nav.pushViewController(controller, animated: false)
                    self.mapView.deselectAnnotation(view.annotation!, animated: true)
                    dispatch_async(dispatch_get_main_queue(), {
                        self.presentViewController(nav, animated: true, completion: nil)
                    })
                }
            }
        })
    }
    
    // Add a Pin to the Map. Also, perform a flickr Search while we are at it.
    func addPinToMap(gestureRecognizer: UIGestureRecognizer) {
        
        if (gestureRecognizer.state) != UIGestureRecognizerState.Ended {
            return
        } else {
            let touchpoint = gestureRecognizer.locationInView(mapView)
            let touchCoordinate = mapView.convertPoint(touchpoint, toCoordinateFromView: mapView)
            let geoLoc = CLLocationCoordinate2D(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude)
            let dictionary: [String : AnyObject] = [
                Pin.Keys.Latitude : touchCoordinate.latitude,
                Pin.Keys.Longitude : touchCoordinate.longitude,
            ]
            self.sharedContext.performBlockAndWait({
                self.PinToBeAdded = Pin(dictionary: dictionary, context: self.sharedContext)
                CoreDataStackManager.sharedInstance().saveContext()
                self.pins.append(self.PinToBeAdded)
            })
            let annotation = MKPointAnnotation()
            annotation.coordinate = geoLoc
            mapView.addAnnotation(annotation)
            
            Flickr.sharedInstance().flickrSearch(touchCoordinate.latitude, longitude: touchCoordinate.longitude){ (success, Photos ,errorString) in
                if success {
                    if let Photos = Photos {
                        for photo in Photos {
                            let dictionary: [String : AnyObject] = [
                                Photo.Keys.Id : photo[Flickr.Constants.ID]!,
                                Photo.Keys.Path : photo[Flickr.Constants.URL]! ,
                            ]
                            self.sharedContext.performBlockAndWait({
                                let pic = Photo(dictionary: dictionary, context: self.sharedContext)
                                pic.pin = self.PinToBeAdded
                                CoreDataStackManager.sharedInstance().saveContext()
                            })
                        }
                    } else {
                        
                    }
                }
            }
        }
    }

}

