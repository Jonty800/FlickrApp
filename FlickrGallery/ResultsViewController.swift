// Part of FlickrApp | Copyright (C) 2014-2015 Jon Baker <jb854@kent.ac.uk> c/o School of
// Engineering and Digital Arts <http://www.eda.kent.ac.uk> | Under BSD-3 | See LICENSE.txt

import UIKit

class ResultsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate {
    
    @IBOutlet var collectionView: UICollectionView! //the collectioView which holds the cells
    var imageCache = [String: UIImage]() //cache of search result images, for performance
    
    let ImageHeight: CGFloat = 280.0 //height for each image (larger than cell for parallex)
    let OffsetSpeed: CGFloat = 50.0 //The speed for the parallex
    var searchTerm:String! //the search term from the previous page
    
    var flickrResults:NSMutableArray! = NSMutableArray() //the collection of results for this page (Object Photo)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self //setup the delegates
        collectionView.dataSource = self
        loadPhotos() //load the collectionView
    }
    
    func loadPhotos(){
        //1) Check internet
        if(!Reachability.isConnectedToNetwork()){
            var alertController = UIAlertController(title: "Unable to connect to Flickr", message: "Unable to connect to the internet. Ensure that you are using Mobile Data or connected to a WiFi device.", preferredStyle: .Alert)
            
            // Create the actions
            var okAction = UIAlertAction(title: "Retry", style: UIAlertActionStyle.Default) {
                UIAlertAction in
                NSLog("Retry Pressed")
                self.loadPhotos();
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
        //2) Load the results into the collectionView
        let flickr:FlickrHelper = FlickrHelper()
        flickr.searchFlickrForString(searchTerm, page: 1, completion: { (searchString:String!, flickrPhotos:NSMutableArray!, error:NSError!) -> () in
            //3) If the count is 0, alert that there are no results
            if flickrPhotos.count == 0 {
                var alertController = UIAlertController(title: "No Images Found", message: "The search found no images matching \"" + self.searchTerm + "\"", preferredStyle: .Alert)
                
                // Create the actions
                var okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default) {
                    UIAlertAction in
                }
                
                // Add the action
                alertController.addAction(okAction)
                
                // Present the controller
                self.parentViewController?.presentViewController(alertController, animated: true, completion: nil)
                return;
            }
            //4)Check if there is an error. If not, update the collection
            if error == nil{
                dispatch_async(dispatch_get_main_queue(), {
                    self.flickrResults = NSMutableArray(array: flickrPhotos)
                    self.collectionView.reloadData()
                })
            }else{ //5) If there is an error, alert it here. Add retry functionality
                var alertController = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .Alert)
                
                // Create the actions
                var okAction = UIAlertAction(title: "Retry", style: UIAlertActionStyle.Default) {
                    UIAlertAction in
                    self.loadPhotos(); //retry this method
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
    
    var page : Int = 1 //current page of results
    var loadMoreCancelled = false //if the autoload is cancelled
    
    //loads more photos into the collection async
    func loadMorePhotos(){
        if(loadMoreCancelled){
            //dont try to load more results anymore
            return;
        }
        //check for internet, alert if not
        if(!Reachability.isConnectedToNetwork()){
            var alertController = UIAlertController(title: "Error Loading More Photos", message: "Unable to connect to the internet. Ensure that you are using Mobile Data or connected to a WiFi device.", preferredStyle: .Alert)
            
            // Create the actions
            var okAction = UIAlertAction(title: "Retry", style: UIAlertActionStyle.Default) {
                UIAlertAction in
                self.loadMorePhotos(); //retry this method
            }
            var cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {
                UIAlertAction in
                self.loadMoreCancelled = true
            }
            
            // Add the actions
            alertController.addAction(cancelAction)
            alertController.addAction(okAction)
            
            // Present the controller
            self.parentViewController?.presentViewController(alertController, animated: true, completion: nil)
            return;
        }

        page++ //increment the page number for next usage
        let flickr:FlickrHelper = FlickrHelper()
        flickr.searchFlickrForString(searchTerm, page: page, completion: { (searchString:String!, flickrPhotos:NSMutableArray!, error:NSError!) -> () in
            
            if error == nil{ //error handling
                dispatch_async(dispatch_get_main_queue(), {
                    self.flickrResults.addObjectsFromArray(NSMutableArray(array: flickrPhotos))
                    self.collectionView.reloadData()
                })
            }else{
                var alertController = UIAlertController(title: "Error Loading More Photos", message: error.localizedDescription, preferredStyle: .Alert)
                
                // Create the actions
                var okAction = UIAlertAction(title: "Retry", style: UIAlertActionStyle.Default) {
                    UIAlertAction in
                    self.loadMorePhotos(); //retry this method
                }
                var cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel) {
                    UIAlertAction in
                }
                
                // Add the actions
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                
                // Present the controller
                self.parentViewController?.presentViewController(alertController, animated: true, completion: nil)
            }
        })
    }
    
    
    func collectionView(collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int{
            return flickrResults.count
    }
    
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            //reuse cells
            let cell:ResultCell = collectionView.dequeueReusableCellWithReuseIdentifier("FlickrCell", forIndexPath: indexPath) as ResultCell
            
            cell.image = nil //make image blank
            cell.loadingView.startAnimating() //start the spinner to show activity
            cell.loadingView.hidesWhenStopped = true //set to remove when done
            cell.bringSubviewToFront(cell.loadingView) //bring the loading icon to front
            var canCellImage=false
            
            if(indexPath.row == flickrResults.count - 1 && flickrResults.count > 9){
                loadMorePhotos() //if the user has reached the end of the page, load more results
            }
            
            //setup an async task for the global queue
            let queue:dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
            
            //http://jamesonquave.com/blog/developing-ios-apps-using-swift-part-5-async-image-loading-and-caching/
            dispatch_async(queue, { () -> Void in
                var error:NSError?
                
                //object in question
                let object:Photo = self.flickrResults.objectAtIndex(indexPath.item) as Photo
                var tImage = self.imageCache[object.url] //check image cache
                
                //if not in cache, download and add it
                if( tImage == nil ) {
                    ImageLoader.sharedLoader.imageForUrl(object.url, completionHandler:{(image: UIImage?, url: String) in
                        self.imageCache[object.url] = image
                        tImage = self.imageCache[object.url]
                        cell.image = tImage
                        cell.loadingView.stopAnimating() //finish activity spinner
                    })
                    
                }else{
                    canCellImage=true
                    cell.loadingView.stopAnimating() //finish activity spinner
                }
                
                if error == nil{
                    var title  = object.title as String
                    
                    //do this async to reduce lag
                    dispatch_async(dispatch_get_main_queue(), {
                        if canCellImage {cell.image = tImage }
                        //uppercase first chars for cosmetics
                        title=title.capitalizedString
                        
                        cell.titleLabel.text = "  " + title // " " poor mans padding
                        cell.viewsLabel.text = "  " + object.views + " views" // " " poor mans padding
                        cell.dateLabel.text = self.formatDate(object.dateupload)
                        //initally set the offset to avoid 'jumping' issues
                        let yOffset:CGFloat = (((collectionView.contentOffset.y - cell.frame.origin.y) / 280.0) * 50) //make parallex effect
                        cell.setImageOffset(CGPointMake(0, yOffset))
                        
                    })
                }
            })
            
            return cell
    }
    
    //http://www.michaelbabiy.com/parallax-scroll-view-in-swift/
    //every scroll event, change the offset to match parallex effect
    func scrollViewDidScroll(scrollView: UIScrollView!) {
        if let visibleCells = collectionView.visibleCells() as? [ResultCell] {
            for parallaxCell in visibleCells {
                var yOffset = ((collectionView.contentOffset.y - parallaxCell.frame.origin.y) / ImageHeight) * OffsetSpeed
                parallaxCell.setImageOffset(CGPointMake(0.0, yOffset)) //set parallex amount
            }
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell,
        forRowAtIndexPath indexPath: NSIndexPath) {
            
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        let destinationViewController:PhotoViewController = segue.destinationViewController as PhotoViewController
        let indexPaths : NSArray = self.collectionView!.indexPathsForSelectedItems()
        let indexPath : NSIndexPath = indexPaths[0] as NSIndexPath
        destinationViewController.flickrPhoto = flickrResults[indexPath.row] as Photo
        destinationViewController.flickrPhoto.thumbnail = imageCache[destinationViewController.flickrPhoto.url] as UIImage? //change to picture preview page
        
        println("Clicked: " + flickrResults[indexPath.row].title) //debug
    }
    
    //Formats the date string to TimeAgo format
    func formatDate(unixTS: String) -> String{
        var timestampString = unixTS
        var timestamp = timestampString.toInt()
        var rawDate: NSDate = NSDate(timeIntervalSince1970:NSTimeInterval(timestamp!))
        var dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "dd/MM/yyyy"
        return dateFormat.stringFromDate(rawDate)
    }
    
    
}
