//
//  AddMenuItemViewController.swift
//  My Menu
//
//  Created by Michael Miller on 4/6/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit

//note to self: this controller is a subclass of UITableViewController because static cells were desired (and static cells are only available on subclasses of UITableViewController); a custom delegation pattern is used (RestaurantSelectorDelegate) in order pass data back from the RestaurantSelectorController, in the event the user taps the "Place:" row to update the place
class AddMenuItemViewController: UITableViewController, RestaurantSelectorDelegate {

    //MARK: - OUTLETS
    @IBOutlet weak var itemName: UITextField! { didSet { itemName.delegate = self }}
    @IBOutlet weak var itemDescription: UITextField! { didSet { itemDescription.delegate = self }}
    @IBOutlet weak var restaurant: UILabel!
    
    //tags are set for each of the smiley buttons for easy distinction when toggling them selected/not selected in the buttonTapped method below
    @IBOutlet weak var ratingButtonSad: UIButton! { didSet { ratingButtonSad.tag = 1 }}
    @IBOutlet weak var ratingButtonHappy1: UIButton! { didSet { ratingButtonHappy1.tag = 2 }}
    @IBOutlet weak var ratingButtonHappy2: UIButton! { didSet { ratingButtonHappy2.tag = 3 }}
    @IBOutlet weak var ratingButtonHappy3: UIButton! { didSet { ratingButtonHappy3.tag = 4 }}
    @IBOutlet weak var ratingButtonHappy4: UIButton! { didSet { ratingButtonHappy4.tag = 5 }}
    @IBOutlet weak var ratingButtonHappy5: UIButton! { didSet { ratingButtonHappy5.tag = 6 }}
    
    //this label becomes hidden as soon as the restaurantOfItem is set (either on loading or when selected in the RestaurantSelectorController)
    @IBOutlet weak var tapToSelectLabel: UILabel!
    
    @IBOutlet weak var numberOrderedLabel: UILabel!
    @IBOutlet weak var notesLabel: UITextView! { didSet { notesLabel.delegate = self }}
    @IBOutlet weak var stepper: UIStepper!
    
    //MARK: - PROPERTIES
    //passed properties when this view controller is segued to from the either the MenuItemViewController (via "+" or tapping an item), or the RestaurantViewController (via tapping "Add an Item")
    var actionToAssignToButton: Selector!
    var titleToShow: String?
    
    //additional property that is passed when this controller is segued to from the MenuItemViewController, leading to the item's info being initially loaded into the respective outlets
    var menuItemToEdit: MenuItem?

    //additional property that is passed when this controller is segued to from the RestaurantViewController, leading to the row with "Place:" to be initially loaded with the place name
    var restaurantTapped: Restaurant?
    
    //property that stores the restaurant that an item is being added to or updated; whenever this object is set, the restaurant label is updated (and the "tap to select" indicator is hidden)
    var restaurantOfItem: Restaurant? {
        didSet {
            restaurant?.text = restaurantOfItem?.title
            if let _ = restaurantOfItem {
                tapToSelectLabel?.hidden = true
            }
        }
    }
    
    //stores the order of smiley buttons
    var buttons: [UIButton]!
    
    //the rating corresponding to which smiley is tapped
    var rating: Int?
    
    //MARK: - CUSTOM METHODS
    //updates the ordered label to match the value of the stepper
    @IBAction func changeTimesOrdered(sender: UIStepper) {
        numberOrderedLabel.text = "\(Int(sender.value))"
    }
    
    ///method that is invoked by the unwind segue in the RestaurantSelectorController when the user taps a place from the table; since the only information that is needed from that controller is the place (Restaurant object), that object is sent back via the prepareForSegue and stored in this controller's restaurantOfItem property, which invokes the necessary updates through its property observer; hence, there is no additional action needed, and so this method is empty (but still necessary in order to connect the unwind segue)
    @IBAction func unwindFromRestaurantSelector(segue: UIStoryboardSegue) { }

    ///method that sets up the six rating buttons and also arranges the buttons correctly in the array to be accessed later
    func configureButtons() {
        buttons = [ratingButtonSad, ratingButtonHappy1, ratingButtonHappy2, ratingButtonHappy3, ratingButtonHappy4, ratingButtonHappy5]
        
        let sadFaceGrayImage = UIImage(named: "smileysadgray")
        let sadFaceRedImage = UIImage(named: "smileysadred")
        let happyFaceGrayImage = UIImage(named: "smileyhappygray")
        let happyFaceGreenImage = UIImage(named: "smileyhappygreen")
        
        //sets each button to gray versions as the normal state and colored (red/green) versions for when they are in selected mode
        for button in buttons {
            if button.tag == 1 {
                button.setImage(sadFaceGrayImage, forState: .Normal)
                button.setImage(sadFaceRedImage, forState: .Selected)
            } else {
                button.setImage(happyFaceGrayImage, forState: .Normal)
                button.setImage(happyFaceGreenImage, forState: .Selected)
            }
            button.addTarget(self, action: #selector(AddMenuItemViewController.buttonTapped(_:)), forControlEvents: .TouchUpInside)
            
            button.adjustsImageWhenHighlighted = false
        }
    }
    
    ///method that is attached to each smiley button and when a smiley is tapped, it sets the current rating of the item to be set to whichever button was tapped in the array, then highlights the appropriate button(s) in response
    func buttonTapped(button: UIButton) {
        rating = buttons.indexOf(button)!
        
        for (index, button) in buttons.enumerate() {
            button.selected = (index <= rating) && (button.tag != 1)
        }
        
        ratingButtonSad.selected = (button.tag == 1)
    }
    
    ///method that is invoked when the view loads if menuItemToEdit is not nil (i.e. the user tapped an item in MenuItemViewController) and loads all appropriate outlet properties to match those that are saved in the persisten store for the tapped on item, as well as setting the smiley faces to reflect the saved item rating
    func loadMenuItemToEdit(menuItemToUpdate: MenuItem) {
        
        itemName.text = menuItemToUpdate.title
        itemDescription.text = menuItemToUpdate.itemDescription
        stepper.value = Double(menuItemToUpdate.timesOrdered)
        numberOrderedLabel.text = "\(menuItemToUpdate.timesOrdered)"
        notesLabel.text = menuItemToUpdate.notes
        
        restaurantOfItem = menuItemToUpdate.restaurant //causes the property observer on the restaurantOfItem property to be invoked, which updates the restaurant field and hides the "Tap to Select" text
        
        rating = Int(menuItemToUpdate.myRating)
        
        if rating == 0 {
            ratingButtonSad.selected = true
        } else {
            for (index, button) in buttons.enumerate() {
                button.selected = (index <= rating) && (button.tag != 1)
            }
        }
        
    }
    
    ///method that cancels the update/add item, rolling back any changes that may be present on the context and then dismissing the view controller
    func cancel() {
        if CoreDataStack.sharedInstance.managedObjectContext.hasChanges {
            CoreDataStack.sharedInstance.managedObjectContext.rollback()
        }
        
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    ///method that saves a new item; this method is attached to the Save button when the view controller loads if the controller is being displayed in response to the user tapping "+" (as set during the prepareForSegue in the MenuItemViewController)
    func save() {
        
        //in case the save button is tapped when the cursor is still in either textfield, this prevents the keyboard from popping up after the save is complete
        itemName.resignFirstResponder()
        itemDescription.resignFirstResponder()
        notesLabel.resignFirstResponder()
        
        guard let itemName = itemName.text where itemName != "" else {
            callAlert("Required Field Missing", message: "Must have an Item Name before saving!", alertHandler: nil, presentationCompletionHandler: nil)
            return
        }
        
        guard let myRating = rating else {
            callAlert("Required Field Missing", message: "Must select a Rating before saving!", alertHandler: nil, presentationCompletionHandler: nil)
            return
        }
        
        guard let restaurant = restaurantOfItem else {
            callAlert("Required Field Missing", message: "Must select a Place before saving!", alertHandler: nil, presentationCompletionHandler: nil)
            return
        }
        
        let stepperInt = Int(stepper.value)
        
        //creates a new item in the core data managed object context
        let _ = MenuItem(title: itemName, restaurant: restaurant, itemDescription: itemDescription.text, notes: notesLabel.text, myRating: Int16(myRating), timesOrdered: Int16(stepperInt), context: CoreDataStack.sharedInstance.managedObjectContext)
        
        do {
            try CoreDataStack.sharedInstance.managedObjectContext.save()
            dismissViewControllerAnimated(true, completion: nil)
        } catch {
            callAlert("Error Saving", message: "There was a problem saving", alertHandler: nil, presentationCompletionHandler: nil)
        }
    }
    
    ///method that updates a loaded item; this method is attached to the Save button when the view controller loads if the controller is being displayed in response to the user tapping an item from the table (as set during the prepareForSegue in the MenuItemViewController)
    func update() {
        
        //in case the save button is tapped when the cursor is still in either textfield, this prevents the keyboard from popping up after the save is complete
        itemName.resignFirstResponder()
        itemDescription.resignFirstResponder()
        notesLabel.resignFirstResponder()
        
        guard let itemName = itemName.text where itemName != "" else {
            callAlert("Required Field Missing", message: "Must have an Item Name before saving!", alertHandler: nil, presentationCompletionHandler: nil)
            return
        }
        
        guard let myRating = rating else {
            callAlert("Required Field Missing", message: "Must select a Rating before saving!", alertHandler: nil, presentationCompletionHandler: nil)
            return
        }
        
        guard let restaurant = restaurantOfItem else {
            callAlert("Required Field Missing", message: "Must select a Place before saving!", alertHandler: nil, presentationCompletionHandler: nil)
            return
        }
        
        guard let menuItemToEdit = menuItemToEdit else {
            callAlert("Error Loading Data", message: "There was an error selecting item", alertHandler: nil, presentationCompletionHandler: nil)
            return
        }
        
        //requires confirmation from the user in order to update/overwrite any changes that were made
        let confirmAlert = UIAlertController(title: "Confirm Changes", message: "Are you sure you want to save these changes?", preferredStyle: .Alert)
        
        confirmAlert.addAction(UIAlertAction(title: "Yes", style: .Default, handler: { [unowned self] (alertAction) in
            let stepperInt = Int(self.stepper.value)
            
            menuItemToEdit.title = itemName
            menuItemToEdit.restaurant = restaurant
            menuItemToEdit.itemDescription = self.itemDescription.text
            menuItemToEdit.notes = self.notesLabel.text
            menuItemToEdit.myRating = Int16(myRating)
            menuItemToEdit.timesOrdered = Int16(stepperInt)
            
            if CoreDataStack.sharedInstance.managedObjectContext.hasChanges {
                do {
                    try CoreDataStack.sharedInstance.managedObjectContext.save()
                    self.dismissViewControllerAnimated(true, completion: nil)
                } catch {
                    self.callAlert("Error Saving", message: "There was a problem saving", alertHandler: nil, presentationCompletionHandler: nil)
                }
            }
        }))
        confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        self.presentViewController(confirmAlert, animated: true, completion: nil)
    }
    
    ///method that is registered with the tap gesture recognizer and checks the location of a tap to see if the tap occurred on the cell with "Place:," and if so, perform the segue to the RestaurantSelectorController; if not, do nothing except dismiss the keyboard (note to self: a gesture was used instead of "touchesBegan" because touchesBegan doesn't work the same way with a tableView; there was initially an issue with the restaurant selector row not firing the segue that was connected to it after implementing the gesture recognizer, so it was necessary to hit test the point to check and see if the tap was on the row associated with the restaurant selection; doing this required setting the restaurant row (only) to a subclass of UITableViewCell so that it could be distinguished from the other rows)
    func didTap(gesture: UIGestureRecognizer) {
        let pointOfTouch = gesture.locationInView(tableView)
        let view = tableView.hitTest(pointOfTouch, withEvent: nil)

        //tests to see if tap occurs on the little > accessory icon in the restaurant row, since this little area registers as a UITableViewCell (not a RestaurantRowTableViewCell), and performs the segue if so...
        if let _ = view as? UITableViewCell {
            performSegueWithIdentifier(Constants.AddMenuItemConstants.ShowRestaurantSelectorSegue, sender: nil)
        
        //...else, tests to see if tap occurs on the "Place:" row itself (and performs the segue if so) by looking at the superview of the view, which registers as a UITableViewCellContentView, and checking to see if the superview (i.e. the table view cell itself) is of type RestaurantRowTableViewCell, which is differentiated from the rest of the rows because only the restaurant row has been set as a subclassed RestaurantRowTableViewCell in interface builder, while the other rows are generic UITAbleViewCells...
        } else if let _ = view?.superview as? RestaurantRowTableViewCell {
            performSegueWithIdentifier(Constants.AddMenuItemConstants.ShowRestaurantSelectorSegue, sender: nil)
       
        //...else, the tap was somewhere other than the "Place:" row (and not involving another UIControl) so dismiss the keyboard and do nothing else
        } else {
            tableView.endEditing(true)
        }
    }
    
    //MARK: - CONTROLLER CLASS METHODS & LIFECYCLE
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == Constants.AddMenuItemConstants.ShowRestaurantSelectorSegue {
            if let dvc = segue.destinationViewController as? RestaurantSelectorController {
                dvc.delegate = self
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //the action of the Save button is either save() of update(), depending on how the user got to this screen (either by tapping the "+" button or tapping an item in the table)
        let saveButton = UIBarButtonItem(barButtonSystemItem: .Save, target: self, action: actionToAssignToButton)
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(AddMenuItemViewController.cancel))

        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItem = saveButton
        
        //the title is passed
        title = titleToShow
        
        configureButtons()
        
        if let menuItem = menuItemToEdit {
            loadMenuItemToEdit(menuItem)
        }
        
        if let restaurant = restaurantTapped {  //which is only the case when this VC gets loaded via the segue from the RestaurantViewController
            restaurantOfItem = restaurant //invokes UI update via property observer, which is safe now since outlets have been set
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(AddMenuItemViewController.didTap))
        tableView.addGestureRecognizer(tapGesture)
    }
    
    //MARK: - TABLE VIEW DELEGATE METHODS
    //header and footer values were determined based on what i personally thought looked nice!
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 32
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
}

//MARK: - TEXTFIELD & TEXTVIEW DELEGATE METHODS
extension AddMenuItemViewController: UITextFieldDelegate, UITextViewDelegate {
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    //when the user begin editing the textview ("notes" section), a check occurse to see if the textView being passed in matches the instance of the notesLabel (which it will since there are no others), and then clears the textView when the user starts typing
    func textViewDidBeginEditing(textView: UITextView) {
        if textView === notesLabel {
            if textView.text == Constants.AddMenuItemConstants.DefaultNotesMessage {
                textView.text = ""
            }
        }
    }
    
    //when the user is finished editing the textview, if there is nothing entered (i.e. a value of ""), then sets the text to the default "Tap to edit notes..."
    func textViewDidEndEditing(textView: UITextView) {
        if textView === notesLabel {
            if textView.text == "" {
                textView.text = Constants.AddMenuItemConstants.DefaultNotesMessage
            }
        }
    }
}
