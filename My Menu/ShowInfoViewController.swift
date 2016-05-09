//
//  TermsViewController.swift
//  Ordered!
//
//  Created by Michael Miller on 4/29/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import SafariServices

//class used for ALL three info views for simplicity; the About view controller doesnt have a textView outlet so care must be taken not to reference this outlet for the About view controller (since it WILL be nil!); the two IBAction methods are distinct in that they are utilized only by certain instances of this class
class ShowInfoViewController: UIViewController {

    //only used by the Terms and Privacy view controllers
    @IBOutlet weak var textView: UITextView!

    //only used by the About view controller
    @IBAction func showURL(sender: UIButton) {
        if let url = sender.titleLabel?.text {
            let safari = SFSafariViewController (URL: NSURL(string: url)!)
            presentViewController(safari, animated: true, completion: nil)
        }
    }
    
    //used by ALL three view controllers
    @IBAction func cancel(button: UIBarButtonItem) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    //sinec ALL view controllers call the method below automatically, we use self.textView? instead of self.textView since the About view controller doesnt contain a textview; otherwise, the app crashes since the view controller will be looking for a textView outlet to exists (which in the About view controller it doesnt)
    override func viewDidLayoutSubviews() {
        self.textView?.setContentOffset(CGPointZero, animated: false)
    }
}
