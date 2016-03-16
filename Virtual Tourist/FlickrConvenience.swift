//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by Venkata Palakodety on 12/28/15.
//  Copyright © 2015 Venkata Palakodety. All rights reserved.
//

import Foundation
import UIKit

// Flickr extension Helper Class to abstract parsing and getting Photos.
extension Flickr {
    
    func flickrSearch(latitude: Double, longitude: Double, completionHandler: (success: Bool, Photos: [[String: AnyObject]]? ,errorString: String?) -> Void) {
        
        let methodArguments : [String : AnyObject] = [
            "method": Constants.METHOD_NAME,
            "api_key": Constants.apiKey,
            "bbox": createBoundingBoxString(latitude, longitude: longitude),
            "safe_search": Constants.SAFE_SEARCH,
            "extras": Constants.EXTRAS,
            "format": Constants.DATA_FORMAT,
            "nojsoncallback": Constants.NO_JSON_CALLBACK,
            "per_page" : Constants.Per_Page
        ]
        
        getPage(methodArguments) { (success, PageNum , errorString) in
            
            if success {
                var withPageDictionary = methodArguments
                withPageDictionary["page"] = PageNum
                self.getPhotos(withPageDictionary) { (success, Photos , errorString) in
                    if success {
                        completionHandler(success: true, Photos: Photos , errorString: errorString)
                    } else {
                        completionHandler(success: false, Photos: nil , errorString: errorString)
                    }
                }
            } else {
                completionHandler(success: false, Photos: nil , errorString: errorString)
            }
        }
        
    }
    
    
    func getPage(methodArguments : [String: AnyObject], completionHandler: (success: Bool, PageNum: Int? ,errorString: String?) -> Void) {
        
        _ = taskForSearch(methodArguments) { JSONResult, error in
            
            if let _ = error {
                completionHandler(success: false, PageNum: nil , errorString: "Network Error")
            } else {
                
                if let totalPages = JSONResult.valueForKey("pages") as? Int {
                    
                    let pageLimit = min(totalPages, 40)
                    let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                    completionHandler(success: true, PageNum: randomPage , errorString: "Done")
                    
                } else {
                    completionHandler(success: false, PageNum: nil , errorString: "No Pages")
                }
            }
        }
    }
    
    func getPhotos (methodArguments : [String: AnyObject], completionHandler: (success: Bool, Photos: [[String: AnyObject]]? ,errorString: String?) -> Void) {
        
        _ = taskForSearch(methodArguments) { JSONResult, error in
            
            if let _ = error {
                completionHandler(success: false, Photos: nil , errorString: "Network Error")
            } else {
                
                var totalPhotosVal = 0
                if let totalPhotos = JSONResult.valueForKey("total") as? String {
                    totalPhotosVal = (totalPhotos as NSString).integerValue
                }
                
                if totalPhotosVal > 0 {
                    if let photosArray = JSONResult.valueForKey("photo") as? [[String: AnyObject]] {
                        
                        completionHandler(success: true, Photos: photosArray , errorString: "Done")
                        
                    } else {
                        completionHandler(success: false, Photos: nil , errorString: "No Key")
                    }
                } else {
                    completionHandler(success: false, Photos: nil , errorString: "No Photos")
                }
            }
        }
        
    }
}