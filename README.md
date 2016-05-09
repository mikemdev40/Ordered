#Ordered!
##Udacity iOS Developer Nanodegree: Capstone Project

###_[Download it on the App Store!](https://itunes.apple.com/us/app/ordered!/id1108247978?ls=1&mt=8)_

**Thank you**

 This complete app is proudly open sourced as a THANK YOU to the very community that helped me go from installing Xcode for the first time and reading my first line of Swift to building a full production-quality app from start to finish in 8 months.  And a special thank you to the Udacity iOS Developer Nanodegree program, for which this served as the final project.  This app is dedicated to fellow developers who are just getting started, and as the code is fully commented with "notes to self" about design decisions and important things to remember, I truly hope that someone out there can learn something from it!  If nothing else, maybe it will inspire you to build something even greater :)
 
 All feedback, thoughts, and suggestions are certainly welcomed, and if you have questions or would like to discuss any parts of the code, please don't hesitate to reach out (and if you'd like to contribute directly, feel free to submit a pull request)!
 
 Thank you again,
 
 Mike
 
**Short preview video of this app available on [my blog](http://mikemdev40.blogspot.com).**

---
**Overview**

**_Never again forget that great entree you ordered for dinner, and always have a restaurant to recommend to friends!_**

Want to keep track of all the various food and drink items that you order at restaurants, cafes, and other places so that you know what to order again (or avoid)?

Want to be able to make quick recommendations to friends for good places to have a meal or snack and what to order?

Interested in knowing which items you order the most, the places from which you order the most often, and how all your places and items rank based on your personal ratings?

If you answered YES to any (or all) of the above, then *Ordered!* is for you!

*Features of Ordered!:*
- Multi-tab favorites-tracking app that allows the user to search for and save restaurants and items from those places, such as entrees and drinks, along with personal ratings and descriptions.
- Utilizes Google Maps’ Place Details and Autocomplete APIs to search for and download information on locations.
- Users can sort saved places and items in various ways, filter items to show only those from a specific place, and see at-a-glance aggregate data points for both places and items.
- Displays all saved places on a map and allows quick access to saved items for a specific place by tapping on the location’s map bubble.
- Production application that includes a custom privacy policy and requires terms acknowledgement from user.
- Fully tested for memory leaks and under a wide variety of networking conditions.

More details, including tips for using the app and links to Privacy Policy, Terms of Use, available [HERE] (http://mikemdev40.blogspot.com/p/usingordered.html).

**Purpose**

This project was developed to solve a problem that I personally have: whenever I visit a restaurant, bar, or cafe, or order delivery, I never had a good way of tracking what I liked and didn't like in terms of meals and drinks. I seem to have dozens of take-out menus clipped together with my favorites circles all over them and no way to organize them.  This app is designed to solve that problem by enabing the user to enter a restaurant or other location at which they would like to remember something that they ordered, and then add items that they ordered from that location along with some information about those items, including a description, personal rating (from dislike up to a 5-like rating), and some notes. It also enables the user to track how many times each item has been ordered over time.  The app provides three tabs: one tab for listing the saved locations, one tab for listing the saved items at those locations, and one tab that displays a map of the saved locations. The app also enables a variety of sort options for both places and saved items and provides user-friendly data that the user can use to make decisions and recommendations, including average item rating and total number of times items have been ordered.

**Usage**

- When starting for the first time, the user is notified via a message in the opening table that adding a place (e.g. restaurant, bar, etc.) is the first thing to do; this is done via the "+" button in the top right.
- When searching for a place to add (via the Google Maps API), enabling location services will allow Google to return "predictions" that are nearer to the user.
- Locations that are saved from the Google results have an address stored (which enables its placement on the map), an icon image, and a URL to the Google page for that location. 
- Manual entry of a location (if Google can't find it, or if user is offline) is possible by tapping the row that says "Can't find what you're looking for?" Locations that are entered manually won't have an address or URL associated with them, nor will they appear on the map.
- By tapping on a saved location, an action sheet is presented to the user with various actions that can be taken with that place, including adding an item, filtering the list of items to only show those from that specific location, showing the place on the map, and opening up the Google page for that location in a Safari browser; actions that aren't available for a given location are not listed.
- Once a place has been added, the user can being adding items to the location for the purpose of remembering them; these can be added by either tapping on the location in the table and selecting "Add an Item," or by selecting the "Items" tab and tapping the "+" button.
- Each item that is added can store a title, description, associated place, rating, number of times ordered, and notes; all of these values can be subsequently edited/updated simply by tapping on the item in the items list once it has been saved for the first time.
- As the user stores more locations and more items, the sort features become more and more useful; sorting is supported on both places and on items and include sorting by attributes such as name, rating, number of times ordered, and date added.
- The data presented for each place in the "Places" tab is aggregate data for that location and includes total number of items saved for that location, combined total of times those saved items have been oredered, and an average item rating for all saved items.
- The data presented for each item in the "Items" tab is singular and includes the item rating as well as the number of times that specific item has been ordered (this feature is most useful if the user updates the number each time it gets ordered, as intended); the description of the item and notes can be viewed by tapping the item.
- Deletions of places and items is supported and can be done using swipe left or the "-" button in the top left.

**Design Specifications**

- This app features a tab bar controller, as well as many different views that are displayed in various ways (e.g. modal, show/unwind segues, etc.), as appropriate.
- There are various controls in use, incluing text fields, a stepper control, a text view, and custom image-based rating buttons; the app also utilizes a searchBarController, which is a unique class that faciltiates user-driven searches and connects seamlessly to a tableview.
- The app implements calls to two APIs from the Google Maps Web suite: the Place Autocomplete API (which enables on-the-fly location searches which update and present up to 5 "predictive" locations based on string and user location) and the Place Details API (which supplies detailed information about a particular placeID, as returned by the Autocomplete API and selected by the user).
- As a full production app, a privacy policy has been constructed for the app and user is prompted during the first use to acknowledge the privacy policy and terms, as well as enable Location Services; if user declines Location Services, design considerations were made so as to ensure core functionality is not affected and user can still use the app.
- All data pertaining to the user's locations and items is persisted using a Core Data-managed persistent store, and organized via an object graph that contains two stored entities (one for the places and one for the saved items), along with all necessary and appropriate attributes, relationships, and delete rules; additionally, NSUserDefaults is used to persist the last map zoom/region so that the map loads on each use to the most recently used scale (preventing the user from always having to "zoom in"), as well as the privacy acknowledgement.
- All networking errors are delivered to the user as necessary; code was carefully tested using the Network Link Conditioner in various states of network stability/availabilty, leading to customization and attempted optimization of NSURLsessions to support custom timeout intervals and cancellation of unnecessary API calls (and network activity).
- Memory leaks were tested for, identified, and strategically resolved (specically with regard to thoe related to unclosed NSURLSessions and Core Data fetching).
- The primary source of possible network delay is when the user taps a result in Google's Place Autocomplete list, which begins the download of data and icon image for that location via a second API call and a third URL data task; although in fast network situations, there is hardly any delay, in the event there is network lag, a spinner is shown above a blurry background while the data is downloaded (or a timeout occurs after 15 seconds); the network activity indicator is also enabled/disabled surrounding all network-based calls.
- All icons used on the tab bar and navigation controller are included as vectors, and the app icon has been created for all required sizes/resolutions.
- Licenses have been procured for all images requiring licensure, and attribution is not required for any of the graphics in use.
