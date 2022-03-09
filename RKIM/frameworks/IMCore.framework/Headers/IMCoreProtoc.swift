//
//  IMCoreProtoc.swift
//  IMCore
//
//  Created by chzy on 2021/11/16.
//

import UIKit

public typealias RKResultCompelet = (_ isSuccess:Bool, _ errorMessage:String?, _ result: Any) -> Void

@objc public protocol RKIMDelegate: NSObjectProtocol {
    ///  收到消息
    @objc optional func RKMessage(didReceiveMessageWith string: String)
    
    ///  收到IM普通消息
    @objc optional func RKMessage(didReceiveNormalMessage message: RKChatMessage)
    
    /// 收到系统消息
    @objc optional func RKMessage(didReceiveSystemMessage message: RKChatMessage)
    
    /// 开启成功
    @objc optional func RKDidOpen()
    
    /// 开启失败
    @objc optional func RKDidFail(WithError error: Error)
    
    /// 被远端关闭 code 码 reason 原因 wasClean 套接字是否干净  只要不是登出 都主动做重连
    @objc optional func RKDidClose(code: Int, reason: String?, wasClean: Bool)
}

@objcMembers
public class RKIMManager: NSObject, IMCoreProtocl {
  
}

/// IM 参数配置
@objcMembers
public class RKIMConfig: NSObject {
    var socketURL: String ///socket url
    var httpURL: String  /// http url
    var beatInterval: Int = 5 ///心跳间隔
    public init(socketURL: String, httpURL:String, beatInterval: Int = 5) {
        self.socketURL = socketURL
        self.httpURL = httpURL
        self.beatInterval = beatInterval
    }
}

@objc public protocol IMCoreProtocl: NSObjectProtocol {
    
    static var share:RKIMManager! { get }

// MARK:-------------sdk 初始化------------------------
    /// 配置im config
    func config(config: RKIMConfig)
    
    /// 配置token
    func imToken(token: String)
    
    /// 开启连接
    func openClient()
    
    /// 断开链接
    func closeClient()
    
    /// 增加im 回调 无需移除 此处为弱引用
    func addDelegate(newDelegate: RKIMDelegate)
// MARK:  -------------APIs------------------------
    /// 获取联系人列表
    func contactList(compelet: @escaping (_ isSuccess:Bool, _ errorMessage:String?, _ result: [RKContactModel]?) -> Void)
    
    /// 获取群组列表
    func groupList(compelet: @escaping (_ isSuccess:Bool, _ errorMessage:String?, _ result: [RKGroupModel]?) -> Void)
    
    /// 获取群组用户列表
    func groupMemberList(groupID: String, compelet: @escaping (_ isSuccess:Bool, _ errorMessage:String?, _ result: [RKContactModel]?) -> Void)
    
    /// 创建群组
    func createGroup(groupName name: String, userList users:[String], compelet: @escaping RKResultCompelet)
    
    /// 为群组添加用户
    func addGroupUsers(groupID: String, userList users:[String], compelet: @escaping RKResultCompelet)
    
    /// 移除用户出群
    func rmoveGroupUsers(groupID: String, userList users:[String], compelet: @escaping RKResultCompelet)
    
    /// 解散群组
    func dissolveGroup(groupID: String, compelet: @escaping RKResultCompelet)
    
    
// MARK: -------------Message------------------------
    /// 创建文本消息
    func createTextMessage(reciever: String?, receiveGroup: String?, text: String) -> RKChatMessage?
    
    /// 创建图片消息
    func createImageMessage(reciever: String?, receiveGroup: String?, image: UIImage) -> RKChatMessage?
    
    /// 发送消息
    func sendMessage(_ message: RKChatMessage?, compelet: @escaping RKResultCompelet)
    
    /// 发送消息 带进度回调
    func sendMessage(_ message: RKChatMessage?, progressBlock: @escaping (_ percent: Float) ->Void, compelet: @escaping RKResultCompelet)
        
    /// 获取历史消息记录
    func historyMessage(reciever: String?, receiveGroup: String?, pageSize: String?, pageIndex: String?, sendTimeLongEnd: String?, compelet: @escaping RKResultCompelet)
    
    /// 更新未读数量
    func updateMessageRecordTime(groupID: String, compelet: @escaping RKResultCompelet)
    
    /// 上传文件
    func uploadCompressFile(file: Data, isImage: Bool, compress: Float, callbackQueue: DispatchQueue?, progressBlock:@escaping (Double) ->Void, completion: @escaping RKResultCompelet)
    
}
