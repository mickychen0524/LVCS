//
//  md5.swift
//  RegisterAppPoc
//
//  Created by Mycom on 7/31/16.
//  Copyright © 2016 bank. All rights reserved.
//

import Foundation

class Md5Make : NSObject {
    
    static func md5(string: String) -> Data? {
        guard let messageData = string.data(using:String.Encoding.utf8) else { return nil }
        var digestData = Data(count: Int(CC_MD5_DIGEST_LENGTH))
        
        _ = digestData.withUnsafeMutableBytes {digestBytes in
            messageData.withUnsafeBytes {messageBytes in
                CC_MD5(messageBytes, CC_LONG(messageData.count), digestBytes)
            }
        }
        
        return digestData
    }

}
