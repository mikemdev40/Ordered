//
//  GoogleMapsClient.swift
//  My Menu
//
//  Created by Michael Miller on 4/7/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import Foundation

class GoogleMapsClient {
    
    static let SharedInstance = GoogleMapsClient()
    
    private var searchSession: NSURLSession?
    
    ///cancels any pending calls to the google API for finding place names, called once any of the calls returns an error (or user cancels out of the place search box entirely)
    func cancelSearch() {
        searchSession?.delegateQueue.cancelAllOperations()
        searchSession?.invalidateAndCancel()
        searchSession = nil
    }
    
    //alternative to the above, which uses a task that cancels the previous task each time it is set (UNUSED, but maintained here for personal reference)
    /*
     private var searchTask: NSURLSessionDataTask? {
         didSet {
            if let taskToCancel = oldValue {
            taskToCancel.cancel()
            }
         }
     }*/
    
    ///returns an array of up to 5 results (max returned by google's "Place Autocomplete" API) of "predictions" that match or nearly match user's search text input (called/updated after each character is entered)
    func searchForTextEnteredUsingGoogleAutoComplete(searchString: String, latitude: Double?, longitude: Double?, completionHandler: (success: Bool, googleResults: [[String: AnyObject]]?, error: String?) -> Void) {
        
        //necessary because once a session is cancelled and invalidated, it can't be used again (need to get a new one); the same session is used here for google search string calls made in (generally) quick succession; the queue of search calls on this session gets cancelled and the session invalidated via the cancelSearch above (note to self: this is different from other API calls, in which separate sessions are made and invalidated)
        if searchSession == nil {
            searchSession = getConfiguredSession()
        }

        let nsurl = getGoogleURLForLocation(searchString, latitude: latitude, longitude: longitude)
        let request = NSURLRequest(URL: nsurl)
        
        //searchTask =
        let task = searchSession!.dataTaskWithRequest(request) { (data, response, error) in
            
            guard error == nil else {
                completionHandler(success: false, googleResults: nil, error: error?.localizedDescription)
                return
            }

            guard let data = data else {
                completionHandler(success: false, googleResults: nil, error: "There was an error getting the data.")
                return
            }
            
            guard let parsedData = GoogleMapsClient.parseData(data) else {
                completionHandler(success: false, googleResults: nil, error: "There was an error parsing the data.")
                return
            }
            
            guard let statusCode = parsedData["status"] as? String else {
                completionHandler(success: false, googleResults: nil, error: "There was an error parsing the status code.")
                return
            }
            
            guard statusCode == "OK" else {
                completionHandler(success: false, googleResults: nil, error: statusCode)
                return
            }
            
            guard let predictions = parsedData["predictions"] as? [NSDictionary] else {
                completionHandler(success: false, googleResults: nil, error: "There was an error parsing out the predictions.")
                return
            }
            
            if let predictionArray = predictions as? [[String: AnyObject]] {
                completionHandler(success: true, googleResults: predictionArray, error: nil)
            } else {
                completionHandler(success: false, googleResults: nil, error: "There was an error casting to array.")
            }
        }
        // searchTask!.resume()
        task.resume()
    }
    
    ///uses the placeID for a specific result from the selected google prediction array to retrieve details on a specific place via the google "Place Details" API (these details are then used to create the core data Restaurant entity)
    func searchForSpecificPlace(placeID: String, completionHandler: (success: Bool, googlePlaceInfo: [String: AnyObject]?, error: String?) -> Void) {
        
        let placeDetailsSession = getConfiguredSession()
        let nsurl = getGoogleURLForPlaceID(placeID)
        let request = NSURLRequest(URL: nsurl)
        
        let task = placeDetailsSession.dataTaskWithRequest(request) { (data, response, error) in

            guard error == nil else {
                completionHandler(success: false, googlePlaceInfo: nil, error: error?.localizedDescription)
                return
            }

            guard let data = data else {
                completionHandler(success: false, googlePlaceInfo: nil, error: "There was an error getting the data.")
                return
            }
            
            guard let parsedData = GoogleMapsClient.parseData(data) else {
                completionHandler(success: false, googlePlaceInfo: nil, error: "There was an error parsing the data.")
                return
            }
            
            guard let statusCode = parsedData["status"] as? String else {
                completionHandler(success: false, googlePlaceInfo: nil, error: "There was an error parsing the status code.")
                return
            }
            
            guard statusCode == "OK" else {
                completionHandler(success: false, googlePlaceInfo: nil, error: statusCode)
                return
            }
            
            guard let resultInfo = parsedData["result"] as? NSDictionary else {
                completionHandler(success: false, googlePlaceInfo: nil, error: "There was an error parsing out the result dictionary.")
                return
            }
            
            if let resultDetails = resultInfo as? [String: AnyObject] {
                completionHandler(success: true, googlePlaceInfo: resultDetails, error: nil)
            } else {
                completionHandler(success: false, googlePlaceInfo: nil, error: "There was an error casting to array.")
            }
        }
        task.resume()
        
        //required in order to prevent memory leaks
        placeDetailsSession.finishTasksAndInvalidate()
    }
    
    ///creates a new core data entity from the place info returned by the "Place Details" API
    func createRestaurantFromPlaceInfo(placeInfo: [String: AnyObject], completionHandler: (restaurantObject: Restaurant?, error: String?) -> Void) {

        guard let placeID = placeInfo["place_id"] as? String else {
            completionHandler(restaurantObject: nil, error: "Error getting place ID")
            return
        }
        
        guard let geometry = placeInfo["geometry"] as? [String: AnyObject] else {
            completionHandler(restaurantObject: nil, error: "Error getting geometry")
            return
        }
        
        guard let location = geometry["location"] as? [String: Double] else {
            completionHandler(restaurantObject: nil, error: "Error getting location")
            return
        }
        
        guard let latitude = location["lat"], let longitude = location["lng"] else {
            completionHandler(restaurantObject: nil, error: "Error getting latitude/longitude")
            return
        }
        
        let title = placeInfo["name"] as? String
        let subtitle = placeInfo["vicinity"] as? String
        let url = placeInfo["url"] as? String

        let restaurant = Restaurant(placeID: placeID, title: title, subtitle: subtitle, latitude: latitude, longitude: longitude, url: url, iconPhoto: nil, context: CoreDataStack.sharedInstance.managedObjectContext)
        
        //is the results include a URL to an icon image, then go and download that image; otherwise, return the Restaurant entity with iconPhoto = nil (which will use a generic image for the icon)
        if let iconImageUrl = placeInfo["icon"] as? String {
            getIconImageForLocation(iconImageUrl, restaurant: restaurant, completionHandler: completionHandler)
        } else {
            completionHandler(restaurantObject: restaurant, error: nil)
        }
    }
    
    ///downloads the data associated with an image URL provided as part of the google "Place Details" response and saves it to the Restaurant object
    private func getIconImageForLocation(urlForIcon: String, restaurant: Restaurant, completionHandler: (restaurantObject: Restaurant?, error: String?) -> Void) {

        guard let imageNSURL = NSURL(string: urlForIcon) else {
            completionHandler(restaurantObject: nil, error: "Error converting to NSURL")
            return
        }
        
        let iconFetcSession = getConfiguredSession()
        let request = NSURLRequest(URL: imageNSURL)
        let task = iconFetcSession.dataTaskWithRequest(request) { (data, response, error) in

            guard error == nil else {
                completionHandler(restaurantObject: restaurant, error: error?.localizedDescription)
                return
            }

            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                completionHandler(restaurantObject: restaurant, error: "Unsuccessful status code")
                return
            }
            
            guard let imageData = data else {
                completionHandler(restaurantObject: restaurant, error: "There was an error getting icon image data.")
                return
            }
            
            restaurant.iconPhoto = imageData
            completionHandler(restaurantObject: restaurant, error: nil)
        }
        
        task.resume()
        
        //required in order to prevent memory leaks
        iconFetcSession.finishTasksAndInvalidate()
    }
    
    ///creates an NUSRL to be used in a request to google's "Place Autocomplete" API
    private func getGoogleURLForLocation(searchString: String, latitude: Double?, longitude: Double?) -> NSURL {
        var parameters: [String: String] = [Constants.GoogleMapsClientConstants.GoogleParameterKeys.APIKey: Constants.GoogleMapsClientConstants.GoogleParameterValues.APIKey,
                                            Constants.GoogleMapsClientConstants.GoogleParameterKeys.Types: Constants.GoogleMapsClientConstants.GoogleParameterValues.Types,
                                            Constants.GoogleMapsClientConstants.GoogleParameterKeys.Input: searchString]
        
        if let latitude = latitude, let longitude = longitude {
            parameters[Constants.GoogleMapsClientConstants.GoogleParameterKeys.Location] = "\(latitude),\(longitude)"
            parameters[Constants.GoogleMapsClientConstants.GoogleParameterKeys.Radius] = Constants.GoogleMapsClientConstants.GoogleParameterValues.Radius
        } else {
            parameters[Constants.GoogleMapsClientConstants.GoogleParameterKeys.Location] = Constants.GoogleMapsClientConstants.GoogleParameterValues.LocationNoLocationServices
            parameters[Constants.GoogleMapsClientConstants.GoogleParameterKeys.Radius] = Constants.GoogleMapsClientConstants.GoogleParameterValues.RadiusNoLocationServices
        }
        
        let NSURLFromComponents = NSURLComponents()
        NSURLFromComponents.scheme = Constants.GoogleMapsClientConstants.GoogleAPI.APIScheme
        NSURLFromComponents.host = Constants.GoogleMapsClientConstants.GoogleAPI.APIHost
        NSURLFromComponents.path = Constants.GoogleMapsClientConstants.GoogleAPI.APIAutoCompletePath
        
        var queryItems = [NSURLQueryItem]()
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: value)
            queryItems.append(queryItem)
        }
        
        NSURLFromComponents.queryItems = queryItems
        
        return NSURLFromComponents.URL!
    }
    
    ///creates an NSURL to be used in a request to google's "Place Details" API
    private func getGoogleURLForPlaceID(placeID: String) -> NSURL {
        let parameters: [String: String] = [Constants.GoogleMapsClientConstants.GoogleParameterKeys.APIKey: Constants.GoogleMapsClientConstants.GoogleParameterValues.APIKey,
                                            Constants.GoogleMapsClientConstants.GoogleParameterKeys.PlaceID: placeID]
        
        let NSURLFromComponents = NSURLComponents()
        NSURLFromComponents.scheme = Constants.GoogleMapsClientConstants.GoogleAPI.APIScheme
        NSURLFromComponents.host = Constants.GoogleMapsClientConstants.GoogleAPI.APIHost
        NSURLFromComponents.path = Constants.GoogleMapsClientConstants.GoogleAPI.APIPlaceDetailsPath
        
        var queryItems = [NSURLQueryItem]()
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: value)
            queryItems.append(queryItem)
        }
        
        NSURLFromComponents.queryItems = queryItems
        
        return NSURLFromComponents.URL!
    }
    
    ///method that returns a new session with a timeout configured; used as opposed to the shared session because it was necessary to have the ability to cancel/invalidate (which the shared session does not allow)
    private func getConfiguredSession() -> NSURLSession {
        let config = NSURLSessionConfiguration.defaultSessionConfiguration()
        config.timeoutIntervalForRequest = Constants.GoogleMapsClientConstants.TimeOutInterval
        return NSURLSession(configuration: config)
    }
    
    ///helper method that takes JSON NSData and returns an optional NSDictionary
    private class func parseData(dataToParse: NSData) -> NSDictionary? {
        let JSONData: AnyObject?
        do {
            JSONData = try NSJSONSerialization.JSONObjectWithData(dataToParse, options: .AllowFragments)
        } catch {
            return nil
        }
        guard let parsedData = JSONData as? NSDictionary else {
            return nil
        }
        return parsedData
    }
 
    private init() { }
}
