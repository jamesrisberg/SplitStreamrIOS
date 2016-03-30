//
//  User.swift
//  SplitStreamr
//
//  Created by James on 3/29/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation

class User : NSObject {
    
    static let sharedInstance = User()
    
    var id: String?
    var username: String?
    var fullname: String?
    
    func configureWithUserData(data: UserData) {
        self.id = data.id
        self.username = data.username
        self.fullname = data.fullname
    }
}
