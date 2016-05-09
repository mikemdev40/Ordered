//
//  Constants.swift
//  Virtual Tourist
//
//  Created by Michael Miller on 3/28/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import Foundation
import MapKit

struct Constants {
    
    struct RestaurantViewConstants {
        static let AddRestaurantSegue = "AddRestaurant"
        static let AddItemSegue = "AddItemFromRestaurantList"
        static let ManualRestaurantPlaceID = "MANUAL"
        static let ManualRestaurantSubtitle = "Manual entry"
        static let ShowPrivacyTermsSegue = "ShowPrivacyTerms"
        
        //these seemingly random latitude and longitude values are in antarctica and are used as "placeholder" values for restaurants that are added manually (since the Restaurant class conforms to MKAnnotation and requires lat/lon values); Restaurants with these exact latitude/longitude values are not added to the map
        static let ManualRestaurantLatitude = Double(-84.1)
        static let ManualRestaurantLongitude = Double(40.5)
        
        //core data error code for duplicate entry (as enforced by the core data model constraint "placeID")
        static let DuplicateEntrySaveErrorCode = 133021
        
        static let RestaurantCellIdentifier = "RestaurantCell"
        static let AddFirstRestaurantCellIdentifier = "AddFirstRestaurantCell"
    }
    
    struct AddRestaurantView {
        static let UnwindSegue = "UnwindSegueFromAddView"
        static let RestaurantSearchCellIdentifier = "RestaurantSearchReturn"
        static let EnterManualCellIdentifier = "EnterManual"
        static let ForBetterResultsCellIdentifier = "ForBetterResults"
        static let HeightForCellRowCompact: CGFloat = 44
        static let HeightForCellRowRegular: CGFloat = 54
    }
    
    struct MenuItemConstants {
        static let AddMenuItemSegue = "AddMenuItem"
        static let ShowEditItemSegue = "ShowEditMenuItem"
        static let MenuItemCellIdentifier = "MenuItemCell"
        static let ShowAllItemsCellIdentifier = "ShowAllItemsCell"
        static let AddFirstItemCell = "GettingStartedCell"
    }
    
    struct AddMenuItemConstants {
        static let DefaultNotesMessage = "Tap to add/edit notes..."
        static let ShowRestaurantSelectorSegue = "ShowRestaurantSelector"
    }
    
    struct RestaurantSelectorConstants {
        static let RestaurantSelectorCellIdentifier = "RestaurantSelectorCell"
    }
    
    struct GoogleMapsClientConstants {  //see https://developers.google.com/places/web-service/autocomplete#place_autocomplete_requests
        
        static let TimeOutInterval: Double = 15
        
        struct GoogleAPI {
            static let APIScheme = "https"
            static let APIHost = "maps.googleapis.com"
            
            //per the Google Maps API, /RESULT TYPE (either JSON or XML) goes on the end of the URL, and since we want json results, /json is part of the path
            static let APIAutoCompletePath = "/maps/api/place/autocomplete/json"
            
            //per the Google Maps API, /RESULT TYPE (either JSON or XML) goes on the end of the URL, and since we want json results, /json is part of the path
            static let APIPlaceDetailsPath = "/maps/api/place/details/json"
        }
        
        // Google Parameter Keys
        struct GoogleParameterKeys {
            //keys with pre-defined constant values
            static let APIKey = "key"
            static let Radius = "radius" //does not fully restrict results to within this radius, but rather biases results to PREFER results within the given radius; see Google API docs for info
            static let Types = "types"
            
            //keys that have values which are defined during app run
            static let Input = "input"  //required parameter, based on search string
            static let Location = "location"  //optional parameter, for if the location around where to search is known (i.e. location services are enabled and it is known where the use is); value for this key needs to be: LATITUDE,LONGITUDE (no space after comma)
            static let PlaceID = "placeid"
        }
        
        // Google Parameter Values
        struct GoogleParameterValues {
            static let APIKey = ""  //ENTER YOURS HERE (note that it is necessary to actually create a SERVER key, not an API key; see http://stackoverflow.com/questions/21933247/this-ip-site-or-mobile-application-is-not-authorized-to-use-this-api-key)
            
            static let Radius = "50"
            static let RadiusNoLocationServices = "20000000"
            static let LocationNoLocationServices = "0,0"
            static let Types = "establishment" //returns only businesses
        }
    }
}