//
//  Flickr.swift
//  Virtual Tourist
//
//  Created by Venkata Palakodety on 12/28/15.
//  Copyright © 2015 Venkata Palakodety. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation


let MAX_SEARCH = 100;


// Flickr Class to perform a Flickr Search for images.
class Flickr : NSObject {
    typealias Completion = (results:[(String,String)]?, error:NSError?)->Void
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    struct Constants {
        
        static let METHOD_NAME = "flickr.photos.search"
        static let apiKey = "8037b52f90028f2826375f03239e9da4"
        static let BASE_URL = "https://api.flickr.com/services/rest/"
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
        static let NO_JSON_CALLBACK = "1"
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
        static let ID = "id"
        static let URL = "url_m"
        static let Per_Page = "20"
    }
    
    func taskForSearch(methodArguments : [String: AnyObject] , completionHandler : (data:
        AnyObject! , errorString: String?) -> Void) -> NSURLSessionDataTask{
            
            let urlString = Constants.BASE_URL + escapedParameters(methodArguments)
            let url = NSURL(string: urlString)!
            let request = NSURLRequest(URL: url)
            
            let task = session.dataTaskWithRequest(request) {data, response, downloadError in
                if let error = downloadError {
                    print("Could not complete the request \(error)")
                } else {
                    do {
                        let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments) as! NSDictionary
                        if let photosDictionary = parsedResult.valueForKey("photos") as? [String:AnyObject] {
                            
                            completionHandler(data: photosDictionary, errorString: nil)
                        } else {
                            print("Cant find key 'photos' in \(parsedResult)")
                        }
                    } catch {}
                }
                
            }
            task.resume()
            return task
    }
    
    func taskForImage(path : String , completionHandler : (data:
        NSData? , errorString: String?) -> Void) -> NSURLSessionDataTask{
            let urlString = path
            let url = NSURL(string: urlString)!
            let request = NSURLRequest(URL: url)
            
            let task = session.dataTaskWithRequest(request) {data, response, downloadError in
                if let error = downloadError {
                    print("Could not complete the request \(error)")
                } else {
                    completionHandler(data: data, errorString: nil)
                }
                
            }
            task.resume()
            return task
    }
    
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            /* Make sure that it is a string value */
            let stringValue = "\(value)"
            
            /* Escape it */
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            /* Append it */
            urlVars += [key + "=" + "\(escapedValue!)"]
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") +  urlVars.joinWithSeparator("&")
    }
    
    func createBoundingBoxString(latitude: Double, longitude: Double) -> String {
        
        let bottom_left_lon = max(longitude - Constants.BOUNDING_BOX_HALF_WIDTH, Constants.LON_MIN)
        let bottom_left_lat = max(latitude - Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LAT_MIN)
        let top_right_lon = min(longitude + Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LON_MAX)
        let top_right_lat = min(latitude + Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
    class func sharedInstance() -> Flickr {
        struct Singleton {
            static var sharedInstance = Flickr()
        }
        return Singleton.sharedInstance
    }
    
    struct Caches {
        static let imagecache = imageCache()
    }
}