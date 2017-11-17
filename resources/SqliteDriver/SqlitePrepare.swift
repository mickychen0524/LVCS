//
//  SqlitePrepare.swift
//  SqliteLib
//
//  Created by xiushan.fan on 12/1/16.
//  Copyright © 2016年 Frank. All rights reserved.
//

import Foundation

//Make sqlite param to pass to driver.

class SqlitePrepare  {
    class func createSqlWithTableName(_ tableName:String,fieldArray:Array<String>) -> SqliteParam {
        var fieldString:String = String()
        for field in fieldArray {
            fieldString.append("\(field),")
        }
        fieldString.remove(at: fieldString.characters.index(before: fieldString.endIndex))
        
        let param:SqliteParam = SqliteParam()
        param.sql = "create table if not exists \(tableName) (\(fieldString));";
        return param
    }
    
    class func insertSqlWithTableName(_ tableName:String,dict:[String:AnyObject]) -> SqliteParam {
        var fieldString:String = String()
        var placeHolderString:String = String()
        var bindArray:Array<AnyObject> = Array()
        
        for (key,object) in dict {
            fieldString.append("\(key),")
            placeHolderString.append("?,")
            bindArray.append(object)
        }
        fieldString.remove(at: fieldString.characters.index(before: fieldString.endIndex))
        placeHolderString.remove(at: placeHolderString.characters.index(before: placeHolderString.endIndex))
        let insertString:String = "insert into \(tableName)(\(fieldString)) values(\(placeHolderString));"
        let param:SqliteParam = SqliteParam()
        param.sql = insertString
        param.bindArray = bindArray
        return param
    }
    
    class func selectSqlWithTableName(_ tableName:String,fieldArray:Array<String>?,condition:String) -> SqliteParam {
        let param:SqliteParam = SqliteParam()
        var sql:String = String()
        if fieldArray == nil || fieldArray?.count == 0 {
            sql = "select * from \(tableName)"
        }
        else {
            var fieldString:String = String()
            for field in fieldArray! {
                fieldString.append("\(field),")
            }
            fieldString.remove(at: fieldString.characters.index(before: fieldString.endIndex))
            sql.append("select \(fieldString) from \(tableName)")
        }
        if condition.characters.count != 0 {
            sql.append(" where \(condition)")
        }
        param.sql = sql
        return param
    }
    
    class func updateSqlWithTableName(_ tableName:String,dict:Dictionary<String,AnyObject>,condition:String) -> SqliteParam {
        var setString:String = String()
        var bindArray:Array<AnyObject> = Array()
        for (key,value) in dict {
            setString.append("\(key)=?,")
            bindArray.append(value)
        }
        setString.remove(at: setString.characters.index(before: setString.endIndex))
        var updateSql:String = "update \(tableName) set \(setString)"
        if condition.characters.count > 0 {
            updateSql.append(" where \(condition)")
        }
        let param:SqliteParam = SqliteParam()
        param.sql = updateSql
        param.bindArray = bindArray
        return param
    }
    
    class func deleteSqlWithTableName(_ tableName:String,condition:String) -> SqliteParam {
        let param:SqliteParam = SqliteParam()
        param.sql = "delete from \(tableName) where \(condition)"
        return param
    }
}
