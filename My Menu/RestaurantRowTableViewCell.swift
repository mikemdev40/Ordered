//
//  RestaurantRowTableViewCell.swift
//  My Menu
//
//  Created by Michael Miller on 4/16/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit

//empty subclass used in the AddMenuItemViewControllersolely solely for the purpose of being able to distinguish the static row containing the "Restaurant" from the other static rows, as it was desired that the keyboard dismissed whenever the user taps a space that isn't for interacting (via the tap gesture recognizer), but the restuarant row was not invoking the segue, so making it a subclass (but otherwise functionally identical) allowed for the tap to be hit tested for being within a cell of a certain class
class RestaurantRowTableViewCell: UITableViewCell { }
