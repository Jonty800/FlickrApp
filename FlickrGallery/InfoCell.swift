// Part of FlickrApp | Copyright (C) 2014-2015 Jon Baker <jb854@kent.ac.uk> c/o School of
// Engineering and Digital Arts <http://www.eda.kent.ac.uk> | Under BSD-3 | See LICENSE.txt

import UIKit

class InfoCell : UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel! //title for the cell
    @IBOutlet weak var contentLabel: STTweetLabel! //content of the cell
    
    func configCell(title : String, var content : String) {
        titleLabel.text = title
        if(content == ""){
            content = "N/A"
        }
        //strip whitespace and newlines from the end
        content = content.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
        //strip HTML tags
        content = content.stringByReplacingOccurrencesOfString("<[^>]+>", withString: "", options: .RegularExpressionSearch, range: nil)
        contentLabel.makeColorsLighter() //make clickable links the lighter blue (custom method i made in STTweetLabel)
        contentLabel.text = content //done
    }
    
}
