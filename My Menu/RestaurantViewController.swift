//
//  ViewController.swift
//  My Menu
//
//  Created by Michael Miller on 4/6/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import CoreData
import SafariServices

class RestaurantViewController: UIViewController {

    //MARK: - OUTLETS
    @IBOutlet weak var restaurantTable: UITableView! {
        didSet {
            restaurantTable.delegate = self
            restaurantTable.dataSource = self
            restaurantTable.estimatedRowHeight = 65
            restaurantTable.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    //spinner that appears along with the blurview when restaurant data is being retrieved during the unwindFromAddRestaurantView method (which is called after user taps a desired location in the AddRestaurantViewController
    @IBOutlet weak var spinner: UIActivityIndicatorView! {
        didSet {
            spinner.hidesWhenStopped = true
        }
    }
    
    //MARK: - PROPERTIES
    var blurView = UIVisualEffectView()
    
    //property for storing the restaurants that are stored in the core data model; this array is used as data source for table, as well as for in-place sorting (initially, an NSFetchedResultsController was in use , but that was replaced with this array to make sorting easier)
    var fetchedArrayForSorting = [Restaurant]() {
        didSet {
            sortButton.enabled = fetchedArrayForSorting.count > 0
            deleteButton.enabled = fetchedArrayForSorting.count > 0
            if fetchedArrayForSorting.count == 0 {
                if editing {
                    toggleEditMode()
                }
            }
        }
    }
    
    //property that tracks if there are no places saved, and if not, enables the first row of the table to show a helper message
    var showGettingStarted = true
    
    //custom navigation bar buttons
    var sortButton: UIBarButtonItem!
    var deleteButton: UIBarButtonItem!
    var showInfoButton: UIBarButtonItem!
    
    //property that stores the new location that user taps when adding a new restaurant; stored via an unwind segue
    var googleResultToSave: (placeID: String, description: String)?
    
    //MARK: - CUSTOM METHODS
    ///method that adds (or removes) the blur effect over the table view along with turning the spinner on, for use when the data from the selected location is being downloaded from google; the blur effect is created by adding the blurView (which is a UIVisualEffectView) as a subview of the table view controller and adding an animated blur effect; passing "true" as the arguement enables the blurview and spinner, and passing "false" disables it (which simply removes the view from the mapview and stops the spinner, which hides itself when stopped)
    func displayBlurEffect(enable: Bool) {
        if enable {
        restaurantTable.addSubview(blurView)
            blurView.frame = view.bounds
            UIView.animateWithDuration(0.2) {
                self.blurView.effect = UIBlurEffect(style: .Light)
            }
            spinner.startAnimating()
        } else {
            blurView.removeFromSuperview()
            spinner.stopAnimating()
        }
    }
    
    ///method invoked when "+" is tapped which leads to the AddRestaurantViewController being presented modally; in this case, prepareForSegue doesn't so any additional configuration
    func addNewRestaurant() {
        
        if let permissionGranted = NSUserDefaults.standardUserDefaults().objectForKey("didAcceptTerms") as? Bool where permissionGranted {
            performSegueWithIdentifier(Constants.RestaurantViewConstants.AddRestaurantSegue, sender: nil)
        } else {
            performSegueWithIdentifier(Constants.RestaurantViewConstants.ShowPrivacyTermsSegue, sender: nil)  //note to self: in order to present modally with background transparency, the segue "presentation" setting is "Over Full Screen" (rather than Default) and the root view's background color was set to clear ("default")
        }
    }
    
    
    
    ///method that loads and returns all saved places from the persistent store; invoked each time the view appears, as well as when the data from google's Place Details API is returned and a new restaurant is created and added to the table
    func loadRestaurants() -> [Restaurant] {
        let fetchRequest = NSFetchRequest(entityName: "Restaurant")
        let sort = NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))  //replaced Selector("caseInsensitiveCompare:")
        fetchRequest.sortDescriptors = [sort]
        
        do {
            return try CoreDataStack.sharedInstance.managedObjectContext.executeFetchRequest(fetchRequest) as! [Restaurant]
        } catch {
            return []
        }
    }
    
    ///method invoked when the sort icon is tapped; presents an action sheet (on an iphone) with options for sorting the list of places, and as a popover extending from the sort button on an ipad
    func showSort() {
        
        //note to self: ActionSheet style selected because Alert style does not produce a popover presentation controller (it is nil) and subsequently appears modally, blurring the background; since a popover is the desired effect, ActionSheet is selected
        let sortSelector = UIAlertController(title: "SORT PLACES", message: "What would you like to sort by?", preferredStyle: .ActionSheet)
        
        sortSelector.addAction(UIAlertAction(title: "Place Name", style: .Default, handler: handleSortSelection))
        sortSelector.addAction(UIAlertAction(title: "Average Item Rating", style: .Default, handler: handleSortSelection))
        sortSelector.addAction(UIAlertAction(title: "Number of Saved Items", style: .Default, handler: handleSortSelection))
        sortSelector.addAction(UIAlertAction(title: "Combined Times Ordered", style: .Default, handler: handleSortSelection))
        sortSelector.addAction(UIAlertAction(title: "Most Recently Added", style: .Default, handler: handleSortSelection))
        sortSelector.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        sortSelector.modalPresentationStyle = .Popover
        let ppc = sortSelector.popoverPresentationController
        ppc?.barButtonItem = sortButton
        presentViewController(sortSelector, animated: true, completion: nil)
    }
    
    ///handler method that is invoked when a row in the sort places action sheet is tapped (the title of the row is used to distinguish which action sheet button was tapped)
    func handleSortSelection(alert: UIAlertAction) {
        
        guard let title = alert.title else {
            return
        }
        
        switch title {
            case "Place Name":
                //note to self: the localizedCompare compares strings in a non-case-sensitive way, which is desired (default .sort/.sortInPlace functions puts uppercase before lowercase; could alternatively have compared .lowercaseString versions of the titles)
                fetchedArrayForSorting.sortInPlace { return $0.title!.localizedCompare($1.title!) == .OrderedAscending }
            case "Average Item Rating":
                fetchedArrayForSorting.sortInPlace{ return $0.averageItemRating > $1.averageItemRating }
            case "Number of Saved Items":
                fetchedArrayForSorting.sortInPlace{ return $0.menuItemCount > $1.menuItemCount }
            case "Combined Times Ordered":
                fetchedArrayForSorting.sortInPlace{ return $0.totalItemsOrdered > $1.totalItemsOrdered }
            case "Most Recently Added":
                fetchedArrayForSorting.sortInPlace{ return $0.dateAdded.compare($1.dateAdded) == .OrderedDescending }
            default:
                break
        }
        restaurantTable.reloadData()
    }
    
    /// this method presents an "Info" view controller as a popoever (even on compact devices, by inmplementing the adaptivePresentationStyleForPresentationController) for presenting a short list of options to the user from a dropdown menu, incuding "About," "Terms of Service," and "Prvacy Policy"
    func showInfo() {
        if let infoViewController = storyboard?.instantiateViewControllerWithIdentifier("infoMenuViewController") as? InfoViewController {
            infoViewController.modalPresentationStyle = .Popover
            
            //delegate is set since the infoViewController will be sending info back to this view controller via the delegate method (tappedButton) below to let this view controller know which sof the three "info" storyboards to instantiate
            infoViewController.delegate = self
            
            if let popover = infoViewController.popoverPresentationController {
                
                //note to self: required in order to take advantage of the adaptivePresentationStyleForPresentationController, which is needed in order to force a popover on compact devices
                popover.delegate = self
                
                popover.barButtonItem = showInfoButton
                popover.backgroundColor = UIColor.whiteColor()
                
                //size is equal to the fixed-deminsion view that encapsualates the three "info" buttons
                infoViewController.preferredContentSize = CGSize(width: 132, height: 116)
                
                //creating and presenting the popover in code rather than using segues on the storyboard was used because the "presentViewController" function comes with a completion callback which was needed in order to set the passthroughViews property to nil, thus preventing the user form interacting with the "Albums" button on the toolbar while the popover was up (note that setting this property before presenting the popover did NOT disable the toolbar interactivity, and thus access to this closure was necessary); performing a segue did not provide a callback option
                presentViewController(infoViewController, animated: true, completion: { [unowned popover] () -> Void in
                    popover.passthroughViews = nil
                })
            }
        }
    }
    
    ///method that presents the options as an action sheet (popover on ipad) when a user taps a place in the table; which actions are available depends on how the place was added and how many items have been associated with the place so far; the tableview and indexpath are passed as arguments because they are needed to determine the anchor point (the table row) of the popover on an ipad
    func presentRestaurantActions(restaurant: Restaurant, tableView: UITableView, indexPath: NSIndexPath) {
        
        //alert action handlers are implemented as closures so that it is possible to capture the Restaurant object being passed in to the presentRestaurantActions method (rather than defining the handler to be function, since the only argument to the handler is allowed to be the UIAlertAction and cannot contain any other objects)
        let actionSheet = UIAlertController(title: restaurant.title, message: "What would you like to do?", preferredStyle: .ActionSheet)
        
        //an action that is always presented as an option; segues to the AddMenuItemViewController with the tapped restaurant pre-loaded in the "place" row additional configuration of the AddMenuItemViewController is performed in the prepareForSegue method (including passing the Restaurant object that was tapped, passed below to the prepareForSegue through the sender argument)
        actionSheet.addAction(UIAlertAction(title: "Add an Item", style: .Default, handler: { [unowned self] alert in
            self.performSegueWithIdentifier(Constants.RestaurantViewConstants.AddItemSegue, sender: restaurant)
        }))
        
        //an action that is only listed if there is at least one item saved for that place; if so, transitions to the second tab and applies a filter to the items so that only those associated with the tapped place are showing
        if restaurant.menuItems?.count > 0 {
            actionSheet.addAction(UIAlertAction(title: "Show Saved Items", style: .Default, handler: { [unowned self] alert in
                if let navController = self.tabBarController?.viewControllers?[1] as? UINavigationController {
                    if let destinationController = navController.topViewController as? MenuItemViewController {
                        destinationController.restaurantToUseForFilter = restaurant
                        self.tabBarController?.selectedViewController = self.tabBarController?.viewControllers?[1]
                    }
                }
            }))
        }
        
        //an action that is available when a place is added via the google Place Autocomplete search API (because latitude and longitude are returned and stored when the subsequent Place Details API call is made); manual entries of places are saved with a location in antarctica (unless there is a mcdonald's located there - which wouldn't be too surprising - this should be safe) and the first if-then statement below checks to see if a tapped place is at this location, and if so, doesn't present the action on the action sheet
        if restaurant.latitude != Constants.RestaurantViewConstants.ManualRestaurantLatitude && restaurant.longitude != Constants.RestaurantViewConstants.ManualRestaurantLongitude {
            actionSheet.addAction(UIAlertAction(title: "Show on Map", style: .Default, handler: { [unowned self] alert in
                if let destinationViewController = self.tabBarController?.viewControllers?[2] as? MapViewController {
                    destinationViewController.restaurantTappedOn = restaurant
                    self.tabBarController?.selectedViewController = destinationViewController
                }
            }))
        }
        
        //an action that is available when a place is added via the google Place Autocomplete search API (because a google page URL is returned and stored during the subsequent Place Details API call); manual places don't have one
        if let url = restaurant.url {
            actionSheet.addAction(UIAlertAction(title: "Open Google Page", style: .Default, handler: { [unowned self] alert in
                if let nsurl = NSURL(string: url) {
                    let safariViewContoller = SFSafariViewController(URL: nsurl)
                    self.presentViewController(safariViewContoller, animated: true, completion: nil)
                }
            }))
        }
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        //enables the popover on the ipad to extend from the row that was tapped (in order to avoid a crash, either the barbuttonitem property OR the sourceview + sourcerect need to be set);
        actionSheet.popoverPresentationController?.sourceView = tableView.cellForRowAtIndexPath(indexPath)
        actionSheet.popoverPresentationController?.sourceRect = (tableView.cellForRowAtIndexPath(indexPath) as! RestaurantTableViewCell).anchorPointForPopover.frame
        actionSheet.popoverPresentationController?.permittedArrowDirections = .Any
        
        presentViewController(actionSheet, animated: true, completion: nil)
    }

    //method that is called when the unwind segue is called in the AddRestaurantViewController, which either creates a manual Restaurant core data object (if a manual entry was made) or performs the google Place Details API call using the placeID and creating a Restaurant object from those results (note to self: in order to create the unwind segue programatically, it was necessary to FIRST implement the empty IBAction func with a segue argument, as done below, and THEN ctrl-drag from the yellow view controller icon to the the exit button in the storyboard (thus creating an unwind segue in the document outline); finally, give the unwind segue an identifer and call the "performSegueWithIdentifer" method when the cancel button is tapped in the AddRestaurantViewController, rather than dismissViewController)
    @IBAction func unwindFromAddRestaurantView(segue: UIStoryboardSegue) {
        
        if let resultToGetDetailsFor = googleResultToSave {
            
            //creates a manual Restaurant object
            if resultToGetDetailsFor.placeID == Constants.RestaurantViewConstants.ManualRestaurantPlaceID {
                
                let placeID = NSUUID().UUIDString
                let title = resultToGetDetailsFor.description
                let subtitle = Constants.RestaurantViewConstants.ManualRestaurantSubtitle
                let latitude = Constants.RestaurantViewConstants.ManualRestaurantLatitude
                let longitude = Constants.RestaurantViewConstants.ManualRestaurantLongitude
                let icon = UIImagePNGRepresentation(UIImage(named: "genericBusinessGoogle")!)
                
                let _ = Restaurant(placeID: placeID, title: title, subtitle: subtitle, latitude: latitude, longitude: longitude, url: nil, iconPhoto: icon, context: CoreDataStack.sharedInstance.managedObjectContext)
                
                do {
                    //saves the changes, reloads the array of places from the core data model, checks to see if the "row one with getting started tip" should show, then reloads
                    try CoreDataStack.sharedInstance.managedObjectContext.save()
                    
                    //see note next to viewWillAppear for comment on these two lines
                    let getArray = loadRestaurants()
                    fetchedArrayForSorting = getArray.map({$0})
                    
                    showGettingStarted = (fetchedArrayForSorting.count == 0)
                    restaurantTable.reloadData()
                } catch let error as NSError {
                    CoreDataStack.sharedInstance.managedObjectContext.undo()
                    callAlert("Error Saving", message: error.localizedDescription, alertHandler: nil, presentationCompletionHandler: nil)
                }
            } else {
                
                //else, start the spinner with blur effect and enable the network activity indicator...
                displayBlurEffect(true)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                
                //...and make the call to google's Place Details API with the placeID returned earlier; "self" added to capture list as unowned, since the view controller will never be nil
                GoogleMapsClient.SharedInstance.searchForSpecificPlace(resultToGetDetailsFor.placeID, completionHandler: { [unowned self] (success, googlePlaceInfo, error) in
                    
                    //disables network activity indicator
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = false

                    if success && error == nil {
                        
                        guard let placeInfo = googlePlaceInfo else {
                            dispatch_async(dispatch_get_main_queue()) {
                                self.displayBlurEffect(false)
                            }
                            return
                        }
                        
                        //enable network activity indicator for the next network-based call
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = true

                        //if google Place Details call was successful, then create a new Restaurant object, which involves a possible subsequent call to a URL to get the icon image
                        GoogleMapsClient.SharedInstance.createRestaurantFromPlaceInfo(placeInfo, completionHandler: { [unowned self] (restaurantObject, error) in
                            
                            dispatch_async(dispatch_get_main_queue()) {
                                
                                //regardless of success or failure, any resonse disables the network activity indicator
                                UIApplication.sharedApplication().networkActivityIndicatorVisible = false

                                self.displayBlurEffect(false)
                                
                                guard error == nil else {
                                    if CoreDataStack.sharedInstance.managedObjectContext.hasChanges {
                                        CoreDataStack.sharedInstance.managedObjectContext.undo()
                                    }
                                    self.callAlert("Error", message: error!, alertHandler: nil, presentationCompletionHandler: nil)
                                    return
                                }
                                
                                if let _ = restaurantObject {
                                    if CoreDataStack.sharedInstance.managedObjectContext.hasChanges {
                                        do {
                                            try CoreDataStack.sharedInstance.managedObjectContext.save()
                                            
                                            //see note next to viewWillAppear for comment on these two lines
                                            let getArray = self.loadRestaurants()
                                            self.fetchedArrayForSorting = getArray.map({$0})
                                            
                                            self.showGettingStarted = (self.fetchedArrayForSorting.count == 0)
                                            self.restaurantTable.reloadData()
                                        } catch let error as NSError {
                                            CoreDataStack.sharedInstance.managedObjectContext.undo()
                                            
                                            //checks to see if the error resulted from a duplicate entry (i.e. identical placeID) and lets user know
                                            if error.code == Constants.RestaurantViewConstants.DuplicateEntrySaveErrorCode {
                                                self.callAlert("Duplicate Entry", message: "You already saved that place!", alertHandler: nil, presentationCompletionHandler: nil)
                                            } else {
                                                self.callAlert("Error Saving", message: error.localizedDescription, alertHandler: nil, presentationCompletionHandler: nil)
                                            }
                                        }
                                    }
                                }
                            }
                        })
                    } else {
                        dispatch_async(dispatch_get_main_queue()) {
                            self.displayBlurEffect(false)
                            self.callAlert("Error", message: error!, alertHandler: nil, presentationCompletionHandler: nil)
                        }
                    }
                })
            }
        }
    }
    
    ///method invoked by tapping the delete button; this method, along with the overridden setEditing, serves as a graphical replacement of the standard edit-done button
    func toggleEditMode() {
        setEditing(!editing, animated: true)
    }
    
    //MARK: - CONTROLLER CLASS METHODS & LIFECYCLE
    //toggles editing mode on the table based on the editing mode of the view controller, and updates the delete/OK button image to reflect the state
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        restaurantTable.setEditing(editing, animated: true)
        if editing {
            deleteButton.image = UIImage(named: "done")
        } else {
            deleteButton.image = UIImage(named: "delete")
        }
    }
    //this method only performs additional configuration of the destination view controller if the "AddItemFromRestaurantList" segue is occurring from the "Add an Item" action button to the AddMenuItemViewController, in which case, pre-configuration of the AddMenuItemViewController is necessary; if invoked from the user tapping the "+" button (leading to a segue with identifer of "AddRestaurant"), the destination view controller is an AddRestaurantViewController, which requires no additional setup
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == Constants.RestaurantViewConstants.AddItemSegue {
            let restaurant = sender as? Restaurant
            
            if let navController = segue.destinationViewController as? UINavigationController {
                if let destinationController = navController.topViewController as? AddMenuItemViewController {
                    destinationController.restaurantTapped = restaurant //couldn't set the restaurantOfItem property because setting it caused its property observer to invoke an update to outlets, which havent been set yet and thus cause a crash, when the AddMenuItemViewController is segued to from this view controller; as an alternative, created and used a new restaurantTapped property to be set and used exclusively when segueing from this view controller
                    destinationController.actionToAssignToButton = #selector(destinationController.save)
                    destinationController.titleToShow = "Add Item"
                }
            }
        } else if segue.identifier == Constants.RestaurantViewConstants.ShowPrivacyTermsSegue {
            if let dvc = segue.destinationViewController as? PrivacyViewController {
                dvc.delegate = self
            }
        }
    }
    
    //each time the view appears, a fresh fetch is made, thus resetting any sorts and re-enabling the "row 1 with getting started tip" in the event the user has deleted all places
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        //these two lines make up an update made during final testing to address a slight memory leak being caused by what appears to be a weird bridging issue between NSArray and Array during core data fetch execution (as per this stackoverflow post: http://stackoverflow.com/questions/33574867/memory-leak-in-core-data-fetch-request-with-swift; these two lines take the place of: fetchedArrayForSorting = loadRestaurants()
        let getArray = loadRestaurants()
        fetchedArrayForSorting = getArray.map({$0})
        
        showGettingStarted = (fetchedArrayForSorting.count == 0)
        restaurantTable.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
                
        let spacer = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)

        sortButton = UIBarButtonItem(image: UIImage(named: "sort"), style: .Plain, target: self, action: #selector(RestaurantViewController.showSort))
        deleteButton = UIBarButtonItem(image: UIImage(named: "delete"), style: .Plain, target: self, action: #selector(RestaurantViewController.toggleEditMode))
        
        //creating info button to be used in the navigation toolbar (http://stackoverflow.com/questions/1308122/how-can-i-put-an-info-button-on-the-iphone-nav-bar)
        let infoButton = UIButton(type: .DetailDisclosure)
        infoButton.addTarget(self, action: #selector(RestaurantViewController.showInfo), forControlEvents: .TouchUpInside)
        showInfoButton = UIBarButtonItem(customView: infoButton)
        
        let addButton = UIButton(type: .ContactAdd)
        addButton.addTarget(self, action: #selector(RestaurantViewController.addNewRestaurant), forControlEvents: .TouchUpInside)
        let addNewRestaurantButton = UIBarButtonItem(customView: addButton)
        
        navigationItem.rightBarButtonItems = [addNewRestaurantButton, spacer, showInfoButton, spacer]
        navigationItem.leftBarButtonItems = [deleteButton, spacer, sortButton, spacer]
        
        //note to self: the typical .title property sets BOTH navigation AND tabbar names, which isn't desired
        navigationItem.title = "Where I Went"
        tabBarItem.title = "Places"
        
    }
}

//MARK: - CUSTOM PROTOCOL DELEGATE METHODS
extension RestaurantViewController: PrivacyUpdateDelegate {
    
    ///method implemented per the PrivacyUpdateDelegate protocol defined on the PrivacyViewController class; when user taps the "continue" button, the privacy view dismisses and this delegate protocol is called within the completion handler of the privacy view's dismissal (thus enabling the AddRestaurantViewController to be immeditely and automatically presented without issue); the fact that the user has checked the box (which is guaranteed because the continue button only becomes enabled when box is checked) is saved to NSUserDefaults and checked for next time the + button is added (thus allowing for the bypass of this screen)
    func updatePrivacy() {
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "didAcceptTerms")
        addNewRestaurant()
    }
}

extension RestaurantViewController: InfoViewDelegate {
    
    ///method implemented per the defined InfoViewDelegate protocol defined on the InfoViewController class; this method receives a string that identifies which of the three "info" storyboards to instantiate based on which button in the popover was tapped (either the "aboutView" view, the "termsView" view, or the "privacyView" view)
    func tapButton(storyboardIndentiferToInstantiate: String) {
        if let infoView = storyboard?.instantiateViewControllerWithIdentifier(storyboardIndentiferToInstantiate) {
            presentViewController(infoView, animated: true, completion: nil)
        }
    }
}

//MARK: - POPOVER PRESENTATION CONTROLLER DELEGATE METHODS

extension RestaurantViewController: UIPopoverPresentationControllerDelegate {
    
    //delegte method used to override the iphone's automatic adapting of a popover into a modal view controller (this was needed in order to maintain the popover bubble on an iphone)
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
}

//MARK: - TABLE DELEGATE & DATASOURCE METHODS
extension RestaurantViewController: UITableViewDelegate, UITableViewDataSource {
    
    //method that is called during the cellForRowAtIndexPath to set up the cell
    private func configureRatingImages(cell: RestaurantTableViewCell, restaurant: Restaurant) {
        
        //initially set all images to nil, so reused cells don't have lingering images
        cell.image5.image = nil
        cell.image4.image = nil
        cell.image3.image = nil
        cell.image2.image = nil
        cell.image1.image = nil
        
        //local variable used to store the images in order, left to right, so as to "fill them up" appropriately
        let images = [cell.image1, cell.image2, cell.image3, cell.image4, cell.image5]
        
        //calculates the average rating of all items associated with the specific place
        var average = 0.0
        var itemCount = 0
        if let menuItems = restaurant.menuItems {
            itemCount = menuItems.count
            var sum = 0
            for item in menuItems {
                sum += Int(item.myRating)
            }
            if itemCount > 0 {
                average = Double(sum) / Double(itemCount)
            }
        }
        
        //sets this property on the restaurant, but this is not an NSManaged/persisted property; stored during the session so that it can be sorted on
        restaurant.averageItemRating = average
        
        //calculates which fraction of a partial smiley icon to show based on the decimal part of the average rating; the icons cover ranges of decimal values, so they are approximate
        let intPart = floor(average)
        let decimalPart = average - intPart
        
        //function used to reduce redundant code; called below when comparing the intPart
        func switchStatement() {
            switch decimalPart {
            case 0:
                images[Int(intPart)].image = nil
            case _ where decimalPart < 0.125:
                images[Int(intPart)].image = UIImage(named: "smileyhappygreen12")
            case _ where decimalPart < 0.375:
                images[Int(intPart)].image = UIImage(named: "smileyhappygreen25")
            case _ where decimalPart < 0.625:
                images[Int(intPart)].image = UIImage(named: "smileyhappygreen50")
            case _ where decimalPart < 0.875:
                images[Int(intPart)].image = UIImage(named: "smileyhappygreen75")
            case _ where decimalPart < 1.0:
                images[Int(intPart)].image = UIImage(named: "smileyhappygreen")
            default:
                images[Int(intPart)].image = nil
            }
        }
        
        //updates the text in the gray section based on how many items are saved and the total counts for those items
        switch itemCount {
        case 0:
            cell.items.text = "No items saved for this place."
        case 1:
            if restaurant.totalItemsOrdered == 1 {
                cell.items.text = "\(itemCount) item saved, which has been ordered \(restaurant.totalItemsOrdered) time."
            } else {
                cell.items.text = "\(itemCount) item saved, which has been ordered \(restaurant.totalItemsOrdered) times."
            }
        default:
            cell.items.text = "\(itemCount) items saved, ordered a combined total of \(restaurant.totalItemsOrdered) times."
        }
        
        guard intPart <= 5 else {
            return
        }
        
        //if there are no items, average rating set below 0 so when the list is sorted by average rating, those with no rating are at the bottom (below those with 0 rating)
        guard itemCount > 0 else {
            restaurant.averageItemRating = -1.0
            return
        }
        
        //determines how many full smiley icons to show based on the integer part of the average rating; for positive averages, full smileys fill up left to right, with the right most smily being the partial smily (if applicable)
        if intPart > 0 {
            for number in 1...Int(intPart) {
                images[number - 1].image = UIImage(named: "smileyhappygreen")
            }
            if intPart < 5 {
                switchStatement()
            }
        } else {
            if decimalPart == 0 {
                images[0].image = UIImage(named: "smileysadred")
            } else {
                switchStatement()
            }
        }
    }
    
    //if there are no places saved (i.e. showGettingStarted == true), return 1 row so that the "row 1 with helper tip" can be displayed
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if showGettingStarted {
            return 1
        } else {
            return fetchedArrayForSorting.count
        }
    }
    
    //if there are no places saved, return an instance of the "row 1 with helper tip" cell, otherwise, return an instance of the RestaurantTableViewCell, fully configured
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
     
        if showGettingStarted {
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.RestaurantViewConstants.AddFirstRestaurantCellIdentifier)!
            return cell
        }
 
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.RestaurantViewConstants.RestaurantCellIdentifier) as! RestaurantTableViewCell
        let restaurant = fetchedArrayForSorting[indexPath.row]
        
        cell.name.text = restaurant.title
        cell.location.text = restaurant.subtitle
        
        configureRatingImages(cell, restaurant: restaurant)
        
        //sets icon image to the iconPhoto saved in the persistent store
        if let data = restaurant.iconPhoto {
            cell.iconImage.image = UIImage(data: data)
        } else {
            cell.iconImage.image = nil
        }
        
        return cell
    }
    
    //if showGettingStarted == true (i.e. there are no places saved), then nothing happens when user taps the row, otherwise, the action sheet is presented with various actions to take for the selected place
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if showGettingStarted {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        } else {
            let selectedRestaurant = fetchedArrayForSorting[indexPath.row]
            presentRestaurantActions(selectedRestaurant, tableView: tableView, indexPath: indexPath)
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }

    //disable deleting in the event that showGettingStarted == true (i.e. the "row 1 with helper tip" is showing)
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
       return !showGettingStarted
    }
    
    //if deleting a place will cascade delete items (menuItems > 0 for that place), a confirmation alert is displayed; otherwise, the deletion occurs and update saved to core data
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let restaurant = fetchedArrayForSorting[indexPath.row]
            
            if restaurant.menuItems?.count > 0 {
                let alert = UIAlertController(title: "Confirm Delete", message: "Removing this place will ALSO delete \(restaurant.menuItemCount) saved items. Are you sure you wish to delete?", preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Delete", style: .Destructive, handler: { [unowned self] (alert) in
                    CoreDataStack.sharedInstance.managedObjectContext.deleteObject(restaurant)
                    
                    if CoreDataStack.sharedInstance.managedObjectContext.hasChanges {
                        do {
                            try CoreDataStack.sharedInstance.managedObjectContext.save()
                            self.fetchedArrayForSorting.removeAtIndex(indexPath.row)
                            self.restaurantTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                        } catch { }
                    }
                }))
                
                // note to self: .Default style selected because by default, .Cancel style buttons are always listed on the left; .Default allowed to place destructive button on the left, per iOS human interface guidelines
                alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
                presentViewController(alert, animated: true, completion: nil)
            } else {
                CoreDataStack.sharedInstance.managedObjectContext.deleteObject(restaurant)
                
                if CoreDataStack.sharedInstance.managedObjectContext.hasChanges {
                    do {
                        try CoreDataStack.sharedInstance.managedObjectContext.save()
                        fetchedArrayForSorting.removeAtIndex(indexPath.row)
                        restaurantTable.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                    } catch { }
                }
            }
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
}

