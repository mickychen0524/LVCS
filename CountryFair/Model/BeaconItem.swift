//
//  BeaconItem.swift
//  CountryFair
//
//  Created by developer on 10/1/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit
import SwiftyJSON

class BeaconItem: NSObject {

    let beaconuuid: String?
    let beaconMajor: Int?
    let beaconMinor: Int?
    
    struct BeaconItemKey {
        static let beaconuuidKey = "beaconId"
        static let beaconMajorKey = "major"
        static let beaconMinorKey = "minor"
    }
    
    init?(_ json: JSON) {
        beaconuuid = json[BeaconItemKey.beaconuuidKey].stringValue
        beaconMajor = json[BeaconItemKey.beaconMajorKey].intValue
        beaconMinor = json[BeaconItemKey.beaconMinorKey].intValue
        
        super.init()
    }
}
