//
//  SqliteMasterModel.swift
//  SqliteLib
//
//  Created by xiushan.fan on 12/1/16.
//  Copyright © 2016年 Frank. All rights reserved.
//

import Foundation

class SqliteMasterModel {
    var name:String?
    var rootPage:NSInteger = 0
    var sql:String?
    var tbl_name:String?
    var type:String?
    
    class func masterModelFromDict(_ dict:NSDictionary) -> SqliteMasterModel {
        let sqliteMasterModel:SqliteMasterModel = SqliteMasterModel()
        sqliteMasterModel.type = dict.object(forKey: "type") as! String?
        sqliteMasterModel.name = dict.object(forKey: "name") as! String?
        sqliteMasterModel.tbl_name = dict.object(forKey: "tbl_name") as! String?
        sqliteMasterModel.rootPage = NSInteger.init((dict.object(forKey: "rootpage") as! String?)!)!
        sqliteMasterModel.sql = dict.object(forKey: "sql") as! String?
        return sqliteMasterModel
    }
}
