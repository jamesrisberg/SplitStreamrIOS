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
    var email: String?
    var firstName: String?
    var lastName: String?
    
    func configureWithUserData(data: UserData) {
        self.id = data.id
        self.email = data.email
        self.firstName = data.firstName
        self.lastName = data.lastName
    }
}
