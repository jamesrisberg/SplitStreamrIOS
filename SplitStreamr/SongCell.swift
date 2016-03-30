//
//  SongCell.swift
//  SplitStreamr
//
//  Created by James on 2/21/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit

class SongCell: UITableViewCell {

    var activityIndicator: UIActivityIndicatorView!
    var titleArtistLabel: UILabel!
    var timeLabel: UILabel!
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String!) {
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        titleArtistLabel = UILabel(frame: CGRectMake(10,10, self.frame.size.width, self.frame.size.height))
        titleArtistLabel.text = "Title"
        titleArtistLabel.textColor = UIColor(hexString: "F8F8F8")
        self.addSubview(titleArtistLabel)
        
        self.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.5)
    }
}
