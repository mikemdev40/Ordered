//
//  PrivacyViewController.swift
//  Ordered!
//
//  Created by Michael Miller on 4/28/16.
//  Copyright © 2016 MikeMiller. All rights reserved.
//

import UIKit
import SafariServices

/*note to self: partial transparency and dissolve of this view controller was accomplished by:
 1. set root view background color = default (clear)
 2. add another view immediately above the root view (and behind all the others), same size (full screen), and set it's background to light gray with alpha = 0.5
 3. segue settings: kind = present modally, presentation = over full screen (NOT default), transition = cross dissolve (optional, fades in rather than slide up)
 4. make sure that the view hierarchy that is desired to not be partially transparent is NOT a subview of the view added in 2; this is because the alpha of a view distributes its alpha to its subviews in a multiplicative way, so the view in 2 should be a child of the root view ONLY; the view hierarchy to be fully opaque on top of the transparent background show be a subview of the root view also - NOT a subview of the view in 2 (i.e. the root view has two subviews: the partially transparent one (which sits behind), and the view that sits on top fully opaque)
 */

//protocol that defines a function to invoke on delegate when the continue button is tapped; used to notify the delegate that the continue button was pressed (by checking the box) and that the user's checking of the box should be saved to NSUserDefaults; note to self: i initially tried an unwind segue to get back to the initial screen, but there were issues with timing, specifically, the calls in the unwindsegue method on the RestaurantViewContoller were calling before the dismissal of the privacy screen had competed, thus preventing a segue attempt to the AddRestaurantViewController within the unwind segue method from occurring; delegation worked perfectly since it was possible to call the desired method within the completion handler of dismissViewController, which will definitely only fire one the privacy VC is completely gone!
protocol PrivacyUpdateDelegate: class {
    func updatePrivacy()
}

class PrivacyViewController: UIViewController {

    @IBOutlet weak var textView: UITextView! {
        didSet {
            textView.delegate = self
            textView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        }
    }
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var continueButton: UIButton!
    
    @IBOutlet weak var checkButton: UIButton! {
        didSet {
            //prevents the background from highlighting when tapping
            checkButton.adjustsImageWhenHighlighted = false
        }
    }
    
    //toggles the value of the didOK monitoring property each time check button is tapped; update to graphics is done as part of the didOK property observer
    @IBAction func tapCheck(sender: UIButton) {
        didOK = !didOK
    }
    
    //method that is invoked when the continue button is tapped (note that the only way this buttons becomes enabled is when the user taps the "i understand" check box and marks it with a green checkmark); when this method is invoked, it dismisses the privacy notice view controller entirely and calls the delegate method inside its dismissal completion handler (see discussion below) which is responsible for updating the user settings and then presenting the next view controller
    @IBAction func tapContinue(sender: UIButton) {
        
        //dismisses the current view controller and THEN invokes updatePrivacy, which in the case of RestaurantViewController (the delegate), will IMMEDIATELY present the AddRestaurantViewController; the reason that delegation was used here instead of am unwind segue was because it was imperative that the invoked method (either as part of an unwind segue OR within completion handler) took place AFTER this view controller is dismissed BECAUSE i wanted a new view controller to be immediately presented; as part of the completion handler on dismissViewController, this was possible, but as part of an unwind segue, it was discovered that even with dismissing the view controller before/after performing the unwind, there were still timing issues with the new view controller that wanted ot be presented was not being allowed to present because this view controller was still dismissing
        dismissViewControllerAnimated(true) {
            self.delegate?.updatePrivacy()
        }
    }
    
    @IBAction func tapCancel(sender: UIButton) {
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    weak var delegate: PrivacyUpdateDelegate?
    
    //property that monitors whether the user has tapped the check box or not, and updates the graphical display of the check box accordingly; if the user HAS checked the box (didOK = true), then not only is the icon a green checkmark but the continue button becomes enabled
    var didOK = false {
        didSet {
            if didOK {
                checkButton.setImage(UIImage(named: "check-mark-green"), forState: .Normal)
                continueButton.enabled = true
            } else {
                checkButton.setImage(UIImage(named: "blank-circle"), forState: .Normal)
                continueButton.enabled = false
            }
        }
    }
    //method that creates the string for the testview containing the embedded hyperlinks (as opposed to showing the "raw" URLs and having the textview detect them); concatenation of attributed strings was informed by http://stackoverflow.com/questions/18518222/how-can-i-concatenate-nsattributedstrings
    func buildPrivacyMessage() -> NSMutableAttributedString {
        let privacyMessagePart1 = NSAttributedString(string: "By using the Google Maps search feature of this app, you are agreeing to ")
        
        let googleTermsURLText = NSMutableAttributedString(string: "Google Maps' Terms of Service")
        googleTermsURLText.addAttribute(NSLinkAttributeName, value: "https://developers.google.com/maps/terms", range: NSMakeRange(0, googleTermsURLText.length))
        
        //note: two line breaks were added using \n
        let privacyMessagePart2 = NSAttributedString(string: "\n\nBy enabling Location Services for this app, you acknowledge the use of your device’s location by Google Maps, as detailed in the ")
        
        let privacyURLText = NSMutableAttributedString(string: "Privacy Policy")
        privacyURLText.addAttribute(NSLinkAttributeName, value: "http://mikemdev40.blogspot.com/p/ordered-privacy-policy.html", range: NSMakeRange(0, privacyURLText.length))
        
        let period = NSAttributedString(string: ".")
        
        let privacyMessage = NSMutableAttributedString()
        
        privacyMessage.appendAttributedString(privacyMessagePart1)
        privacyMessage.appendAttributedString(googleTermsURLText)
        privacyMessage.appendAttributedString(period)
        privacyMessage.appendAttributedString(privacyMessagePart2)
        privacyMessage.appendAttributedString(privacyURLText)
        privacyMessage.appendAttributedString(period)
        
        //note to self: http://stackoverflow.com/questions/21687349/nsmutableattributedstring-set-font-size
        let font = UIFont(name: "HelveticaNeue", size: 15)!
        privacyMessage.addAttributes([NSFontAttributeName: font], range: NSMakeRange(0, privacyMessage.length))
        
        return privacyMessage
    }
    
    //enables the textview to start the text at the top; note to self: http://stackoverflow.com/questions/28053140/uitextview-is-not-scrolled-to-top-when-loaded/28377727#28377727
    override func viewDidLayoutSubviews() {
        self.textView.setContentOffset(CGPointZero, animated: false)
        
        /* CODE MAINTAINED FOR REFERENCE; all referenced code below was together used to:
                1. load the check box to be disabled
                2. automatically enable the check box as soon as the user scrolled to the very bottom of the textview
                3. prevent the disabling of the button if the window was big enough to show all text at once (i.e. no scrolling need to see the bottom)
         
        if (textView.contentOffset.y >= (textView.contentSize.height - textView.frame.size.height)) {
            checkButton.enabled = true
            checkButton.layer.opacity = 1.0
        } else {
            checkButton.enabled = false
            checkButton.layer.opacity = 0.5
        }
         */
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        continueButton.enabled = false

        /* CODE MAINTAINED FOR REFERENCE
        checkButton.enabled = false
        checkButton.layer.opacity = 0.5
        */

        textView.attributedText = buildPrivacyMessage()
    }

}

extension PrivacyViewController: UITextViewDelegate {
    
    //method this is invoked when the user taps a URL that is detected within the textView; in a way, the two lines below that are prior to the "return false" sort of "override" the default behavior of this method, as typically, a "return true" will enable the URL to be opened in a default browser (with the little "return to ordered" in the top left), but it was desired to use the newer safari view controller to show only this page (with a "DONE" button), so a safari view controller is created and presented below, followed by "return false" which then prevents the default browser behavior from occurring
    func textView(textView: UITextView, shouldInteractWithURL URL: NSURL, inRange characterRange: NSRange) -> Bool {
        
        let safari = SFSafariViewController(URL: URL)
        presentViewController(safari, animated: true, completion: nil)
        
        return false
    }
    
}

/* CODE MAINTAINED FOR REFERENCE
extension PrivacyViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        
        // automatically enables a button when the user scrolls to the bottom
        if (scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height)) {
            
            if !checkButton.enabled {
                checkButton.enabled = true
                checkButton.layer.opacity = 1.0
            }
        }
    }
}
*/