//
//  ExtData.swift
//  CountryFair
//
//  Created by Mac on 10/4/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import Foundation

extension Data {
    
    func toSha256() -> Data {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        self.withUnsafeBytes {
            _ = CC_SHA256($0, CC_LONG(self.count), &hash)
        }
        return Data(bytes: hash)
    }
}
