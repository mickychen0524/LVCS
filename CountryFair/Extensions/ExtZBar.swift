//
//  ExtZBar.swift
//  VALotteryPlay
//
//  Created by MyMac on 5/10/17.
//  Copyright © 2017 ATM. All rights reserved.
//

import UIKit
import ZBarSDK

// MARK: ZBarSDK extension for sequence
extension ZBarSymbolSet: Sequence {
    public func makeIterator() -> NSFastEnumerationIterator {
        return NSFastEnumerationIterator(self)
    }
}
