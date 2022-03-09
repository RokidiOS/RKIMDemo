//
//  IMDBTool.swift
//  Alamofire
//
//  Created by chzy on 2021/11/9.
//

import Foundation
import WCDBSwift

import RKLogger

public class RKIMDBManager {
    
    public class func db() -> Database {
        let dbName = "RKIMDB"
        let path = URL(fileURLWithPath: RKIMUtil.getDocumentPath()).appendingPathComponent(dbName).path
        if !FileManager.default.fileExists(atPath: path) {
            do {
              try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)
           } catch {
               print(error.localizedDescription);
           }
         
        }
        print(path)
        let database = Database(withPath: path)
        return database
    }
    
    public class func className(_ aclsss: AnyClass) -> String {
        return String(String(NSStringFromClass(aclsss)).split(separator: ".").last!)
    }

    
    /// 添加或更新数据至对于表
    public class func dbAddObjects<Root: TableCodable>(_ model: [Root]) {
        
        if let aClass = Root.self as? AnyClass {
            do {
                let tableName: String = className(aClass)
                let _ = try self.db().insertOrReplace(objects: model, intoTable: tableName)
            } catch let error {
                print("creat table error: \(error)")
            }
        } else {
            
        }
    }
    
    /// 查询
    public class func queryObjects<T: TableCodable>(_ class:T.Type, where condition: Condition? = nil, limit limitInt: Int? = nil, orderBy orderList:[OrderBy]? = nil, _ compelet: @escaping ([T]) ->Void ) {
        guard let aClass = T.self as? AnyClass else { return }
        do {
            let tableName: String = className(aClass)
            let objects:[T] = try db().getObjects(fromTable: tableName, where: condition, orderBy: orderList, limit: limitInt)
            compelet(objects)
        } catch let error {
            RKLog("\(error)", .error)
        }
    }
    
    public class func initDB(){

        let database = db()
        database.close(onClosed: {
            try? database.removeFiles()
        })

        do {
            try database.run(transaction: {
                try database.create(table: className(RKContactModel.classForCoder()), of: RKContactModel.self)
                try database.create(table: className(RKGroupModel.classForCoder()), of: RKGroupModel.self)
                try database.create(table: className(RKChatMessage.classForCoder()), of: RKChatMessage.self)
            })
        } catch let error {
            print("creat table error: \(error)")
        }
                

    }
}
