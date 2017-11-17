//
//  SqliteResult.swift
//  SqliteLib
//
//  Created by xiushan.fan on 12/1/16.
//  Copyright © 2016年 Frank. All rights reserved.
//

import Foundation

//Sql excuted result.

class SqliteResult {
    var sqliteResultCode:Int32?
    var sqliteResultMsg:String?
    var sqliteResultData:Array<AnyObject> = Array()
}