//
//  Store.swift
//  CountryFair
//
//  Created by Micky on 8/18/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import Foundation
import SwiftyJSON
import CoreLocation

public class Store: NSObject {
    /*
    "retailerRefId": "731a1580-ebc5-42a1-a0b0-6f775fd09e09",
    "brand": null,
    "beacons": [],
    "brandRefId": null,
    "retailerName": "Dunkin Donuts",
    "addressLine1": "7165 Peach St",
    "addressLine2": null,
    "addressCity": "Erie",
    "addressStateProvince": "PA",
    "addressCounty": "Erie County",
    "addressZipPostalCode": "16509",
    "addressCountryCode": "US",
    "addressLocation": {
    "type": "Point",
    "coordinates": [
    -80.0863136,
    42.0548083
    ]
    },
    "logoUrl": "https://dev2lngmstr.blob.core.windows.net/media/acmemartlogo.png",
    "logoVerticalUrl": null,
    "logoHorizontalUrl": null
    */
    
    let retailerName: String?
    let addressLine1: String?
    let addressLine2: String?
    let addressCity: String?
    let addressStateProvince: String?
    let addressCountry: String?
    let addressZipPostalCode: String?
    let addressCountryCode: String?
    let latitude: Double!
    let longitude: Double!
    var distance: Double!
    
    struct StoreKey {
        static let retailerNameKey = "retailerName"
        static let addressLine1Key = "addressLine1"
        static let addressLine2Key = "addressLine2"
        static let addressCityKey = "addressCity"
        static let addressStateProvinceKey = "addressStateProvince"
        static let addressCountryKey = "addressCountry"
        static let addressZipPostalCodeKey = "addressZipPostalCode"
        static let addressCountryCodeKey = "addressCountryCode"
    }
    
    init?(_ json: JSON) {
        retailerName = json[StoreKey.retailerNameKey].stringValue
        addressLine1 = json[StoreKey.addressLine1Key].string
        addressLine2 = json[StoreKey.addressLine2Key].string
        addressCity = json[StoreKey.addressCityKey].string
        addressStateProvince = json[StoreKey.addressStateProvinceKey].string
        addressCountry = json[StoreKey.addressCountryKey].string
        addressZipPostalCode = json[StoreKey.addressZipPostalCodeKey].string
        addressCountryCode = json[StoreKey.addressCountryCodeKey].string
        latitude = json["addressLocation"]["coordinates"][1].doubleValue
        longitude = json["addressLocation"]["coordinates"][0].doubleValue
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        if let currentLatitude = appDelegate.myCoords?.latitude, let currentLongitude = appDelegate.myCoords?.longitude {
            let currentLocation = CLLocation(latitude: currentLatitude, longitude: currentLongitude)
            let location = CLLocation(latitude: latitude, longitude: longitude)
            distance = currentLocation.distance(from: location)
        }
        
        super.init()
    }
    
    func fullAddress() -> String {
        var address = ""
        if let addressLine1 = addressLine1 {
            address += addressLine1
        }
        
        if let addressLine2 = addressLine2 {
            address += ", " + addressLine2
        }
        
        if let addressCity = addressCity {
            address += ", " + addressCity
        }
        
        if let addressStateProvince = addressStateProvince {
            address += ", " + addressStateProvince
        }
        
        if let addressZipPostalCode = addressZipPostalCode {
            address += " " + addressZipPostalCode
        }
        
        if let addressCountryCode = addressCountryCode {
            address += ", " + addressCountryCode
        }
        
        return address
    }
}
