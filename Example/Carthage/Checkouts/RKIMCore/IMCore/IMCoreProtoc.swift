//
//  IMCoreProtoc.swift
//  IMCore
//
//  Created by chzy on 2021/11/16.
//

import Foundation


public typealias RKResultCompelet = (_ isSuccess:Bool, _ errorMessage:String?, _ result: Any) -> Void

@objc public protocol RKIMDelegate: NSObjectProtocol {
    ///  收到消息
    func RKMessage(didReceiveMessageWith string: String)
    /// 开启成功
    func RKDidOpen()
    /// 开启失败
    func RKDidFail(WithError error: Error)
    /// 被远端关闭 code 码 reason 原因 wasClean 套接字是否干净
    func RKDidClose(code: Int, reason: String?, wasClean: Bool)
}

@objcMembers
open class RKIMManager: NSObject, IMCoreProtocl {
    
}

@objc public protocol IMCoreProtocl: NSObjectProtocol {
    
    static var share:RKIMManager! { get }
    
    /// 配置im socket baseurl 以及token
    func config(imUrl url:String, token imToken: String)
    
    /// 配置im http url
    func configHttp(imUrl url: String)
    
    /// 开启连接
    func openClient()
    
    /// 断开链接
    func closeClient()
    
    ///  发送心跳
    func sendBeat()
    
    /// 增加im 回调 无需移除 此处为弱引用
    func addDelegate(_ newDelegate: RKIMDelegate)
    
    /// 获取用户列表
    func userList( compelet: @escaping RKResultCompelet)
    
    /// 获取群组列表
    func groupList( compelet: @escaping RKResultCompelet)
    
    /// 获取群组用户列表
    func groupMember(_ groupID: String, compelet: @escaping RKResultCompelet)
    
    /// 创建群组
    func createGroup(groupName name: String, userList users:[String], compelet: @escaping RKResultCompelet)
    
    /// 为群组添加用户
    func addUsersToGroup(_ groupID: String,  userList users:[String], compelet: @escaping RKResultCompelet)
    
    /// 移除用户出群
    func rmoveUserToGroup(_ groupID: String,  userList users:[String], compelet: @escaping RKResultCompelet)
    
    /// 解散群组
    func dissolveGroup(_ groupID: String, compelet: @escaping RKResultCompelet)
    
    /// 发消息
    func sendMessage(reciever: String?, receiveGroup: String?, messageType: String?, messageDetail: String?, compelet: @escaping RKResultCompelet)
    
    /// 获取历史消息记录
    func historyMessage(reciever: String?, receiveGroup: String?, pageSize: String?, pageIndex: String?, sendTimeLongEnd: String?, compelet: @escaping RKResultCompelet)
    
    /// 更新未读数量
    func updateMessageRecordTime(_ groupID: String, compelet: @escaping RKResultCompelet)
    
    /// 上传文件
    func uploadCompressFile(file: Data, isImage: Bool, compress: Float, callbackQueue: DispatchQueue?, progressBlock:@escaping (Double) ->Void, completion: @escaping RKResultCompelet)
    
}
