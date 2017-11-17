//
//  SqliteParam.swift
//  SqliteLib
//
//  Created by xiushan.fan on 12/1/16.
//  Copyright © 2016年 Frank. All rights reserved.
//

import Foundation

//This instance of class is a param to pass to driver.

class SqliteParam  {
    var sql:String?
    //insert & update sql need parameters. bindArray can take this parameters.
    var bindArray:Array<AnyObject> = Array()
}
