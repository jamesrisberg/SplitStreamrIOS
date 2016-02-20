//
//  NSError+LocalizedDescription.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation

extension NSError {
    convenience init(localizedDescription: String) {
        self.init(domain: networkErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey : localizedDescription]);
    }
}
