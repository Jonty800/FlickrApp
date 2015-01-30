// Part of FlickrApp | Copyright (C) 2014-2015 Jon Baker <jb854@kent.ac.uk> c/o School of
// Engineering and Digital Arts <http://www.eda.kent.ac.uk> | Under BSD-3 | See LICENSE.txt

import UIKit

class Photo: NSObject {
    
    var thumbnail:UIImage!
    
    //required stuff
    var photoID:String!
    var farm:Int!
    var owner:String!
    var ownername:String!
    var server:String!
    var secret:String!
    var url:String!
    var title:String!
    
    var views:String! //number of views
    var tags:String! //tags, separated with " "
    var desc:String! //the description
    var commentsURL:String! //the valid url to get the comments
    var hasGeo:Int! //1 if long!="0" && lat!="0"
    var longG:String! //longitude
    var lat:String! //lattatude
    var dateupload : String! //date uploaded
    var licenceID : String!
    
    override init() {
        super.init()
    }
    
}
