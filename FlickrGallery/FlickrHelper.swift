// Part of FlickrApp | Copyright (C) 2014-2015 Jon Baker <jb854@kent.ac.uk> c/o School of
// Engineering and Digital Arts <http://www.eda.kent.ac.uk> | Under BSD-3 | See LICENSE.txt

import UIKit

@objc class FlickrHelper: NSObject {
    
    //Gets the URL for flickr.interestingness.getList
    class func getGetInterestingStringUrl (input:String!) -> String{
        let apiKey:String = "3dfbc4e2b3b0df7c03b6057bba1a2ea3"
        
        var url = "https://api.flickr.com/services/rest/?method=flickr.interestingness.getList&api_key=\(apiKey)&format=json&nojsoncallback=1&extras=description,date_upload,tags,views,owner_name,geo,license,date_upload&per_page=30"
        return url
    }
    
    //gets a valid url for an avatar based on author, iconserver and iconfarm
    class func getAvatarStringUrl (comment :Comment) -> String{
        var url = "http://farm\(comment.iconfarm).staticflickr.com/\(comment.iconserver)/buddyicons/\(comment.author).jpg"
        return url
    }
    
    //gets the flickr.interestingness.getList async. uses completion to transfer across errors
    func getPopularImages(searchStr:String, completion:(searchString:String!, flickrPhotos:NSMutableArray!, error:NSError!)->()){
        //get the search url
        let searchURL:String = FlickrHelper.getGetInterestingStringUrl(searchStr)
        //set queue object (default priority)
        let queue:dispatch_queue_t  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        //start the asyncronous task
        dispatch_async(queue, {
            var error:NSError? //error object
            
            //the results string, fills error if error
            let searchResultString:String! = String(contentsOfURL: NSURL(string: searchURL)!, encoding: NSUTF8StringEncoding, error: &error)
            //  println(searchResultString)
            //if error, end here
            if error != nil{
                completion(searchString: searchStr, flickrPhotos: nil, error: error)
            }else{ //all seems to be okay
                
                // Parse JSON Response
                
                let jsonData:NSData! = searchResultString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                //put json into dictionary object
                println(searchResultString)
                let resultDict:NSDictionary! = NSJSONSerialization.JSONObjectWithData(jsonData, options: nil, error: &error) as NSDictionary
                
                //if error (ususally from corrupt json) end here
                if error != nil{
                    completion(searchString: searchStr, flickrPhotos: nil, error: error)
                }else{
                    
                    //check the status from the json is ok
                    let status:String! = resultDict.objectForKey("stat") as String
                    
                    if status == "fail"{ //if result was a fail, end here
                        
                        let messageString:String = resultDict.objectForKey("message") as String
                        let error:NSError? = NSError(domain: "FlickrSearch", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:messageString])
                        
                        completion(searchString: searchStr, flickrPhotos: nil, error:error )
                    }else{
                        // split photos key into a dictonary
                        let photosDict:NSDictionary = resultDict.objectForKey("photos") as NSDictionary
                        //get the photos data from the main object into an array
                        let resultArray:NSArray = photosDict.objectForKey("photo") as NSArray
                        
                        let flickrPhotos:NSMutableArray = NSMutableArray() //make array for chosen stuff
                        
                        for photoObject in resultArray{
                            //fill array with stuff we need
                            let photoDict:NSDictionary = photoObject as NSDictionary //convert to key=>value
                            var flickrPhoto:Photo = Photo()
                            //this should be everything we need
                            flickrPhoto.farm = photoDict.objectForKey("farm") as Int
                            flickrPhoto.title = photoDict.objectForKey("title") as String
                            flickrPhoto.server = photoDict.objectForKey("server") as String
                            flickrPhoto.secret = photoDict.objectForKey("secret") as String
                            flickrPhoto.photoID = photoDict.objectForKey("id") as String
                            flickrPhoto.views = photoDict.objectForKey("views") as String
                            flickrPhoto.tags = photoDict.objectForKey("tags") as String
                            flickrPhoto.owner = photoDict.objectForKey("owner") as String!
                            flickrPhoto.ownername = photoDict.objectForKey("ownername") as String!
                            flickrPhoto.dateupload = photoDict.objectForKey("dateupload") as String!
                            flickrPhoto.licenceID = photoDict.objectForKey("license") as String!
                            let descDict:NSDictionary = photoDict.objectForKey("description") as NSDictionary
                            flickrPhoto.desc = descDict.objectForKey("_content") as String
                            if let id = photoDict.objectForKey("longitude") as? Int {
                                flickrPhoto.longG = "\(id)"
                            }else{
                                flickrPhoto.longG = photoDict.objectForKey("longitude") as String
                            }
                            if let id = photoDict.objectForKey("latitude") as? Int {
                                flickrPhoto.lat = "\(id)"
                            }else{
                                flickrPhoto.lat = photoDict.objectForKey("latitude") as String
                            }
                            
                            if(flickrPhoto.longG != "0" && flickrPhoto.lat != "0"){
                                flickrPhoto.hasGeo = 1
                            }else{
                                flickrPhoto.hasGeo = 0
                            }
                            
                            // println("HSHDHHD " + flickrPhoto.desc)
                            
                            let imageURL:NSString = FlickrHelper.getFlickrPhotoUrl(flickrPhoto, size: "z")
                            flickrPhoto.url = imageURL
                            
                            let commentsURL : String = FlickrHelper.getPhotoCommentsUrl(flickrPhoto)
                            flickrPhoto.commentsURL = commentsURL
                            flickrPhotos.addObject(flickrPhoto)//add to array
                            
                        }
                        //well done, transfer across the flickrPhotos
                        completion(searchString: searchURL, flickrPhotos: flickrPhotos, error: nil)
                        
                    }
                }
            }
        })
    }
    
    //gets the url for flickr.photos.search
    class func getSearchStringUrl (input:String!, page:Int) -> String{
        //my api key
        let apiKey:String = "3dfbc4e2b3b0df7c03b6057bba1a2ea3"
        
        //replace all " " with a comma to enforce a correct url format
        /* let formatString = input.stringByReplacingOccurrencesOfString(" ", withString: ",", options: NSStringCompareOptions.LiteralSearch, range: nil)*/
        
        //encode url
        let search:String = input.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)!
        
        //use sort=relevance to try and avoid crappy results
        var url = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&text=\(search)&per_page=10&format=json&nojsoncallback=1&sort=relevance&extras=description,date_upload,tags,owner_name,views,geo,license,date_upload&page=\(page)"
        return url
    }
    
    //method used to process a clicked element from a UILabel
    func processClickableText(input: NSString, viewController: UIViewController){
        println(input);
        var url = input
        if input.hasPrefix("#") {
            //presume hashtag
            var searchTerm = input.stringByReplacingOccurrencesOfString("#", withString: "")
            let vc : ResultsViewController = viewController.storyboard?.instantiateViewControllerWithIdentifier("ResultViewController") as ResultsViewController
            
            vc.searchTerm = searchTerm
            viewController.showViewController(vc as ResultsViewController, sender: nil)
            return
        }
        //fix urls starting with no http://
        if(!url.containsString("://")){
            url = "http://" + url
        }
        if let checkURL = NSURL(string: url) as NSURL? {
            if UIApplication.sharedApplication().openURL(NSURL(string: url)!) {
                println("url successfully opened")
            }
        } else {
            println("invalid url")
        }
    }
    
    //returns a valid URL for the image
    class func getFlickrPhotoUrl(photo:Photo, var size:String) -> String{
        
        //if empty (shouldnt happen) set to m
        if size.isEmpty{
            size = "m"
        }
        
        //return the url
        return "http://farm\(photo.farm).staticflickr.com/\(photo.server)/\(photo.photoID)_\(photo.secret)_\(size).jpg"
        
    }
    
    //returns a valid URL for the image
    class func getPhotoCommentsUrl(photo:Photo) -> String{
        //return the url
        let apiKey:String = "3dfbc4e2b3b0df7c03b6057bba1a2ea3"
        return "https://api.flickr.com/services/rest/?method=flickr.photos.comments.getList&api_key=\(apiKey)&photo_id=\(photo.photoID)&format=json&nojsoncallback=1"
        
    }
    
    //sends the async query for flickr.photos.search and gets the json response.
    func searchFlickrForString(searchStr:String, page:Int, completion:(searchString:String!, flickrPhotos:NSMutableArray!, error:NSError!)->()){
        //get the search url
        let searchURL:String = FlickrHelper.getSearchStringUrl(searchStr, page: page)
        //set queue object (default priority)
        let queue:dispatch_queue_t  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        //start the asyncronous task
        dispatch_async(queue, {
            var error:NSError? //error object
            
            //the results string, fills error if error
            let searchResultString:String! = String(contentsOfURL: NSURL(string: searchURL)!, encoding: NSUTF8StringEncoding, error: &error)
            //  println(searchResultString)
            //if error, end here
            if error != nil{
                completion(searchString: searchStr, flickrPhotos: nil, error: error)
            }else{ //all seems to be okay
                
                // Parse JSON Response
                
                let jsonData:NSData! = searchResultString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                //put json into dictionary object
                
                
                let resultDict:NSDictionary! = NSJSONSerialization.JSONObjectWithData(jsonData, options: nil, error: &error) as NSDictionary
                
                //if error (ususally from corrupt json) end here
                if error != nil{
                    completion(searchString: searchStr, flickrPhotos: nil, error: error)
                }else{
                    
                    //check the status from the json is ok
                    let status:String! = resultDict.objectForKey("stat") as String
                    
                    if status == "fail"{ //if result was a fail, end here
                        
                        let messageString:String = resultDict.objectForKey("message") as String
                        let error:NSError? = NSError(domain: "FlickrSearch", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:messageString])
                        
                        
                        completion(searchString: searchStr, flickrPhotos: nil, error:error )
                    }else{
                        // split photos key into a dictonary
                        let photosDict:NSDictionary = resultDict.objectForKey("photos") as NSDictionary
                        //get the photos data from the main object into an array
                        let resultArray:NSArray = photosDict.objectForKey("photo") as NSArray
                        
                        let flickrPhotos:NSMutableArray = NSMutableArray() //make array for chosen stuff
                        
                        for photoObject in resultArray{
                            //fill array with stuff we need
                            let photoDict:NSDictionary = photoObject as NSDictionary //convert to key=>value
                            var flickrPhoto:Photo = Photo()
                            flickrPhoto.farm = photoDict.objectForKey("farm") as Int!
                            flickrPhoto.title = photoDict.objectForKey("title") as String!
                            flickrPhoto.server = photoDict.objectForKey("server") as String!
                            flickrPhoto.secret = photoDict.objectForKey("secret") as String!
                            flickrPhoto.photoID = photoDict.objectForKey("id") as String!
                            flickrPhoto.views = photoDict.objectForKey("views") as String!
                            flickrPhoto.tags = photoDict.objectForKey("tags") as String!
                            flickrPhoto.owner = photoDict.objectForKey("owner") as String!
                            flickrPhoto.ownername = photoDict.objectForKey("ownername") as String!
                            flickrPhoto.dateupload = photoDict.objectForKey("dateupload") as String!
                            flickrPhoto.licenceID = photoDict.objectForKey("license") as String!
                            let descDict:NSDictionary = photoDict.objectForKey("description") as NSDictionary
                            flickrPhoto.desc = descDict.objectForKey("_content") as String!
                            if let id = photoDict.objectForKey("longitude") as? Int {
                                flickrPhoto.longG = "\(id)"
                            }else{
                                flickrPhoto.longG = photoDict.objectForKey("longitude") as String
                            }
                            if let id = photoDict.objectForKey("latitude") as? Int {
                                flickrPhoto.lat = "\(id)"
                            }else{
                                flickrPhoto.lat = photoDict.objectForKey("latitude") as String
                            }
                            
                            if(flickrPhoto.longG != "0" && flickrPhoto.lat != "0"){
                                flickrPhoto.hasGeo = 1
                            }else{
                                flickrPhoto.hasGeo = 0
                            }
                            
                            let imageURL:NSString = FlickrHelper.getFlickrPhotoUrl(flickrPhoto, size: "z")
                            flickrPhoto.url = imageURL
                            
                            let commentsURL : String = FlickrHelper.getPhotoCommentsUrl(flickrPhoto)
                            flickrPhoto.commentsURL = commentsURL
                            // println(commentsURL)
                            flickrPhotos.addObject(flickrPhoto)//add to array
                            
                        }
                        //when done, transfer across the flickrPhotos
                        completion(searchString: searchURL, flickrPhotos: flickrPhotos, error: nil)
                        
                    }
                }
            }
        })
    }
    
    //sends the async query for flickr.comments.getlist and gets the json response.
    func getComments(photo:Photo, completion:(comments:NSMutableArray!, error:NSError!)->()){
        //get the search url
        let commentURL:String = FlickrHelper.getPhotoCommentsUrl(photo)
        //set queue object (default priority)
        let queue:dispatch_queue_t  = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        
        //start the asyncronous task
        dispatch_async(dispatch_get_global_queue(0,0), {
            
            var error:NSError? //error object
            
            //the results string, fills error if error
            let commentResultString:String! = String(contentsOfURL: NSURL(string: commentURL)!, encoding: NSUTF8StringEncoding, error: &error)
            // println(commentResultString)
            //if error, end here
            if error != nil{
                completion(comments: nil, error: error)
            }else{ //all seems to be okay
                
                // Parse JSON Response
                
                let jsonData:NSData! = commentResultString.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
                //put json into dictionary object
                
                
                let resultDict:NSDictionary! = NSJSONSerialization.JSONObjectWithData(jsonData, options: nil, error: &error) as NSDictionary
                
                //if error (ususally from corrupt json) end here
                if error != nil{
                    completion(comments: nil, error: error)
                }else{
                    
                    //check the status from the json is ok
                    let status:String! = resultDict.objectForKey("stat") as String
                    
                    if status == "fail"{ //if result was a fail, end here
                        
                        let messageString:String = resultDict.objectForKey("message") as String
                        let error:NSError? = NSError(domain: "FlickrCommentGet", code: 0, userInfo: [NSLocalizedFailureReasonErrorKey:messageString])
                        
                        
                        completion(comments: nil, error: error)
                    }else{
                        // split photos key into a dictonary
                        let commentDict:NSDictionary = resultDict.objectForKey("comments") as NSDictionary
                        //get the photos data from the main object into an array
                        let resultArray:NSArray = commentDict.objectForKey("comment") as NSArray
                        
                        let comments:NSMutableArray = NSMutableArray() //make array for chosen stuff
                        
                        for commentObject in resultArray{
                            //fill array with stuff we need
                            let commentDict:NSDictionary = commentObject as NSDictionary //convert to key=>value
                            var comment:Comment = Comment()
                            if(commentDict.objectForKey("id") != nil){
                                comment.id = commentDict.objectForKey("id") as String
                            }
                            if commentDict.objectForKey("_content") != nil {
                                var str : String = commentDict.objectForKey("_content") as String
                                comment.content = str as String
                            }
                            if commentDict.objectForKey("authorname") != nil {
                                comment.authorname = commentDict.objectForKey("authorname") as String
                            }
                            if( commentDict.objectForKey("author") != nil){
                                comment.author = commentDict.objectForKey("author") as String
                            }
                            if( commentDict.objectForKey("iconserver") != nil ){
                                comment.iconserver = commentDict.objectForKey("iconserver") as String
                            }
                            if(commentDict.objectForKey("iconfarm") != nil){
                                comment.iconfarm = commentDict.objectForKey("iconfarm") as Int
                            }
                            if(commentDict.objectForKey("datecreate") != nil){
                                comment.datecreate = commentDict.objectForKey("datecreate") as String
                            }
                            if(commentDict.objectForKey("permalink") != nil){
                                
                                comment.permalink = commentDict.objectForKey("permalink") as String
                            }
                            
                            var aUrl = FlickrHelper.getAvatarStringUrl(comment)
                            comment.avatarUrl = aUrl
                            comments.addObject(comment)//add to array
                            
                        }
                        //when done, transfer across the flickrPhotos
                        completion(comments: comments, error: nil)
                        
                    }
                }
            }
        })
    }
    
    class func getLicenceFromID(id: String) -> String {
        if(id=="1"){ return "Attribution-NonCommercial-ShareAlike License" }
        if(id=="2"){ return "Attribution-NonCommercial License" }
        if(id=="3"){ return "Attribution-NonCommercial-NoDerivs License" }
        if(id=="4"){ return "Attribution License" }
        if(id=="5"){ return "Attribution-ShareAlike License" }
        if(id=="6"){ return "Attribution-NoDerivs License" }
        if(id=="7"){ return "No known copyright restrictions" }
        if(id=="8"){ return "United States Government Work" }
        return "All Rights Reserved" //for 0 & everything else
    }
    
}
