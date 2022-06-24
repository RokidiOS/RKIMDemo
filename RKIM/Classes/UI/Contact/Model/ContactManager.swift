//
//  ContactManager.swift
//  AFNetworking
//
//  Created by chzy on 2022/6/22.
//

import Foundation
import RKIHandyJSON
import RKIMCore

public var kUserId: String = ""
extension String {
    var isSelf: Bool {
        get {
            return self == kUserId
        }
    }
    
    var userInfo: RKIMUser {
        get {
            return KContacts.first { $0.userId == self } ?? RKIMUser()
        }
    }
    
    var groupInfo: RKIMGroup? {
        get {
            return KGroups.first { $0.groupId == self }
        }
    }
}

var KContacts: [RKIMUser] = []

var KGroups: [RKIMGroup] = []

public class RKIMUser: NSObject, HandyJSON {
   
    public var userId: String = "" /// 用户id
    
    public var username: String = ""/// 用户名
    
    public var realName: String = ""/// 真实名字
    
    public var postName: String = ""/// 岗位信息
   
    public var companyName: String = "" /// 公司信息
   
    public var headPortrait: String = "" /// 头像URL
  
    public var unitName: String = ""  /// 部门
   
    public var selected: Bool = false /// 本地标记字段 是否选中

    
    public func mapping(mapper: HelpingMapper) {
        mapper <<<
            userId <-- ["deviceUserId", "userId"]
        mapper <<<
            headPortrait <-- ["headPortrait", "avatar"]
    }
    
    required public override init() {}
    
}
