//
//  AddRestaurantViewController.swift
//  My Menu
//
//  Created by Michael Miller on 4/6/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import CoreLocation

class AddRestaurantViewController: UIViewController {
    
    //MARK: - OUTLETS
    @IBOutlet weak var tableView: UITableView! {
        didSet {
            tableView.delegate = self
            tableView.dataSource = self
        }
    }
    
    //MARK: - PROPERTIES
    //property to store whether user has granted access to location services; used to determine if the "Want Results Closer to You?" cell is shown
    var userGrantedLocationAccess = true
    
    //property to store whether to stop additional calls to google's Place Autocomplete API in the event user taps a result before subsequent calls have finishsed
    var stopSearchForSegue = false
    
    var searchBarController: UISearchController!

    var sharedClientInstance: GoogleMapsClient {
        return GoogleMapsClient.SharedInstance
    }
    
    //initialized lazily, since it is only used if the user has granted access to location services
    lazy var locationManager: CLLocationManager = {
       let lazyLocationManager = CLLocationManager()
        lazyLocationManager.delegate = self
        lazyLocationManager.desiredAccuracy = kCLLocationAccuracyBest
        return lazyLocationManager
    }()
    
    //array to store results from Place Autocomplete APIs; tuples used because it is necessary to capture both the placeID and the description for each (note to self: it is an ordered array (versus unordered dictionary) since the table is using it for its rows)
    var tempResultsForTable = [(placeID: String, description: String)]()
    
    //reference to selected cell row in google results; never set (stays nil) if user enters a manual place, and actively set to nil if user cancels
    var selectedIndexPath: NSIndexPath?
    
    //stores the place name in the event a user manually enters a place
    var manuallyEnteredRestaurant: String?
    
    //if user has enabled location services, this stores the user's current location and is used by the google API to show results closer to the user
    var userLocation: CLLocationCoordinate2D?
    
    //MARK: - CUSTOM METHODS
    //method that is called when view loads to determine if user has granted location access and take appropriate action
    func getLocation() {
        switch CLLocationManager.authorizationStatus() {
            
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
            
        //note to self: if location services have already been enabled, then the specilized "requestLocation()" method on the locationManager is invoked, which returns a single location of the user, calls the didUpdateLocations location manager delegate method with that single location, then disables location updates (this is opposed to using the locationManager.startUpdatingLocation method, which will continuously track a user's location, an unnecessary action for this app's purposes)
        case .AuthorizedWhenInUse:
            locationManager.requestLocation()
            
        //the case below is never actually accessed because this level of authorization is not requested; it is simply added here for switch completeness
        case .AuthorizedAlways:
            locationManager.requestLocation()
            
        //in the event none of the above are true, that means the user has responded "don't allow" to the prompt at an earlier time
        case .Denied:
            break
            
        default:
            break
        }
    }

    //method that determines whether the text field on the manual entry alert is empty or not, and disables/enables the "Save" button accordingly (thank you http://stackoverflow.com/questions/25628000/prevent-dismissal-of-uialertcontroller for the suggestion on how to do this!); method invoked when a user updates text in the manual entry text field
    func updateText(sender: AnyObject) {
        let textField = sender as! UITextField
        var responder: UIResponder? = textField
        while !(responder is UIAlertController) {
            responder = responder?.nextResponder()
        }
        if let alert = responder as? UIAlertController {
            alert.actions[0].enabled = (textField.text != "")
        }
    }
    
    //method that disables the searchbar and brings up an alert to allow manual entry of a place
    func showManualEntryScreen() {
        searchBarController.active = false
        
        let entryController = UIAlertController(title: "Enter Place Manually", message: "Enter name below to save a place manually.  NOTE: Manually entered places will not appear on the map or receive an address or Google URL.", preferredStyle: .Alert)
        entryController.addTextFieldWithConfigurationHandler { (textField) in
            textField.placeholder = "Enter place name"
            textField.addTarget(self, action: #selector(AddRestaurantViewController.updateText(_:)), forControlEvents: .EditingChanged)
        }
        entryController.addAction(UIAlertAction(title: "Save", style: .Default, handler: { (alert) in
        
            //saves the string entered as the restaurant name that will get passed back as part of the unwind segue
            let restaurantName = entryController.textFields?[0].text
            self.manuallyEnteredRestaurant = restaurantName
            
            //invokes the cancel method, which leads to the unwind
            self.cancel()
        }))
        entryController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        //disables the Save button initially; the button is enabled when the user enters something in the textfield, as determined by the updateText method
        entryController.actions[0].enabled = false
        presentViewController(entryController, animated: true, completion: nil)
    }
    
    //method attached to the top left "cancel" button (not the the cancel button that comes attached to the searchBarController)
    func cancel() {
        selectedIndexPath = nil
        performSegueWithIdentifier(Constants.AddRestaurantView.UnwindSegue, sender: nil)
    }

    //MARK: - CONTROLLER CLASS METHODS & LIFECYCLE
    //there are three "exits" from this view controller, and all lead to the unwind segue; if the user taps a google result (i.e. selectedIndexPath != nil), the tuple containing the placeID and place name associated with that row gets passed back to the RestaurantViewController and subsequently processed via the google Place Details API; if the user enters a result manually, a tuple containing a default placeID string ("MANUAL") along with the typed place name gets passed back; if a user cancels entirely, nil is passed back, which prevents anything from happening in the unwind segue action
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.AddRestaurantView.UnwindSegue {
            if let dvc = segue.destinationViewController as? RestaurantViewController {
                if let indexPath = selectedIndexPath {
                    dvc.googleResultToSave = tempResultsForTable[indexPath.row]
                } else if let restaurant = manuallyEnteredRestaurant {
                    dvc.googleResultToSave = (Constants.RestaurantViewConstants.ManualRestaurantPlaceID, restaurant)
                } else {
                    dvc.googleResultToSave = nil
                }
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //in case there are still calls to the google Place Autocomplete API being processed, this cancels those to prevent unnecessary API calls
        GoogleMapsClient.SharedInstance.cancelSearch()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //setup the search bar controller
        searchBarController = UISearchController(searchResultsController: nil)
        searchBarController.searchResultsUpdater = self
        searchBarController.searchBar.delegate = self
        searchBarController.obscuresBackgroundDuringPresentation = false
        searchBarController.dimsBackgroundDuringPresentation = false
        searchBarController.searchBar.placeholder = "Search with Google Maps"
        tableView.tableHeaderView = searchBarController.searchBar
    
        title = "Find a Place"
    
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(AddRestaurantViewController.cancel))
        
        navigationItem.leftBarButtonItem = cancelButton
        
        //if .Denied, then the tableview loads and shows an additional row at the end of the table providing guidance to user on how to get better results
        if CLLocationManager.authorizationStatus() == .Denied {
            self.userGrantedLocationAccess = false
        }
        
        getLocation()
    }
    
    //code below prevents what appears to be a bug that causes an error message ("Attempting to load the view of a view controller while it is deallocating is not allowed and may result in undefined behavior (<UISearchController:") that is printed to log when a user taps the cancel button in the top left (this dismissing the view controller) withOUT tapping in the search field at all (no error if the user taps the search field before cancelling); thank you stackoverflow for this one: http://stackoverflow.com/questions/32282401/attempting-to-load-the-view-of-a-view-controller-while-it-is-deallocating-uis
    deinit {
        searchBarController.view.removeFromSuperview()
    }
}

//MARK: - SEARCH BAR DELEGATE METHODS
extension AddRestaurantViewController: UISearchResultsUpdating, UISearchBarDelegate {
    
    func updateSearchResultsForSearchController(searchController: UISearchController) {
    
        guard !stopSearchForSegue else {
            return
        }
        
        guard let searchString = searchController.searchBar.text else {
            return
        }
        
        if searchString != "" {

            //if .Denied, enables the tableview loads and shows an additional row at the end of the table providing guidance to user on how to get better results
            if CLLocationManager.authorizationStatus() == .Denied {
                self.userGrantedLocationAccess = false
            }
            
            //starts the network activity indicator spinning
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true

            //performs the call to google's Place Autocomplete API using the entered string and location (if allowed by user) to get "predictions" to display on the table; this call typically occurs very quickly, as the API is intended to be used for quick calls in sequence; if userLocation == nil (i.e. user did not allow location services) or it the location has not yet been determined, then nil is passed for the latitude and longitude values, otherwise, the value is passed; method can handle either case; if location is determined while user is typing, then the next character entered in the string will use the more precise location (note to self: "self" added to capture list as WEAK, since it is possible that this view controller becomes nil (i.e. dismissed/cancelled out of) before certain pending API calls are completed; iniitally this was "unowned" but crashes were occurring when waiting for a response (i.e. in bad internet areas) and giving up and cancelling, only to have the call actually complete later)
            sharedClientInstance.searchForTextEnteredUsingGoogleAutoComplete(searchString, latitude: userLocation?.latitude, longitude: userLocation?.longitude, completionHandler: { [weak self] (success, googleResults, error) in
                dispatch_async(dispatch_get_main_queue()) {

                    //regardless of success or failure, any resonse disables the network activity indicator
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false

                    if let error = error {
                        
                        //note to self: the line below is required since searchbarcontroller is technically a view controller that is being presented to the user, and setting active to false essentially disables it and allows the for the alert view controller below to get called; without this line, the following error occurs when callAlert is called: "Warning: Attempt to present <UIAlertController: 0x7fb4a1dba9e0>  on <My_Menu.AddRestaurantViewController: 0x7fb4a1c2e100> which is already presenting (null)"
                        if let search = self?.searchBarController where search.active {
                            search.active = false
                        }
                        
                        //cancels any remaining searches in case of an error on the first one (thus invoking the alert only once)
                        GoogleMapsClient.SharedInstance.cancelSearch()
                        
                        //checking to make sure the "error" isn't from the user cancelling out of the screen entirely before the call finishes (if it is, no alert is shown); note that "cancelled" is the text string that is provided back from the dataTaskWithRequest if it is cancelled by user
                        if error != "cancelled" {
                            self?.callAlert("Error", message: error, alertHandler: nil, presentationCompletionHandler: nil)
                        }
                        
                        return
                    }
 
                    //clears out results array in preparation for new incoming array
                    self?.tempResultsForTable.removeAll()
                    
                    //fills up the array with up to 5 results from the google API
                    if let googleResults = googleResults {
                        for result in googleResults {
                            if let placeID = result["place_id"] as? String, let placeDescription = result["description"] as? String {
                                self?.tempResultsForTable.append((placeID, placeDescription))
                            }
                        }
                    }
                    
                    //reloads the table to show the fresh results
                    self?.tableView.reloadData()
                }
            })
        }
    }
    
    //when the cancel button provided by the searchbar is tapped, clears out the table
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        tempResultsForTable.removeAll()
        tableView.reloadData()
    }
}

//MARK: - TABLE DELEGATE & DATASOURCE METHODS
extension AddRestaurantViewController: UITableViewDelegate, UITableViewDataSource {
    
    //if location services have been enabled, add 1 row to display the "can't find what you're looking for?" manual entry row; if not, add 2 rows - the manual entry row followed by the "get results closer to you" row (which explains via an alert how to turn on locatin services)
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if userGrantedLocationAccess {
            return tempResultsForTable.count + 1
        } else {
            return tempResultsForTable.count + 2
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell
        
        //displays the google results for all rows except the last 1 or 2 (note to self: since the indexPath.row and tempResultsForTable.count values are off by 1, only add 1 for the +2 rows situation as determined above)
        if indexPath.row == tempResultsForTable.count + 1 {
            cell = tableView.dequeueReusableCellWithIdentifier(Constants.AddRestaurantView.ForBetterResultsCellIdentifier)!
        } else if indexPath.row == tempResultsForTable.count {
            cell = tableView.dequeueReusableCellWithIdentifier(Constants.AddRestaurantView.EnterManualCellIdentifier)!
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.AddRestaurantView.RestaurantSearchCellIdentifier) as! RestaurantSearchReturnCell
            cell.label.text = tempResultsForTable[indexPath.row].description
            return cell
        }
        
        return cell
    }
    
    //adjusts row height based on cell type
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch traitCollection.horizontalSizeClass {
        case .Compact:
            return Constants.AddRestaurantView.HeightForCellRowCompact
        case .Regular:
            return Constants.AddRestaurantView.HeightForCellRowRegular
        case .Unspecified:
            return Constants.AddRestaurantView.HeightForCellRowCompact
        }
    }
    
    //take appropriate action depending on which row is tapped
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.row == tempResultsForTable.count + 1 {
            self.searchBarController.active = false
            callAlert("Getting Better Results", message: "Turning on Location Services in Settings > Privacy for this app will enable the search to find results closer to you!", alertHandler: nil, presentationCompletionHandler: nil)
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        } else if indexPath.row == tempResultsForTable.count {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            showManualEntryScreen()
        } else {
            selectedIndexPath = indexPath
            
            //prevents "stray" calls to the searchForTextEnteredUsingGoogleAutoComplete method, which occur when the search bar is being cancelled out in preparation for the segue and which leads to updateSearchResultsForSearchController being called a couple of times
            stopSearchForSegue = true
            GoogleMapsClient.SharedInstance.cancelSearch()
            
            performSegueWithIdentifier(Constants.AddRestaurantView.UnwindSegue, sender: nil)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
}

//MARK: - LOCATION MANAGER DELEGATE METHODS
extension AddRestaurantViewController: CLLocationManagerDelegate {
    
    //called only after the very first time the user authenticates the app to use location services and is included to ensure that the location request gets made immediately after the user approves location services for the first time
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    //called in response to locationManager.requestLocation() and returns a single location data point in the locations array
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        //note to self: there will only be one element in the array in this case, since the locationManager.requestLocation() returns only one location before location services are stopped
        let currentLocation = locations[0]
        userLocation = currentLocation.coordinate
    }
    
    //note to self: required that both didUpdateLocations and the didFailWithError delegate methods are implemented; however, it is not essential for the purposes of this app that a user is notified that a location fix was unsuccessful, so this method remains as an empty implementation
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
    }
}
