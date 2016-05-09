//
//  MapViewController.swift
//  My Menu
//
//  Created by Michael Miller on 4/6/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    //MARK: - OUTLETS
    @IBOutlet weak var mapView: MKMapView! {
        didSet {
            mapView.delegate = self
            
            //shows the user's location, if location services have already been authorized (if they haven't been authorized yet, this controller is NOT the controller that requests it)
            if CLLocationManager.authorizationStatus() == .AuthorizedWhenInUse {
                mapView.showsUserLocation = true
            }
        }
    }
    
    //MARK: - PROPERTIES
    //property that is used to determine whether or not to load the map's settings from the user defaults
    var initiallyLoaded = false
    
    //this property is set exclusively when the user tapping on "Show on Map" in the RestaurantViewController table
    var restaurantTappedOn: Restaurant?
    
    //MARK: - CUSTOM METHODS
    ///this method loads all the Restaurants from the persistent store and returns an array of all currently saved "Restaurant" objects (which were designed to conform to the MKAnnotation protocol)
    func loadAllPins() -> [Restaurant] {
        
        let fetchRequest = NSFetchRequest(entityName: "Restaurant")
        
        do {
            return try CoreDataStack.sharedInstance.managedObjectContext.executeFetchRequest(fetchRequest) as! [Restaurant]
        } catch {
            //if there is a problem for some reason, return an empty array (i.e. no pins will appear on map)
            return [Restaurant]()
        }
    }
    
    //MARK: - CONTROLLER LIFECYCLE
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Map"
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //if initiallyLoaded is false, load the previously saved map zoom/region from NSUserDefaults, then set initiallyLoaded to true (which remains true for the entirety of the user's session since the view controller is a tab and remains initialized, and prevents reloading each time)
        if !initiallyLoaded {
            if let savedRegion = NSUserDefaults.standardUserDefaults().objectForKey("savedMapRegion") as? [String: Double] {
                let center = CLLocationCoordinate2D(latitude: savedRegion["mapRegionCenterLat"]!, longitude: savedRegion["mapRegionCenterLon"]!)
                let span = MKCoordinateSpan(latitudeDelta: savedRegion["mapRegionSpanLatDelta"]!, longitudeDelta: savedRegion["mapRegionSpanLonDelta"]!)
                mapView.region = MKCoordinateRegion(center: center, span: span)
            }
            
            //prevents this block of code from running again during the session
            initiallyLoaded = true
        }
        
        //clear out all annotations each time and re-add them freshly, in the event that a place is removed
        mapView.removeAnnotations(mapView.annotations)
        
        //returns ALL places that are saved in the persistent store, including those that were manually entered (and should not appear on the map because their location was set to antarctica!)
        let loadedRestaurants = loadAllPins()
        
        //creates an empty array that will be used to store those places that SHOULD be shown (i.e. all places that weren't manually entered)
        var manualRestaurantsRemoved = [Restaurant]()
        
        //checks each Restaurant object (MKAnnotation conforming) to see if its latitude and longitude values match those in the "manually added" constants, and if doesn't, it gets appended to the array of places that WILL get added to the map
        for restaurant in loadedRestaurants {
            if restaurant.latitude != Constants.RestaurantViewConstants.ManualRestaurantLatitude && restaurant.longitude != Constants.RestaurantViewConstants.ManualRestaurantLongitude {
                manualRestaurantsRemoved.append(restaurant)
            }
        }
        
        //add and display the annotations that weren't manually entered
        mapView.addAnnotations(manualRestaurantsRemoved)
        
        //if the map tab is being shown as a result of the user tapping the "Show on Map" action in the action sheet, then restaurantTappedOn will not be nil and the condition below will be true, thus enabling the map to "select" that specific place which causes the callout to display; note that restaurantTappedOn is then immediately set to nil, so that if the user leaves the tab then comes back to it, the callout will no longer be showing
        if let restaurantToSelect = restaurantTappedOn {
            mapView.selectAnnotation(restaurantToSelect, animated: true)
            restaurantTappedOn = nil
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //saves the current map region to user defaults
        let regionToSave = [
            "mapRegionCenterLat": mapView.region.center.latitude,
            "mapRegionCenterLon": mapView.region.center.longitude,
            "mapRegionSpanLatDelta": mapView.region.span.latitudeDelta,
            "mapRegionSpanLonDelta": mapView.region.span.longitudeDelta
        ]
        NSUserDefaults.standardUserDefaults().setObject(regionToSave, forKey: "savedMapRegion")
    }
}

//MARK: - MAPVIEW DELEGATE METHODS
extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        //if the annotation for which a view is being returned is the user's location, then return nil, thus enabling this particular annotation to remain as a blue blinking beacon (without this check, the user's current location will also be shown as a red pin)
        if annotation.isKindOfClass(MKUserLocation) {
            return nil
        }
        
        var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier("location") as? MKPinAnnotationView
        if annotationView == nil {
            annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "location")
            annotationView?.canShowCallout = true
            annotationView?.pinTintColor = MKPinAnnotationView.redPinColor()
        } else {
            annotationView?.annotation = annotation
        }
        
        //enable the right callout accessory view as detail disclosure type IF there is at least one saved item associated with the particular place, which when tapped, brings up the list of items (via a filter) that are associated with that place; the use of the detail disclosure accessory (exclusively) also enables (for some weird reaon) the ENTIRE callout bubble to actively receive a user tap and activate the calloutAccessoryControlTapped method, in addition to the detail disclosure icon
        if (annotation as? Restaurant)?.menuItemCount > 0 {
            annotationView?.rightCalloutAccessoryView = UIButton(type: .DetailDisclosure)
        } else {
            annotationView?.rightCalloutAccessoryView = nil
        }
        
        //sets the left accessory view to the icon image stored for the place
        if let imageData = (annotation as? Restaurant)?.iconPhoto {
            
            let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 50, height: 50))
            imageView.contentMode = .ScaleAspectFit
            imageView.image = UIImage(data: imageData)
            
            annotationView?.leftCalloutAccessoryView = imageView
        } else {
            annotationView?.leftCalloutAccessoryView = nil
        }
        return annotationView
    }
    
    //if right accessory view becomes enabled (i.e. the place has at least one item associated with it), and it gets tapped, then this method gets invoked, which leads to the MenuItemViewController tab being selected and a restaurant filter used to display only those items associated with the selected place
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if let navController = self.tabBarController?.viewControllers?[1] as? UINavigationController {
            if let destinationController = navController.topViewController as? MenuItemViewController {
                destinationController.restaurantToUseForFilter = view.annotation as? Restaurant
                self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers?[1]
            }
        }
    }
    
    
}
