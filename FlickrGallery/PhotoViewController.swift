// Part of FlickrApp | Copyright (C) 2014-2015 Jon Baker <jb854@kent.ac.uk> c/o School of
// Engineering and Digital Arts <http://www.eda.kent.ac.uk> | Under BSD-3 | See LICENSE.txt

import UIKit

@objc(PhotoViewController) class PhotoViewController: UIViewController, UIScrollViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    
    @IBOutlet weak var shadowView: UIView! //the view to create a shadow
    @IBOutlet weak var spinner: UIActivityIndicatorView! //activity spinner to show async tasks
    @IBOutlet weak var imageView: UIImageView! //the main image for this page
    @IBOutlet weak var collectionView: UICollectionView! //the collection view to hold the comments
    @IBOutlet weak var scrollView: UIScrollView! //the scrollview to hold the image
    @IBOutlet weak var zoomLabel: UILabel! //the zoom amount text label
    @IBOutlet weak var titleLabel: UILabel! //the title of the image
    @IBOutlet weak var loadingLabel: UILabel! //the label which says "loading comments" then desc
    let kCellIdentifier = "MyCell"
    
    let kHorizontalInsets: CGFloat = 4.0 //horizontal padding
    let kVerticalInsets: CGFloat = 8.0 //vertical padding
    
    var flickrPhoto: Photo! //the Photo object for this page
    var comments : NSMutableArray = NSMutableArray() //collection of Comment objects for comments
    
    //loads the comments async
    func loadComments(){
        let flickr:FlickrHelper = FlickrHelper()
        //check internet
        if(!Reachability.isConnectedToNetwork()){
            var alert = UIAlertController(title: "Error", message: "Unable to connect to the internet. Ensure that you are using Mobile Data or connected to a WiFi device.", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(alert, animated: true, completion: nil)
            return;
        }
        //load the comments in async, update data when finished
        flickr.getComments(flickrPhoto, completion: { (comments:NSMutableArray!, error:NSError!) -> () in
            if error == nil{
                //load this on the main thread
                dispatch_async(dispatch_get_main_queue(), {
                    self.comments = NSMutableArray(array: comments)
                    var sortedComments : NSArray = self.comments.reverseObjectEnumerator().allObjects
                    self.comments = NSMutableArray(array: sortedComments)
                    self.collectionView.reloadData()
                    self.spinner.stopAnimating()
                    var desc = self.flickrPhoto.desc
                    if(desc == nil || desc == ""){
                        desc = "No description available" //fix blank desc
                    }
                    
                    self.loadingLabel.text = desc
                    self.collectionView.backgroundColor = UIColor.blackColor()
                })
            }else{ //show the error to the user (Alert)
                var alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil))
                self.presentViewController(alert, animated: true, completion: nil)
            }
        })
    }
    
    // A dictionary of offscreen cells that are used within the sizeForItemAtIndexPath method to handle the size calculations. These are never drawn onscreen. The dictionary is in the format:
    // { NSString *reuseIdentifier : UICollectionViewCell *offscreenCell, ... }
    var offscreenCells = Dictionary<String, UICollectionViewCell>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Register cells
        var atitle = flickrPhoto.title.capitalizedString
        if(atitle == ""){
            atitle = "Untitled Image"
        }
        titleLabel.text = atitle //set the image title
        spinner.startAnimating() //start the spinner
        spinner.hidesWhenStopped=true
        collectionView.dataSource = self //set up delegates
        collectionView.delegate = self
        
        //set up cell nib
        var myCellNib = UINib(nibName: "CommentViewCell", bundle: nil)
        collectionView.registerNib(myCellNib, forCellWithReuseIdentifier: kCellIdentifier)
        imageView.image = flickrPhoto.thumbnail
        scrollView.contentSize = flickrPhoto.thumbnail.size //set scroll length
        
        var barButton =  UIBarButtonItem() //change the back button to only say "Back"
        barButton.title = "Back";
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = barButton;
        var doubleTapRecognizer = UITapGestureRecognizer(target: self, action: "scrollViewDoubleTapped:") //add gesture recogniser for double press
        doubleTapRecognizer.numberOfTapsRequired = 2
        doubleTapRecognizer.numberOfTouchesRequired = 1
        scrollView.addGestureRecognizer(doubleTapRecognizer)
        
        let scrollViewFrame = scrollView.frame //set up zoom
        let scaleWidth = scrollViewFrame.size.width / scrollView.contentSize.width
        let scaleHeight = scrollViewFrame.size.height / scrollView.contentSize.height
        let minScale = min(scaleWidth, scaleHeight);
        
        scrollView.maximumZoomScale = 3
        scrollView.zoomScale = minScale;
        
        shadowView.layer.masksToBounds = false
        shadowView.layer.shadowOffset = CGSizeMake(0, 3);
        shadowView.layer.shadowRadius = 3;
        shadowView.layer.shadowOpacity = 0.5;
        
        centerScrollViewContents() //center the image in the scrollview
        loadComments() //load the comments
        
    }
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets{
            return UIEdgeInsetsMake(4, 0, 4, 0) //set padding
            
    }
    
    //centers the contents of a view
    func centerScrollViewContents() {
        let boundsSize = scrollView.bounds.size
        var contentsFrame = imageView.frame
        
        if contentsFrame.size.width < boundsSize.width {
            contentsFrame.origin.x = (boundsSize.width - contentsFrame.size.width) / 2.0
        } else {
            contentsFrame.origin.x = 0.0
        }
        
        if contentsFrame.size.height < boundsSize.height {
            contentsFrame.origin.y = (boundsSize.height - contentsFrame.size.height) / 2.0
        } else {
            contentsFrame.origin.y = 0.0
        }
        
        imageView.frame = contentsFrame
    }
    
    //what happens when the user double taps on the Image
    func scrollViewDoubleTapped(recognizer: UITapGestureRecognizer) {
        
        let pointInView = recognizer.locationInView(imageView)
        
        var newZoomScale = scrollView.zoomScale
        if(newZoomScale ==  1.0){ //if 1X zoom
            newZoomScale = 1.5 //Zoom in
        }
        else if(newZoomScale == 1.5){ //if 1.5X zoom
            newZoomScale = 2.5 //zoom in
        }
        else if (newZoomScale == 2.5){ //if 2.5X zoom
            newZoomScale = 1.0 //zoom out
            
        }
        zoomLabel.text = "\(newZoomScale)X"
        if(newZoomScale == 1.0){
            zoomLabel.text = ""
        }
        
        newZoomScale = min(newZoomScale, scrollView.maximumZoomScale) //set the new zoom
        
        let scrollViewSize = scrollView.bounds.size
        let w = scrollViewSize.width / newZoomScale
        let h = scrollViewSize.height / newZoomScale
        let x = pointInView.x - (w / 2.0)
        let y = pointInView.y - (h / 2.0)
        
        let rectToZoomTo = CGRectMake(x, y, w, h);
        
        scrollView.zoomToRect(rectToZoomTo, animated: true) //animate the zoom and update
    }
    
    //when the user clicks the share button
    @IBAction func savePhoto(sender: AnyObject) {
        var textToShare:String = "Check out this image I found on Flickr \n\n" + "https://www.flickr.com/photos/\(flickrPhoto.owner)/\(flickrPhoto.photoID)/"
        
        let imageToShare : UIImage = flickrPhoto.thumbnail
        
        let activityViewController : UIActivityViewController = UIActivityViewController(
            activityItems: [textToShare, imageToShare], applicationActivities: nil)
        
        //exclude these types
        activityViewController.excludedActivityTypes = [
            UIActivityTypePrint,
            UIActivityTypeAssignToContact,
            UIActivityTypeAddToReadingList,
            UIActivityTypePostToFlickr,
            UIActivityTypePostToVimeo,
            UIActivityTypePostToTencentWeibo,
            UIActivityTypeCopyToPasteboard,
            UIActivityTypeMail
        ]
        
        //show the menu
        self.presentViewController(activityViewController, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - UICollectionViewDataSource
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        //println(comments.count)
        return comments.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell: CommentCell = collectionView.dequeueReusableCellWithReuseIdentifier(kCellIdentifier, forIndexPath: indexPath) as CommentCell
        
        var comment : Comment = comments[indexPath.row] as Comment
        cell.configCell(comments[indexPath.row] as Comment, loadImage: true)
        
        //config the comment
        if (cell.contentLabel.text == ""){
            cell.contentLabel.text = "<Image Removed>"
        }
        
        cell.contentLabel.getHref(self as UIViewController)
        return cell
    }
    
    //  Based on: DynamicCollectionViewCellWithAutoLayout-Demo
    //  https://github.com/honghaoz/Dynamic-Collection-View-Cell-With-Auto-Layout-Demo
    //  Completely modified so it works correctly -_-
    //  AutoSizes the cells
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        // Set up desired width
        let targetWidth: CGFloat = (self.collectionView.bounds.width - 3 * kHorizontalInsets)
        
        let reuseIdentifier = kCellIdentifier
        var cell: CommentCell? = NSBundle.mainBundle().loadNibNamed("CommentViewCell", owner: self, options: nil)[0] as? CommentCell
        self.offscreenCells[reuseIdentifier] = cell
        cell!.configCell(comments[indexPath.row] as Comment, loadImage: false)
        if (cell!.contentLabel.text == ""){
            cell!.contentLabel.text = "<Image Removed>"
        }
        
        var cellSize : CGSize = CGSizeMake(targetWidth, cell!.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize).height) //make an auto size
        //println(cellSize)
        return cellSize;
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return kHorizontalInsets
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return kVerticalInsets
    }
    
    
    // MARK: - Rotation
    // iOS7
    override func willRotateToInterfaceOrientation(toInterfaceOrientation: UIInterfaceOrientation, duration: NSTimeInterval) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    // iOS8
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView!) -> UIView! {
        return imageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView!) {
        centerScrollViewContents()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        let destinationViewController:InfoViewController = segue.destinationViewController as InfoViewController
        destinationViewController.flickrPhoto = flickrPhoto
    }
    
}

