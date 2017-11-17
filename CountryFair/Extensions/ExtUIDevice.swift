//
//  ExtUIDevice.swift
//  CountryFair
//
//  Created by Administrator on 10/22/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import Foundation

extension UIDevice {
    var isSimulator: Bool {
        #if arch(i386) || arch(x86_64)
            return true
        #else
            return false
        #endif
    }
}
