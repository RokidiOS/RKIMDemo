//
//  DBHelper.swift
//  RKIM
//
//  Created by chzy on 2022/2/16.
//

import Foundation
import RKIMCore
import WCDBSwift

class DBHelper {
    // 异步获取数据库中群model
    class func asyGroup(_ groupId: String, compelet:@escaping (RKIMGroup?) -> Void) {
        let equalGroupCondition = Expression(with: Column(named: "groupId")) == groupId
        RKIMDBManager.queryObjects(RKIMGroup.self, where: equalGroupCondition) { groups in
            for group in groups {
                if groupId == group.groupId {
                    compelet(group)
                    return
                }
            }
            compelet(nil)
        }
        
    }
    
    //异步删除群组
    class func asyDeletGroup(_ groupId: String, compelet:@escaping (Bool) -> Void) {
        let equalGroupCondition = Expression(with: Column(named: "groupId")) == groupId
        do {
          try RKIMDBManager.database.delete(fromTable: RKIMDBManager.className(RKIMGroup.classForCoder()), where: equalGroupCondition)
            compelet(true)
        } catch {
            compelet(false)
        }
    }
    
    // 异步删除消息
    class func asyDeletMsg(_ messageID: String, compelet:@escaping (Bool) -> Void) {
        let equalGroupCondition = Expression(with: Column(named: "id")) == messageID
        do {
          try RKIMDBManager.database.delete(fromTable: RKIMDBManager.className(RKIMMessage.classForCoder()), where: equalGroupCondition)
            compelet(true)
        } catch {
            compelet(false)
        }
    }
    
    // 异步获取消息
    class func asyMessage(_ messageID: String, _ receiveGroup: String, compelet:@escaping (RKIMMessage?) -> Void) {
        let equalMsgIDCondition = Expression(with: Column(named: "id")) == messageID
        let equalGroupCondition = Expression(with: Column(named: "receiveGroup")) == receiveGroup
        
        RKIMDBManager.queryObjects(RKIMMessage.self, where: equalGroupCondition && equalMsgIDCondition) { msgs in
            for msg in msgs {
                if messageID == msg.id {
                    compelet(msg)
                    return
                }
            }
            compelet(nil)
        }
        
    }
    
    // 异步获取用户
    
    class func asyUser(_ userID: String, compelet:@escaping (RKIMUser?) ->Void) {
        let equalUserIDCondition = Expression(with: Column(named: "userId")) == userID
        
        RKIMDBManager.queryObjects(RKIMUser.self, where: equalUserIDCondition) { users in
            
            guard let user = users.first else {
                compelet(nil)
                return
            }
            compelet(user)
            
        }
    }
    
}
