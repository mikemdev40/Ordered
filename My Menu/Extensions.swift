//
//  Extensions.swift
//  My Menu
//
//  Created by Michael Miller on 4/14/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import Foundation
import UIKit

//this particular extension of UIViewController enables all subclasses to utilize the callAlert method below
extension UIViewController {
    
    ///method that displays an alert with passed in title and message; it takes optional completion handlers for when the button is tapped and also when the display is presented
    func callAlert(title: String, message: String, alertHandler: ((UIAlertAction) -> Void)?, presentationCompletionHandler: (() -> Void)?) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .Default, handler: alertHandler))
        presentViewController(alertController, animated: true, completion: presentationCompletionHandler)
    }
}
