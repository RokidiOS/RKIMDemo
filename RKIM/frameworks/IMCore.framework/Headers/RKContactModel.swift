//
//  RKContactInfoModel.swift
//  RKIM
//
//  Created by chzy on 2021/11/1.
//

import Foundation
import HandyJSON
import WCDBSwift


let UserInfoUserDefaultKey = "UserInfoUserDefaultKey"


@objcMembers
/// 用户信息 model
public class RKUserInfo: NSObject, HandyJSON, TableCodable {
    
    var companyId: String = ""
    public var userId: String = ""
    var companyName: String = ""
    var userName: String = ""
    var realName: String = ""
    var unitName: String = ""
    var phone: String = ""
    var shortNumber: String = ""
    var email: String = ""
    var sex: String = ""
    var post: String = ""
    var avatar: String = ""
    
    public var license: String = ""
    var licenseType: String = ""
    var expiration: Int64 = 0
        
    public func mapping(mapper: HelpingMapper) {
        mapper <<<
            licenseType <-- "type"
        mapper <<<
            userId <-- "deviceUserId"
    }
    
    required public override init() {}
    public enum CodingKeys:String, CodingTableKey{
        public typealias Root = RKUserInfo
        public static let objectRelationalMapping = TableBinding(CodingKeys.self)
        case avatar
    }
}

@objcMembers
/// 群组中 联系人信息model
public class RKContactModel: NSObject, HandyJSON, TableCodable {
    /// 用户id
    public var userId: String = ""
    /// 用户名
    public var username: String = ""
    /// 真实名字
    public var realName: String = ""
    /// 岗位信息
    public var postName: String = ""
    /// 公司信息
    public var companyName: String = ""
    /// 头像URL
    public var headUrl: String = ""
    /// 部门
    public var unitName: String = ""
    /// 0-离线 1-在线
    public var status: Int = 0
    
    /// 本地标记字段 是否选中
    public var selected: Bool = false
    var ownerId: String = RKUserCenter.userInfo.userId
    /// 当前是否是自己
    public var isSelf: Bool {
        get {
            return self.userId == RKUserCenter.userInfo.userId
        }
    }
    
    public func mapping(mapper: HelpingMapper) {
        mapper <<<
            userId <-- ["deviceUserId", "userId"]
        mapper <<<
            headUrl <-- ["headPortrait"]
    }
    
    required public override init() {}
    
}


@objcMembers
/// 当前用户model
public class RKUserCenter: NSObject {
  static public var userInfo = RKUserInfo()
  static public var userConCondition = Expression(with: Column(named: "ownerId")) == userInfo.userId
}


@objcMembers
/// 群组信息 model
public class RKGroupModel: NSObject, HandyJSON, TableCodable {
    public var onlineAccountNum: Int = 0
    public var groupName: String = ""
    public var userList: [RKContactModel] = []
    public var totalAccountNum: Int {
        get {
            return userList.count
        }
    }
    public var groupId: String = ""
    public var lastMessage: RKChatMessage?
    public var tms: Int = 0
    public var unReadCount :Int = 1
    public var groupAvatars: String?
    public var ownerId: String = RKUserCenter.userInfo.userId
    required public override init() {}
}


@objcMembers
/// 联系人列表
public class RKContactListModel: NSObject , HandyJSON {
    /// 在线人数
    var onlineAccountNum: Int = 0
    /// 总的人数
    var totalAccountNum: Int = 0
    
    /// 所有联系人
    public var contactsList: [RKContactModel] = []
    
    /// 在线联系人
    var onlineContacts: [RKContactModel]  {
        get {
            var onlineContacts = self.contactsList.filter { (contactInfo) in
                return contactInfo.status == 1
            }
            
            onlineContacts = onlineContacts.sorted { (model1, model2) -> Bool in
                model1.realName.localizedCompare(model2.realName) == .orderedAscending
            }
            
            return onlineContacts
        }
    }
    /// 离线联系人
    var offlineContacts: [RKContactModel]  {
        get {
            var offlineContacts = self.contactsList.filter { (contactInfo) in
                return contactInfo.status == 0
            }
            
            offlineContacts = offlineContacts.sorted { (model1, model2) -> Bool in
                model1.realName.localizedCompare(model2.realName) == .orderedAscending
            }
            return offlineContacts
        }
    }
    
    required public override init() {}
    
}

