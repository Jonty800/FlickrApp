// Part of FlickrApp | Copyright (C) 2014-2015 Jon Baker <jb854@kent.ac.uk> c/o School of
// Engineering and Digital Arts <http://www.eda.kent.ac.uk> | Under BSD-3 | See LICENSE.txt

import UIKit

// Check System Version
let isIOS7: Bool = !isIOS8
let isIOS8: Bool = floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1

class CommentCell: UICollectionViewCell {
    
    @IBOutlet weak var titleLabel: UILabel! //title for the comment (Author name)
    @IBOutlet weak var contentLabel: STTweetLabel! //Comment content
    @IBOutlet weak var dateLabel: UILabel! //Date/Time
    
    @IBOutlet weak var avatarView: UIImageView! //User picture
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 3.0 //Add a corner radius
        // Initialization code
        if isIOS7 {
            // Need set autoresizingMask to let contentView always occupy this view's bounds, key for iOS7
            self.contentView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        }
        self.layer.masksToBounds = true
    }
    
    // In layoutSubViews, need set preferredMaxLayoutWidth for multiple lines label
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func configCell(com:Comment, loadImage: Bool) {
        self.avatarView.image = nil //set to nil to fix cell reusage
        avatarView.layer.borderColor = UIColor.blackColor().CGColor //add border colour to avatar
        avatarView.layer.borderWidth = 1 //with width of 1
        if com.authorname != nil { //set author name
            self.titleLabel.text = com.authorname
        }else{
            self.titleLabel.text = "Name Unavailable"
        }
        
        if com.datecreate != nil { //set date
            self.dateLabel.text = formatDate(com.datecreate)
        }else{
            self.titleLabel.text = "Date Unknown"
        }
        
        self.contentLabel.text = "Loading..." //set comment
        if( com.content != nil ){
            //reformat the HTML inside to format Text(Href)
            com.content = com.content.stringByReplacingOccurrencesOfString("<a href=\"([^\"]*)\">(.+)</a>", withString: "$2 ($1)", options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
            //Strip any other HTML tags from thr string
            com.content = com.content.stringByReplacingOccurrencesOfString("<[^>]+>", withString: "", options: .RegularExpressionSearch, range: nil)
            //String newlines from the end of some comments
            com.content = com.content.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            contentLabel.text = com.content //set the comment content
        }else{
            contentLabel.text = "Comment Unavailable"
        }
        if(loadImage){ //load the avatar image
            if com.iconfarm <= 0 {
                com.avatarUrl="https://www.flickr.com/images/buddyicon.gif"
            }
            //Load it async
            ImageLoader.sharedLoader.imageForUrl(com.avatarUrl, completionHandler:{(image: UIImage?, url: String) in
                self.avatarView.image = image
            })
        }
    }
    
    //Formats the date string to TimeAgo format
    func formatDate(unixTS: String) -> String{
        var timestampString = unixTS
        var timestamp = timestampString.toInt()
        var rawDate: NSDate = NSDate(timeIntervalSince1970:NSTimeInterval(timestamp!))
        
        return NSDate.timeAgoSinceDate(rawDate, numericDates: true)
    }
    
}
