//
//  SongDrawerView.swift
//  SplitStreamr
//
//  Created by James on 3/29/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit

class SongDrawerView: UIView {
    
    @IBOutlet weak var songTable: SongTableView!
    @IBOutlet weak var upNextView: UIView!
    @IBOutlet weak var upNextLabel: UILabel!

    class func instanceFromNib() -> SongDrawerView {
        return UINib(nibName: "SongDrawerView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! SongDrawerView
    }
}
