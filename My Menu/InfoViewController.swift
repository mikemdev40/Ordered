//
//  InfoViewController.swift
//  Ordered!
//
//  Created by Michael Miller on 4/29/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import SafariServices

//protocol that defines a function to invoke on delegate when a button is tapped; used to pass back information to the delegate about which storyboard should be instantiated based on the button that was tapped in the popover; long note to self: segues from this view controller to the three info views were attempted at first, but doing it this wasy required the popover to "stay alive" (and presented) underneath the new view controller, which meant that the popover was still showing when the user dismissed whatever view controller got presented; this looked weird and had strange grpahical implications, so it was then necessary to ensure that the popover got dismissed BEFORE the "info" view controller (one of the three) gets presented, which couldnt happen with segues from this view controller (dismissing this view and then trying to segue from this view was clearly problematic: "presenting view not in hierarchy!"); delegation was the answer here, and by utilizing a delegate method (which, in the delegate's implementation, a new view controller will be presented) and then invoking that method as part of the dismissviewcontroller completion handler on THIS view controller, it was possible for the popover to disappear FIRST, and the selected "info" view controller to subseqently be presented (withouth timing issues); in this case, the delegate becomes the presenter of the info view controller (whichever one gets tapped), NOT this popover view controller, and so this could be dismissed without issue
protocol InfoViewDelegate: class {
    func tapButton(storyboardIndentiferToInstantiate: String)
}

//class that defines the popover view controller
class InfoViewController: UIViewController {
    
    //method that is invoked by all three buttons; the delegate method is called as part of the popover's dismissal
    @IBAction func choooseInfoSelection(buttonSelected: UIButton) {
        
        var storyboardToInstantiate = ""
        
        guard let buttonTitle = buttonSelected.titleLabel?.text else {
            return
        }
        
        switch buttonTitle {
        case "About":
            storyboardToInstantiate = "aboutView"
        case "Terms of Service":
            storyboardToInstantiate = "termsView"
        case "Privacy Policy":
            storyboardToInstantiate = "privacyView"
        default:
            break
        }
        
        //allows for the popoever to be fully dismissed before the info view controller gets presented by the delegate (which happens as part of the delegate's implementation)
        dismissViewControllerAnimated(true, completion: {
            self.delegate?.tapButton(storyboardToInstantiate)
        })
    }
    
    weak var delegate: InfoViewDelegate?

}
