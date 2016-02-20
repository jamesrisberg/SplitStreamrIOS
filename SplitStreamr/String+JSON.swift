//
//  String+JSON.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation

extension String {
    init?(jsonObject: AnyObject) {
        if NSJSONSerialization.isValidJSONObject(jsonObject) {
            do{
                let data = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    self.init(string);
                }
            } catch {
                // TODO: Handle Error
                print("Error stringifying json object: \(jsonObject)");
            }
        }
        return nil;
    }
}
