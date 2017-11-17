//
//  ExtCollection.swift
//  barcodeScaner
//
//  Created by Mac on 10/18/17.
//  Copyright © 2017 Mac. All rights reserved.
//

import Foundation

extension Collection {
    
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
