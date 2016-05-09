//
//  TabBarController.swift
//  My Menu
//
//  Created by Michael Miller on 4/6/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit

class TabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        //set up the tab bar images and titles
        viewControllers?[0].tabBarItem.image = UIImage(named: "restaurant")
        viewControllers?[0].tabBarItem.title = "Places"
        
        viewControllers?[1].tabBarItem.image = UIImage(named: "food")
        viewControllers?[1].tabBarItem.title = "Items"
        
        viewControllers?[2].tabBarItem.image = UIImage(named: "location")
        viewControllers?[2].tabBarItem.title = "Map"
    }
}
