// Part of FlickrApp | Copyright (C) 2014-2015 Jon Baker <jb854@kent.ac.uk> c/o School of
// Engineering and Digital Arts <http://www.eda.kent.ac.uk> | Under BSD-3 | See LICENSE.txt

import UIKit

class HomeViewController: NVGalleryViewController, UISearchBarDelegate {
    
    //the search bar view
    @IBOutlet var searchBar: UISearchBar!
    
    //the header (shows a shadow)
    @IBOutlet weak var headerView: UIView!
    //the header label (holds text)
    @IBOutlet weak var headerLabel: UILabel!
    //the activity spinner
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    //an array of the interesting items
    var flickrResults = NSMutableArray()
    
    //delegate method
    override func viewDidLoad() {
        super.viewDidLoad()
        spinner.startAnimating()
        spinner.hidesWhenStopped = true //show the spinner
        super.spinnerItem = spinner;
        
        searchBar.delegate = self //setup search bar
        searchBar.layer.masksToBounds = false
        searchBar.layer.shadowOffset = CGSizeMake(0, 2);
        searchBar.layer.shadowRadius = 3;
        searchBar.layer.shadowOpacity = 0.5;
        
        headerView.layer.masksToBounds = false //set up header shadow
        headerView.layer.shadowOffset = CGSizeMake(0, 5);
        headerView.layer.shadowRadius = 5;
        headerView.layer.shadowOpacity = 0.5;
        
        loadInterestingImages() //load the images
    }
    
    //loads the interesting images Async using NVGalleryViewController.h (super class)
    func loadInterestingImages(){
        
        //check for internet connection, alert if false
        if(!Reachability.isConnectedToNetwork()){
            var alertController = UIAlertController(title: "Unable to connect to Flickr", message: "Unable to connect to the internet. Ensure that you are using Mobile Data or connected to a WiFi device.", preferredStyle: .Alert)
            
            // Create the actions
            var okAction = UIAlertAction(title: "Retry", style: UIAlertActionStyle.Default) {
                UIAlertAction in
                NSLog("Retry Pressed")
                self.loadInterestingImages();
            }
            var cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {
                UIAlertAction in
                NSLog("Cancel Pressed")
            }
            
            // Add the actions
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            
            // Present the controller
            self.parentViewController?.presentViewController(alertController, animated: true, completion: nil)
            return;
        }
        
        let flickr:FlickrHelper = FlickrHelper()
        
        let urls = NSMutableArray()
        flickr.getPopularImages("", completion: { (searchString:String!, flickrPhotos:NSMutableArray!, error:NSError!) -> () in
            
            if error == nil{
                
                dispatch_async(dispatch_get_main_queue(), {
                    //separate the images
                    self.flickrResults = NSMutableArray(array: flickrPhotos)
                    var i:Int=0;
                    for result in self.flickrResults {
                        var myError: NSError?
                        var p : Photo = result as Photo
                        urls[i++]=p.url!
                    }
                    self.imageurls = urls
                    //place all the images
                    self.placeImages()
                })
                
            } else { //process a popup if the response is 'fail'
                var alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
                
                // Create the actions
                var okAction = UIAlertAction(title: "Retry", style: UIAlertActionStyle.Default) {
                    UIAlertAction in
                    //try this method again
                    self.loadInterestingImages();
                }
                var cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {
                    UIAlertAction in
                    //do nothing
                }
                
                // Add the actions
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                
                // Present the controller
                self.parentViewController?.presentViewController(alertController, animated: true, completion: nil)
            }
            
        })
        
    }
    
    //handler controlling what happens when an image is tapped once
    override func imgTouchUp(sender: AnyObject?) {
        var gesture : UITapGestureRecognizer = sender as UITapGestureRecognizer;
        var view : UIImageView = gesture.view as UIImageView
        println("Tapped Image tag is \(view.tag)");
        let vc : PhotoViewController = self.storyboard?.instantiateViewControllerWithIdentifier("PhotoViewController") as PhotoViewController
        //load the photo page for this image
        vc.flickrPhoto = flickrResults[view.tag as Int] as Photo
        vc.flickrPhoto.thumbnail = view.image
        self.showViewController(vc as PhotoViewController, sender: nil)
    }
    
    func searchBar(searchBar: UISearchBar!, textDidChange searchText: String!) {
        //do stuff on search key press
    }
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar!) {
        searchBar.text = "" //clear text
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
       //change to the Results page
        let destinationViewController:ResultsViewController = segue.destinationViewController as ResultsViewController
        
        if !searchBar.text.isEmpty{
            destinationViewController.searchTerm = searchBar.text //set the search term
        }else{
            //notify that no search term was entered
            let alert:UIAlertController = UIAlertController(title: "Error", message: "Please enter a search term!", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        
    }
    
    //add the "Search" button in the keyboard
    func searchBarSearchButtonClicked( searchBar: UISearchBar!)
    {
        let vc : ResultsViewController = self.storyboard?.instantiateViewControllerWithIdentifier("ResultViewController") as ResultsViewController
        
        vc.searchTerm = searchBar.text
        self.showViewController(vc as ResultsViewController, sender: nil)
    }
}

