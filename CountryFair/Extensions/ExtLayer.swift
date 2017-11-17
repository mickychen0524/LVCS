//
//  ExtLayer.swift
//  StoreClerkLite
//
//  Created by Administrator on 8/14/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import UIKit

extension CALayer {
    var borderUIColor: UIColor {
        get {
            return UIColor(cgColor: borderColor!)
        }
        
        set {
            borderColor = newValue.cgColor
        }
    }
}
