//
//  SqliteDriver.swift
//  SqliteLib
//
//  Created by xiushan.fan on 12/1/16.
//  Copyright © 2016年 Frank. All rights reserved.
//

import Foundation

//use this driver to operate sqlite.

class SqliteDriver  {
    private static var __once: () = { () -> Void in
            DbHandlerDictStruct.dbTableDict = Dictionary()
        }()
    var dbHandler:OpaquePointer? = nil;
    let sqliteMasterName:String = "sqlite_master"
    
    struct DbHandlerDictStruct {
        //class did not support dictionnary variable.so make a struct.
        static var onceToken:Int  = 0
        //This dict store the table with dbPath and dbhandler
        //The key is table with dbFilePath to make the dbHandler unique to table.
        static var dbTableDict:Dictionary<String,SqliteDriver>? = nil
    }
    
    class func driverOfFilePath(_ filePath:String, tableName:String) -> SqliteDriver {
        _ = SqliteDriver.__once
        let dbHandlerKey:String = (filePath as NSString).appendingPathExtension(tableName)!
        if DbHandlerDictStruct.dbTableDict![dbHandlerKey] == nil {
            let sqliteDriver:SqliteDriver = SqliteDriver()
            let fileManager:FileManager = FileManager.default
            if !fileManager.fileExists(atPath: filePath) {
                fileManager.createFile(atPath: filePath, contents: nil, attributes: nil)
            }
            let sqliteResult:SqliteResult = SqliteResult()
            sqliteResult.sqliteResultCode = sqlite3_open(filePath.cString(using: String.Encoding.utf8)!, &sqliteDriver.dbHandler);
            DbHandlerDictStruct.dbTableDict![dbHandlerKey] = sqliteDriver;
            return sqliteDriver;
        }
        else {
            return DbHandlerDictStruct.dbTableDict![dbHandlerKey]!
        }
    }
    
    func excuteSql(_ sql:String) -> SqliteResult {
        let result:SqliteResult = SqliteResult();
        let errmsg:UnsafeMutablePointer<UnsafeMutablePointer<Int8>?>! = nil;
        result.sqliteResultCode = sqlite3_exec(dbHandler, sql.cString(using: String.Encoding.utf8)!, nil, nil, errmsg)
        return result;
    }
    
    func excuteParam(_ param:SqliteParam) -> SqliteResult {
        if (param.bindArray.count == 0) {
            return self.excuteSql(param.sql!)
        }
        else {
            var compiledStatement:OpaquePointer? = nil
            let result:SqliteResult = SqliteResult()
            result.sqliteResultCode = sqlite3_prepare(dbHandler, (param.sql?.cString(using: String.Encoding.utf8))!, -1, &compiledStatement, nil)
            for (index,object) in (param.bindArray.enumerated()) {
                print("\(index) + \(object)")
                result.sqliteResultCode = sqlite3_bind_text(compiledStatement, Int32.init(index+1), (String.init(describing: object) as NSString).utf8String, -1, nil)
            }
            result.sqliteResultCode = sqlite3_step(compiledStatement)
            sqlite3_reset(compiledStatement)
            return result
        }
    }
    
    func selectParam(_ param:SqliteParam) -> SqliteResult {
        var compiledStatement:OpaquePointer? = nil
        let sqliteResult:SqliteResult = SqliteResult();
        sqlite3_prepare(dbHandler, (param.sql?.cString(using: String.Encoding.utf8))!, -1, &compiledStatement, nil)
        while (sqlite3_step(compiledStatement) == SQLITE_ROW) {
            var rawDict:Dictionary<String,String> = Dictionary()
            for i:Int32 in 0 ..< sqlite3_column_count(compiledStatement) {
                let columnName:UnsafePointer<Int8> = sqlite3_column_name(compiledStatement, i)
                let columnValue:UnsafePointer<UInt8>? = sqlite3_column_text(compiledStatement, i)
                if columnValue != nil {
                    let name:OpaquePointer = OpaquePointer(columnName)
                    let value:OpaquePointer = OpaquePointer(columnValue!)
                    rawDict[String.init(validatingUTF8: UnsafePointer.init(name))!] = String.init(validatingUTF8: UnsafePointer.init(value))
                }
            }
            sqliteResult.sqliteResultData.append(rawDict as AnyObject)
        }
        sqlite3_reset(compiledStatement)
        return sqliteResult
    }
    
    func tableExist(_ tableName:String) -> Bool {
        var result:SqliteResult = SqliteResult()
        let param:SqliteParam = SqlitePrepare.selectSqlWithTableName(sqliteMasterName, fieldArray: nil, condition: "type like 'table'")
        result = self.selectParam(param)
        let resultArray:Array<AnyObject> = result.sqliteResultData
        var found:Bool = false
        for i:Int in 0 ..< resultArray.count {
            let dict:Dictionary<String,String> = resultArray[i] as! Dictionary<String,String>
            let sqliteMasterModel:SqliteMasterModel = SqliteMasterModel.masterModelFromDict(dict as NSDictionary)
            if (sqliteMasterModel.name! as NSString).isEqual(to: tableName) {
                found = true
                break;
            }
        }
        return found;
     }
    
}
