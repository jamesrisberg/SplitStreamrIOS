//
//  String+JSON.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/20/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import Foundation

extension String {
    static func stringFromJson(jsonObject: AnyObject) -> String? {
        if NSJSONSerialization.isValidJSONObject(jsonObject) {
            do{
                let data = try NSJSONSerialization.dataWithJSONObject(jsonObject, options: [])
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string as String;
                }
                else {
                    debugLog("Error stringifying json data: \(data)");
                }
            } catch {
                // TODO: Handle Error
                debugLog("Error stringifying json object: \(jsonObject)");
            }
        }
        return nil;
    }
}
