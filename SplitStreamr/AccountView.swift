//
//  AccountView.swift
//  SplitStreamr
//
//  Created by James on 3/29/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit

class AccountView: UIView {

    @IBOutlet weak var logoutButton: UIButton!
    @IBOutlet weak var settingsButton: UIButton!
    @IBOutlet weak var accountBarView: UIView!
    @IBOutlet weak var usernameLabel: UILabel!
    
    class func instanceFromNib() -> AccountView {
        return UINib(nibName: "AccountView", bundle: nil).instantiateWithOwner(nil, options: nil)[0] as! AccountView
    }
}
