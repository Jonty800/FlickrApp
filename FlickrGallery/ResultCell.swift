// Part of FlickrApp | Copyright (C) 2014-2015 Jon Baker <jb854@kent.ac.uk> c/o School of
// Engineering and Digital Arts <http://www.eda.kent.ac.uk> | Under BSD-3 | See LICENSE.txt

import UIKit

class ResultCell: UICollectionViewCell {
    
    //The image view for this cell
    @IBOutlet var imageView: UIImageView!
    
    //loading indicator
    @IBOutlet weak var loadingView: UIActivityIndicatorView!
    @IBOutlet weak var titleLabel: UILabel! //The title
    @IBOutlet weak var viewsLabel: UILabel! //how many views
    @IBOutlet weak var dateLabel: UILabel! // for date
    var image:UIImage!{
        get{
            return self.image
        }
        
        set{
            self.imageView.image = newValue
            
            if imageOffset != nil{
                setImageOffset(imageOffset) //set new offset
            }else{
                setImageOffset(CGPointMake(0, 0)) //set offset to 0,0
            }
        }
    }
    
    
    
    var imageOffset:CGPoint! //the offset for the image
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupImageView()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupImageView()
    }
    
    func setupImageView(){
        self.clipsToBounds = true
        
    }
    
    func setImageOffset(offset: CGPoint) {
        imageView.frame = CGRectOffset(self.imageView.bounds, offset.x, offset.y)
    }
    
}
