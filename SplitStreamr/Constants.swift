//
//  Constants.swift
//  SplitStreamr
//
//  Created by Joseph Pecoraro on 2/19/16.
//  Copyright © 2016 SplitStreamr. All rights reserved.
//

import UIKit

// MARK: Closure Defines

typealias ErrorClosure = (error: NSError?) -> Void;
typealias BooleanClosure = (success: Bool) -> Void;
typealias SongClosure = (error: NSError?, song: Song?) -> Void;
typealias SongArrayClosure = (error: NSError?, list: Array<Song>?) -> Void;
typealias JsonClosure = (error: NSError?, jsonData: AnyObject?) -> Void;
typealias DataClosure = (error: NSError?, data: NSData?) -> Void;
typealias StringClosure = (error: NSError?, string: String?) -> Void;

// MARK: Color Scheme

// TODO: Redefine Color Scheme

let blueLight1 = UIColor(hexString: "65a5d1");
let blueLight2 = UIColor(hexString: "3e94d1");
let blue1 = UIColor(hexString: "0a64a4");
let blueDark1 = UIColor(hexString: "24577b");
let blueDark2 = UIColor(hexString: "03406a");
let transparentOrange = UIColor(hexString: "bfec6b0e");
let orange = UIColor(hexString: "ec6b0e");

let offWhiteColor = UIColor(hexString: "fefefe");

let buttonNormalColor = blue1;
let buttonHighlightedColor = blueDark2;

let shadowColor = blueLight1;
let navigationBarColor = blue1;

// MARK: Segues

// MARK: Reuse Identifiers

// MARK:

let baseURL = "http://thisismypersonal.website";

let savedSongsDictionaryKey = "savedSongsDictionaryKey";

let songDownloadedNotificationIdentifier = "songDownloadedNotificationIdentifier";

let networkErrorDomain = "com.splitstreamr.network";

let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0];

// MARK: Debug

let dateFormatter: NSDateFormatter = {
    let formatter = NSDateFormatter()
    formatter.locale = NSLocale.currentLocale()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
}()

func debugLog(message: String) {
    dispatch_async(dispatch_get_main_queue(), {
        print("\(dateFormatter.stringFromDate(NSDate())) | \(message)");
    });
}


