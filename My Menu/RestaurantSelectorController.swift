//
//  RestaurantSelectorController.swift
//  My Menu
//
//  Created by Michael Miller on 4/14/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import Foundation
import UIKit
import CoreData

//custom delegation pattern used to pass back a selected Restaurant to the AddMenuItemViewController via the delegate (which is set in the prepareForSegue); this was an easy pattern to implement because it is defined by a property that the AddMenuItemViewController already has (restaurantOfItem)
protocol RestaurantSelectorDelegate {
    var restaurantOfItem: Restaurant? { get set }
}

class RestaurantSelectorController: UIViewController {
    
    //MARK: - OUTLETS
    @IBOutlet weak var tableOfRestaurants: UITableView! {
        didSet {
            tableOfRestaurants.delegate = self
            tableOfRestaurants.dataSource = self
        }
    }
    
    //MARK: - PROPERTIES
    //property that holds all places that get returned by the fetch request; when updated, it causes the table to reload
    var fetchedResults = [Restaurant]() {
        didSet {
            tableOfRestaurants.reloadData()
        }
    }
    
    //
    var delegate: RestaurantSelectorDelegate?
    
    //MARK: - CUSTOM METHODS
    ///method that loads and returns all saved places from the persistent store to be displayed in the table; called once when the view loads
    func loadRestaurants() -> [Restaurant] {
        let fetchRequest = NSFetchRequest(entityName: "Restaurant")
        let sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        fetchRequest.sortDescriptors = sortDescriptors
        
        do {
            return try CoreDataStack.sharedInstance.managedObjectContext.executeFetchRequest(fetchRequest) as! [Restaurant]
        } catch {
            return []
        }
    }
    
    ///method that is attached to the cancel button, which dismisses the current controller and goes back to AddMenuItemViewController; since this controller is being presented via a Show segue by a controller that is in a navigation controller, it is added to the navigation stack and thus is popped off (rather than "dismissed"), in an animated way
    func cancel() {
        navigationController?.popViewControllerAnimated(true)
    }
    
    override func viewDidLoad() {
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(RestaurantSelectorController.cancel))
        navigationItem.leftBarButtonItem = cancelButton
        title = "Select a Place"

        fetchedResults = loadRestaurants()
    }
}

//MARK: - TABLE DELEGATE & DATASOURCE METHODS
extension RestaurantSelectorController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResults.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier(Constants.RestaurantSelectorConstants.RestaurantSelectorCellIdentifier)!
        let restaurant = fetchedResults[indexPath.row]
        cell.textLabel?.text = restaurant.title
        
        return cell
    }
    
    //passes back the selected place (Restaurant object) via the delegate (which is the AddMenuItemViewController)
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedRestaurant = fetchedResults[indexPath.row]
        delegate?.restaurantOfItem = selectedRestaurant
        cancel()
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
}