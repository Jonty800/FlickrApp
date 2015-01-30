// Part of FlickrApp | Copyright (C) 2014-2015 Jon Baker <jb854@kent.ac.uk> c/o School of
// Engineering and Digital Arts <http://www.eda.kent.ac.uk> | Under BSD-3 | See LICENSE.txt

import UIKit

class Comment: NSObject {
    
    var id:String!
    var author:String!
    var authorname:String!
    var iconserver:String!
    var iconfarm: Int!
    var datecreate: String!
    var permalink: String!
    
    var content: String! //content for the comment
    var avatarUrl: String! //url for the avatar
    
    override init() {
        super.init()
    }
    
}
