// Part of FlickrApp | Copyright (C) 2014-2015 Jon Baker <jb854@kent.ac.uk> c/o School of
// Engineering and Digital Arts <http://www.eda.kent.ac.uk> | Under BSD-3 | See LICENSE.txt

import UIKit
import MapKit

class InfoViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, MKMapViewDelegate {
    //the background image for the blur
    @IBOutlet weak var backgroundView: UIImageView!
    var flickrPhoto : Photo! //the flickr object
    @IBOutlet weak var tableView: UITableView! //the tableView
    var mapView : MKMapView = MKMapView() //the map view
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.delegate = self //setup table view
        tableView.dataSource = self
        tableView.estimatedRowHeight = 80.0 //attempt autoheight for cells
        tableView.rowHeight = UITableViewAutomaticDimension
        
        //set up image with blur effect (dark)
        backgroundView.image = flickrPhoto.thumbnail
        let darkBlur = UIBlurEffect(style: .Dark)
        let darkBlurView = UIVisualEffectView(effect: darkBlur)
        self.backgroundView.addSubview(darkBlurView)
        let blurAreaAmount = self.view.bounds.height
        var remainder: CGRect
        (darkBlurView.frame, remainder) = self.view.bounds.rectsByDividing(blurAreaAmount, fromEdge: CGRectEdge.MaxYEdge)
        initMapView()
    }
    
    override func viewDidAppear(animated:Bool){
        super.viewDidAppear(animated)
        tableView.reloadData()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        return 8
    }
    
    //based on help from http://www.myswiftjourney.me/2014/10/23/using-mapkit-mkmapview-how-to-create-a-annotation/
    func initMapView(){ //preload mapView to avoid lag issues on cellForRowAtIndexPath
        if(flickrPhoto.hasGeo == 1){
            let theSpan:MKCoordinateSpan = MKCoordinateSpanMake(0.01 , 0.01)
            
            //set up long & lat
            let location:CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: (flickrPhoto.lat as NSString).doubleValue, longitude: (flickrPhoto.longG as NSString).doubleValue)
            
            //setup region
            let theRegion:MKCoordinateRegion = MKCoordinateRegionMake(location, theSpan)
            var anotation = MKPointAnnotation() //add an annotation
            anotation.coordinate = location
            anotation.title = "Location"
            anotation.subtitle = "This is where the image was taken"
            mapView.addAnnotation(anotation)
            mapView.setRegion(theRegion, animated: false)
        }
    }
    
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("InfoCell", forIndexPath: indexPath) as InfoCell
        cell.tag = indexPath.row
        //set up each row individually (I know, I'm an awful person)
        if(cell.tag == 0){
            cell.configCell("TITLE", content: flickrPhoto.title.capitalizedString)
        }else if(cell.tag == 1){
            cell.configCell("TAKEN BY", content: flickrPhoto.ownername)
        }else if(cell.tag == 2){
            cell.configCell("DATE TAKEN", content: formatDate(flickrPhoto.dateupload))
        }else if(cell.tag == 3){
            cell.configCell("VIEWS", content: flickrPhoto.views)
        }else if(cell.tag == 4){
            cell.configCell("DESCRIPTION", content: flickrPhoto.desc)
        }else if(cell.tag == 5){
            var tags = flickrPhoto.tags
            if(tags == ""){
                tags = "N/A"
            }else{ //set up the tags for view
                tags = tags.stringByReplacingOccurrencesOfString(" ", withString: "    #", options: NSStringCompareOptions.LiteralSearch, range: nil)
                tags = "#" + tags
            }
            cell.contentLabel.addLineSpacing = true
            cell.configCell("TAGS", content: tags)
        }else if(cell.tag == 6){
            cell.configCell("LOCATION", content: " ")
            if(flickrPhoto.hasGeo == 1){
                mapView.frame = CGRect(x: 0, y: 34, width: cell.contentView.frame.width, height: 160)
                // mapView.removeFromSuperview()
                mapView.tag = 99
                cell.contentView.addSubview(mapView)
            }else{
                cell.configCell("LOCATION", content: "Unavailable")
            }
        }
        else if(cell.tag == 7){
            cell.configCell("LICENCE", content: FlickrHelper.getLicenceFromID(flickrPhoto.licenceID))
        }
        if(cell.tag != 6){
            applyReallyHackyMKMapViewFixForView(cell.contentView)
        }
        
        cell.contentLabel.getHref(self as UIViewController)
        return cell
    }
    
    //For some reason the MKMapView messes up and sometimes adds it other cells? Like wtf?
    //So here is my hacky as heck fix. It's awful. But works.
    func applyReallyHackyMKMapViewFixForView(view : UIView){
        var viewsToRemove : NSArray = view.subviews
        for (v) in viewsToRemove {
            if(v.tag == 99){
                v.removeFromSuperview()
            }
        }
    }
    
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if(indexPath.row == 6 && flickrPhoto.hasGeo == 1){ // manually make height for the map row (4)
            return 200
        }else{ //else use automatic
            return UITableViewAutomaticDimension
        }
        
    }
    
    //Formats the date string to TimeAgo format
    func formatDate(unixTS: String) -> String{
        var timestampString = unixTS
        var timestamp = timestampString.toInt()
        var rawDate: NSDate = NSDate(timeIntervalSince1970:NSTimeInterval(timestamp!))
        var dateFormat = NSDateFormatter()
        dateFormat.dateFormat = "dd/MM/yyyy"
        return dateFormat.stringFromDate(rawDate) + " (" + NSDate.timeAgoSinceDate(rawDate, numericDates: true) + ")"
    }
    
}
