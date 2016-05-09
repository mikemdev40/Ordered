//
//  MenuItemViewController.swift
//  My Menu
//
//  Created by Michael Miller on 4/6/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import CoreData

class MenuItemViewController: UIViewController {

    //MARK: - OUTLETS
    @IBOutlet weak var menuItemTableView: UITableView! {
        didSet {
            menuItemTableView.delegate = self
            menuItemTableView.dataSource = self
            menuItemTableView.estimatedRowHeight = 40
            menuItemTableView.rowHeight = UITableViewAutomaticDimension
        }
    }
    
    //MARK: - PROPERTIES
    //property for storing the items that are stored in the core data model; this array is used as data source for table, as well as for in-place sorting
    var fetchedArrayForSorting = [MenuItem]() {
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
    
    //property that tracks if there are no items saved, and if not, enables the first row of the table to show a helper message
    var showGettingStarted = true
    
    //passed value from RestaurantViewController via the segue when user taps "Show Saved Items"; this leads to the application of a filter on the fetch request to the data model
    var restaurantToUseForFilter: Restaurant?
    
    //custom navigation bar buttons
    var sortButton: UIBarButtonItem!
    var deleteButton: UIBarButtonItem!
    
    //computed property which, when false, prevents the addition of a new item via the "+" button; checks the core data model to ensure there is at least one Restaurant object saved (as an item can only be created when associated with a Restaurant object)
    var atLeastOneResaurant: Bool {
        let fetch = NSFetchRequest(entityName: "Restaurant")
        
        do {
            let results = try CoreDataStack.sharedInstance.managedObjectContext.executeFetchRequest(fetch) as! [Restaurant]
            return (results.count > 0)
        } catch {
            return false
        }
    }
    
    //MARK: - CUSTOM METHODS
    ///method that loads and returns all saved items from the persistent store; invoked each time the view appears (as well as when the user taps the "Tap here to show all saved items" row which results from a filter being applied)
    func loadMenuItems() -> [MenuItem] {
        let fetchRequest = NSFetchRequest(entityName: "MenuItem")
        let sort = NSSortDescriptor(key: "title", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))  //replaced Selector("caseInsensitiveCompare:")
        fetchRequest.sortDescriptors = [sort]
        
        //adds a filter via a predicate in the event the user tapped "Show Saved Items" for a specific place (having a filter also enables the "Tap here to show all saved items" to be shown in the table)
        if let restaurantFilter = restaurantToUseForFilter {
            fetchRequest.predicate = NSPredicate(format: "restaurant == %@", restaurantFilter)
        } else {
            fetchRequest.predicate = nil
        }
        
        do {
            return try CoreDataStack.sharedInstance.managedObjectContext.executeFetchRequest(fetchRequest) as! [MenuItem]
        } catch {
            return []
        }
    }
    
    ///method invoked when + is tapped which leads to the AddMenuItemViewController being presented modally; in the event no places are saved (i.e. atLeastOneRestaurant == false), an alert is show instead telling the user that they must first add a place before adding an item
    func addNewMenuItem() {
        if atLeastOneResaurant {
            performSegueWithIdentifier(Constants.MenuItemConstants.AddMenuItemSegue, sender: nil)
        } else {
            callAlert("No Places", message: "Must have at least one place added in order to add an item. Start by first adding the place for which you want to add an item!", alertHandler: nil, presentationCompletionHandler: nil)
        }
    }
    
    ///method that leads to the identical AddMenuItemViewController, but via a differently-named segue (so as to differentiate them using their identifiers in prepareForSegue); in this case, because we want to load a certain item to edit/update, the tapped item is passed in the sender argument
    func showEditMenuItem(menuItemToEdit: MenuItem) {
        performSegueWithIdentifier(Constants.MenuItemConstants.ShowEditItemSegue, sender: menuItemToEdit)
    }
    
    ///method invoked when the sort icon is tapped; presents an action sheet (on an iphone) with options for sorting the list of items, and as a popover extending from the sort button on an ipad
    func showSort() {
        
        //ActionSheet style selected because Alert style does not produce a popover presentation controller (it is nil) and subsequently appears modally, blurring the background; since a popover is the desired effect, ActionSheet is selected
        let sortSelector = UIAlertController(title: "SORT ITEMS", message: "What would you like to sort by?", preferredStyle: .ActionSheet)
        
        sortSelector.addAction(UIAlertAction(title: "Item Name", style: .Default, handler: handleSortSelection))
        sortSelector.addAction(UIAlertAction(title: "Item Rating", style: .Default, handler: handleSortSelection))
        sortSelector.addAction(UIAlertAction(title: "Number of Times Ordered", style: .Default, handler: handleSortSelection))
        sortSelector.addAction(UIAlertAction(title: "Place Name", style: .Default, handler: handleSortSelection))
        sortSelector.addAction(UIAlertAction(title: "Most Recently Added", style: .Default, handler: handleSortSelection))
        sortSelector.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        sortSelector.modalPresentationStyle = .Popover
        let ppc = sortSelector.popoverPresentationController
        ppc?.barButtonItem = sortButton
        presentViewController(sortSelector, animated: true, completion: nil)
    }
    
    ///handler method that is invoked when a row in the sort items action sheet is tapped (the title of the row is used to distinguish which action sheet button was tapped)
    func handleSortSelection(alert: UIAlertAction) {
        
        guard let title = alert.title else {
            return
        }
        
        switch title {
        case "Item Name":
            fetchedArrayForSorting.sortInPlace { return $0.title.localizedCompare($1.title) == .OrderedAscending }
        case "Item Rating":
            fetchedArrayForSorting.sortInPlace{ return $0.myRating > $1.myRating }
        case "Number of Times Ordered":
            fetchedArrayForSorting.sortInPlace{ return $0.timesOrdered > $1.timesOrdered }
        case "Place Name":
            fetchedArrayForSorting.sortInPlace{ (string1, string2) in
                if let title1 = string1.restaurant.title, let title2 = string2.restaurant.title {
                    return title1.localizedCompare(title2) == .OrderedAscending
                } else {
                    return true
                }
            }
        case "Most Recently Added":
            fetchedArrayForSorting.sortInPlace{ return $0.dateAdded.compare($1.dateAdded) == .OrderedDescending }
        default:
            break
        }
        menuItemTableView.reloadData()
    }
    
    ///method invoked by tapping the delete button; this method, along with the overridden setEditing, serves as a graphical replacement of the standard edit-done button
    func toggleEditMode() {
        setEditing(!editing, animated: true)
    }

    //MARK: - CONTROLLER CLASS METHODS & LIFECYCLE
    //toggles editing mode on the table based on the editing mode of the view controller, and updates the delete/OK button image to reflect the state
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: true)
        menuItemTableView.setEditing(editing, animated: true)
        if editing {
            deleteButton.image = UIImage(named: "done")
        } else {
            deleteButton.image = UIImage(named: "delete")
        }
    }
    
    //depending on if a user tapped an item (i.e. to open/update it) or tapped the "+" button (i.e. to add a new one), the appropriate segue is called, and depending on which segue is called, the destination view controller (AddMenuItemViewController) is either provided with an item to load and a title of "Update Item", or starts as a blank slate with a title of "Add Item"; additionally, the selector method that should be attached to the "Save" button in the destination view controller is also set
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let dvc = (segue.destinationViewController as? UINavigationController)?.topViewController as? AddMenuItemViewController
        
        if let dvc = dvc {
            if segue.identifier == Constants.MenuItemConstants.ShowEditItemSegue {
                dvc.actionToAssignToButton = #selector(dvc.update)
                dvc.menuItemToEdit = sender as? MenuItem
                dvc.titleToShow = "Update Item"
            } else if segue.identifier == Constants.MenuItemConstants.AddMenuItemSegue {
                dvc.actionToAssignToButton = #selector(dvc.save)
                dvc.titleToShow = "Add Item"
            }
        }
    }
    
    //each time the view appears, a fresh fetch is made, thus resetting any sorts and re-enabling the "row 1 with getting started tip" in the event the user has deleted all places; since the restaurantToUseForFilter property is set to nil as the view controller disappears, any filter will also be removed upon returning (unless the user returns by tapping a place)
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        //these two lines make up an update made during final testing to address a slight memory leak being caused by what appears to be a weird bridging issue between NSArray and Array during core data fetch execution (as per this stackoverflow post: http://stackoverflow.com/questions/33574867/memory-leak-in-core-data-fetch-request-with-swift; these two lines take the place of: fetchedArrayForSorting = loadMenuItems()
        let getArray = loadMenuItems()
        fetchedArrayForSorting = getArray.map({$0})
        
        showGettingStarted = (fetchedArrayForSorting.count == 0)
        menuItemTableView.reloadData()
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        //removes the filter
        restaurantToUseForFilter = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let spacer = UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil)

        sortButton = UIBarButtonItem(image: UIImage(named: "sort"), style: .Plain, target: self, action: #selector(MenuItemViewController.showSort))
        deleteButton = UIBarButtonItem(image: UIImage(named: "delete"), style: .Plain, target: self, action: #selector(RestaurantViewController.toggleEditMode))
        
        let addButton = UIButton(type: .ContactAdd)
        addButton.addTarget(self, action: #selector(MenuItemViewController.addNewMenuItem), forControlEvents: .TouchUpInside)
        let addMenuItemButton = UIBarButtonItem(customView: addButton)
        
        navigationItem.rightBarButtonItems = [addMenuItemButton, spacer]
        navigationItem.leftBarButtonItems = [deleteButton, spacer, sortButton, spacer]
        
        //note to self: the typical .title property sets BOTH navigation AND tabbar names, which isn't desired
        navigationItem.title = "What I Ordered"
        tabBarItem.title = "Items"
    }
}

//MARK: - TABLE DELEGATE & DATASOURCE METHODS
extension MenuItemViewController: UITableViewDelegate, UITableViewDataSource {
    
    //if there are no item saved (i.e. showGettingStarted == true), return 1 row so that the "row 1 with helper tip" can be displayed; if there is a filter applied (i.e. the user tapped "Show Saved Items"), then 1 is added to the fetched array count, so as to show the "tap here to show all results" (remove filter) row on the row below the items for that place
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let _ = restaurantToUseForFilter {
            return fetchedArrayForSorting.count + 1
        } else if showGettingStarted {
            return 1
        } else {
            return fetchedArrayForSorting.count
        }
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        //if showGettingStarted == true (i.e. no items saved), return a "row 1 with helper tip" cell
        if showGettingStarted {
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.MenuItemConstants.AddFirstItemCell)!
            return cell
        }
        
        //this checks to see if the row being configured exactly matches the length of the fetchedArrayForSorting, and if so, then that means there must be a filter applied and an additional row has been added as part of numberOfRowsInSection and the "tap here to show all results" cell is displayed at the bottom (with no filter applied, the final indexPath.row is one LESS than the count, and this condition will never be true)
        if indexPath.row == fetchedArrayForSorting.count {
            let cell = tableView.dequeueReusableCellWithIdentifier(Constants.MenuItemConstants.ShowAllItemsCellIdentifier)!
            return cell
        }
        
        //otherwise, configure a typical cell to show the item info
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.MenuItemConstants.MenuItemCellIdentifier) as! MenuItemTableViewCell
        let menuItem = fetchedArrayForSorting[indexPath.row]
        
        cell.menuItemName.text = menuItem.title
        cell.timesOrdered.text = "\(menuItem.timesOrdered)"
        
        cell.image5.image = nil
        cell.image4.image = nil
        cell.image3.image = nil
        cell.image2.image = nil
        cell.image1.image = nil
        
        switch Int(menuItem.myRating) {
        case 5:
            cell.image5.image = UIImage(named: "smileyhappygreen")
            fallthrough
        case 4:
            cell.image4.image = UIImage(named: "smileyhappygreen")
            fallthrough
        case 3:
            cell.image3.image = UIImage(named: "smileyhappygreen")
            fallthrough
        case 2:
            cell.image2.image = UIImage(named: "smileyhappygreen")
            fallthrough
        case 1:
            cell.image1.image = UIImage(named: "smileyhappygreen")
        case 0:
            cell.image1.image = UIImage(named: "smileysadred")
        default:
            break
        }
        
        guard let restaurantName = menuItem.restaurant.title else {
            return cell
        }
        
        cell.restaurant.text = restaurantName
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        //if showGettingStarted == true (i.e. there are no items saved), then nothing happens when user taps the row...
        if showGettingStarted {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        //else, if the user taps the row that has the "tap here to show all saved items" (i.e. to remove the filter), then remove filter and reload table
        } else if indexPath.row == fetchedArrayForSorting.count {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            restaurantToUseForFilter = nil
            
            //see note next to viewWillAppear for comment on these two lines
            let getArray = loadMenuItems()
            fetchedArrayForSorting = getArray.map({$0})
            
            showGettingStarted = (fetchedArrayForSorting.count == 0)
            menuItemTableView.reloadData()
        //else, the user has tapped a row with an item, so pass the item that was selected to the segue method
        } else {
            let selectedMenuItem = fetchedArrayForSorting[indexPath.row]
            showEditMenuItem(selectedMenuItem)
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    //no confirmation is used for this delete, since there is no cascading deletions that occur with a menu item
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            let menuItem = fetchedArrayForSorting[indexPath.row]
            
            CoreDataStack.sharedInstance.managedObjectContext.deleteObject(menuItem)
            
            if CoreDataStack.sharedInstance.managedObjectContext.hasChanges {
                do {
                    try CoreDataStack.sharedInstance.managedObjectContext.save()
                    fetchedArrayForSorting.removeAtIndex(indexPath.row)
                    menuItemTableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                } catch let error as NSError {
                    callAlert("Error Deleting", message: error.localizedDescription , alertHandler: nil, presentationCompletionHandler: nil)
                }
            }
        }
    }
    
    //disable deleting in the event that showGettingStarted == true (i.e. the "row 1 with helper tip" is showing)
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        if indexPath.row == fetchedArrayForSorting.count {
            return false
        } else {
            return !showGettingStarted
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
}