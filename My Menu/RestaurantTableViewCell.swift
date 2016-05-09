//
//  RestaurantTableViewCell.swift
//  My Menu
//
//  Created by Michael Miller on 4/9/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit

//subclass used in the RestaurantViewController table
class RestaurantTableViewCell: UITableViewCell {

    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var items: UILabel!
    @IBOutlet weak var image1: UIImageView!
    @IBOutlet weak var image2: UIImageView!
    @IBOutlet weak var image3: UIImageView!
    @IBOutlet weak var image4: UIImageView!
    @IBOutlet weak var image5: UIImageView!

    //added view (1 x 1 in dimension, placed behind the name/location labels but horizontally and vertically to the stackview that contains them) that serves as the anchor point for the "what action?" action sheet (which displays automatically as a popover on ipad)
    @IBOutlet weak var anchorPointForPopover: UIView!
}
