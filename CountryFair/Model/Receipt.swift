//
//  Receipt.swift
//  CountryFair
//
//  Created by Administrator on 10/21/17.
//  Copyright © 2017 MyMac. All rights reserved.
//

import Foundation
import SwiftyJSON

class Receipt: NSObject, NSCoding {
    
    var receiptRefId = ""
    var occurredOn = ""
    var receiptId = ""
    var lineItemsCount = 0
    
    struct ReceiptKey {
        static let receiptRefIdKey = "receiptRefId"
        static let createdOnKey = "createdOn"
        static let receiptIdKey = "receiptId"
        static let lineItemsKey = "lineItems"
        static let lineItemsCountKey = "lineItemsCount"
    }
    
    init(_ json: JSON) {
        receiptRefId = json[ReceiptKey.receiptRefIdKey].stringValue
        occurredOn = json[ReceiptKey.createdOnKey].stringValue
        receiptId = json[ReceiptKey.receiptIdKey].stringValue
        lineItemsCount = json[ReceiptKey.lineItemsKey].arrayValue.count
    }
    
    init(_ receiptRefId: String, _ occurredOn: String, _ receiptId: String, _ lineItemsCount: Int) {
        self.receiptRefId = receiptRefId
        self.occurredOn = occurredOn
        self.receiptId = receiptId
        self.lineItemsCount = lineItemsCount
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(receiptRefId, forKey: ReceiptKey.receiptRefIdKey)
        aCoder.encode(occurredOn, forKey: ReceiptKey.createdOnKey)
        aCoder.encode(receiptId, forKey: ReceiptKey.receiptIdKey)
        aCoder.encode(lineItemsCount, forKey: ReceiptKey.lineItemsCountKey)
    }
    
    required convenience init?(coder aDecoder: NSCoder) {
        let receiptRefId = aDecoder.decodeObject(forKey: ReceiptKey.receiptRefIdKey) as! String
        let occurredOn = aDecoder.decodeObject(forKey: ReceiptKey.createdOnKey) as! String
        let receiptId = aDecoder.decodeObject(forKey: ReceiptKey.receiptIdKey) as! String
        let lineItemsCount = aDecoder.decodeInteger(forKey: ReceiptKey.lineItemsCountKey)
        
        self.init(receiptRefId, occurredOn, receiptId, lineItemsCount)
    }
    
    static let receiptListKey = "receiptList"
    
    static func loadAll() -> [Receipt] {
        if let data = UserDefaults.standard.object(forKey: receiptListKey) as? Data {
            return NSKeyedUnarchiver.unarchiveObject(with: data) as! [Receipt]
        }
        
        return []
    }
    
    static func save(_ receipt: Receipt) {
        var receipts = loadAll()
        receipts.append(receipt)
        let data = NSKeyedArchiver.archivedData(withRootObject: receipts)
        UserDefaults.standard.set(data, forKey: receiptListKey)
        UserDefaults.standard.synchronize()
    }
}
