//
//  Config.swift
//  VALotteryPlay
//
//  Created by Yuriy Berdnikov on 1/10/17.
//  Copyright © 2017 ATM. All rights reserved.
//

import Foundation

struct Config {
    struct APIEndpoints {
        
        static let baseUrl = "https://dev.services.32point6.com"
        
//        static let getAllChannelsUrl = "https://dev2lngmstr.blob.core.windows.net/templates/channels.json"
//        static let playerRegisterUrl = "https://dev2lngmstr.blob.core.windows.net/templates/playerregister.json"
//        static let vaLotteryAppImageStr = "http://www.brandsoftheworld.com/sites/default/files/styles/logo-thumbnail/public/062011/virginia_lottery.png?itok=2fnKR4aZ"
//        static let countryFairImgStr = "http://static1.squarespace.com/static/568efefe25981d5681ae7eb2/t/56969cbf9cadb61ea0964074/1491844083703/"
        
    static let getAllChannelsUrl = "/templates/channels.json"
    static let playerRegisterUrl = "/templates/playerregister.json"
        
    static let vaLotteryAppImageStr = "http://www.brandsoftheworld.com/sites/default/files/styles/logo-thumbnail/public/062011/virginia_lottery.png?itok=2fnKR4aZ"
    static let countryFairImgStr = "http://static1.squarespace.com/static/568efefe25981d5681ae7eb2/t/56969cbf9cadb61ea0964074/1491844083703/"
    }
    
    struct Share {
        static let appURL = "http://www.playlazlo.com"
    }
    
    struct Google {
        struct Maps {
            static let apiKey = "AIzaSyAw-7l4jXEOzJMLYDc4kMJGEiCiPILJLbw"
        }
    }
    
    struct Proximity {
        static let beaconUDID = "E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"
    }
    
    struct License {
        static let cypherKey = "ca7eca1c-921f-486a-be25-552f0be14465"
    }
    struct WebCache {
        static let expiryTime:Int = 900
    }
}
