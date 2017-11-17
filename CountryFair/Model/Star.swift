//
//  Star.swift
//  CountryFair
//
//  Created by Micky on 8/19/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import Foundation
import SwiftyJSON

public class Star: NSObject {
    /*
    "skuName": "abcdefg",
     "lifetimeCount": 200,
     "pendingCount": 5
     */
    
    let skuName: String?
    let lifeTimeCount: Int?
    let pendingCount: Int?
    
    struct StarKey {
        static let skuNameKey = "skuName"
        static let lifeTimeCountKey = "lifetimeCount"
        static let pendingCountKey = "pendingCount"
    }
    
    init?(_ json: JSON) {
        skuName = json[StarKey.skuNameKey].stringValue
        lifeTimeCount = json[StarKey.lifeTimeCountKey].intValue
        pendingCount = json[StarKey.pendingCountKey].intValue
        
        super.init()
    }
}
