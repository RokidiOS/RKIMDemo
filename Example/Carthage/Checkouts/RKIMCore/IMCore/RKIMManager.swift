//
//  RKIMManager.swift
//  RKIMCore
//
//  Created by chzy on 2021/11/11.
//

import Foundation

class RKIMSetting: NSObject {
    static var Moyatoken: String = ""
    static var MoyaBaseUrl: String = ""
    static var SocketUrl: String = ""
    static var delegateArray = NSPointerArray.weakObjects()
    
    static func addToArray(_ obj:RKIMDelegate) {
        let ptr = Unmanaged<AnyObject>.passUnretained(obj).toOpaque()
        delegateArray.addPointer(ptr)
    }
    
    static func fetchFromArray(at ix:Int) -> RKIMDelegate? {
        if let ptr = delegateArray.pointer(at:ix) {
            let obj = Unmanaged<AnyObject>.fromOpaque(ptr).takeUnretainedValue()
            if let del = obj as? RKIMDelegate {
                return del
            }
        }
        return nil
    }
    
    static func allDelegate() -> [RKIMDelegate] {
        var array = [RKIMDelegate]()
        for idx in 0...(delegateArray.count-1) {
            if let ptr = delegateArray.pointer(at:idx) {
                let obj = Unmanaged<AnyObject>.fromOpaque(ptr).takeUnretainedValue()
                if let del = obj as? RKIMDelegate {
                    array.append(del)
                }
            }
        }
        return array
    }
}


extension RKIMManager {
    public static var share: RKIMManager! {
        return RKIMManager()
    }
    
    /// 配置url以及token
    /// - Parameters:
    ///   - imUrl: 基础url
    ///   - imToken: 用户token
    open func config(imUrl url:String, token imToken: String) {
        RKIMSocketManager.share.config(url: url, token: imToken)
        RKIMSocketManager.share.addDelegate(self)
        RKIMSetting.SocketUrl = url
        RKIMSetting.Moyatoken = imToken
    }
    
    open func configHttp(imUrl url: String) {
        RKIMSetting.MoyaBaseUrl = url
    }
    
    /// 添加IM回调代理
    /// - Parameter newDelegate: 代理
    open func addDelegate(_ newDelegate: RKIMDelegate) {
        RKIMSetting.addToArray(newDelegate)
    }
    
    /// 移除IM回调代理
    /// - Parameter newDelegate: 代理
    open func removeDelegate(_ newDelegate: RKIMDelegate) {
        
        //        let ptr = Unmanaged<AnyObject>.passUnretained(newDelegate).toOpaque()
        //        RKIMSetting.delegateArray.removePointer(at: ptr)
        //        RKIMSetting.delegateArray.removeAll (where: { delegate in
        //            delegate.identString() == newDelegate.identString()
        //        })
    }
    
    
    // MARK: socket
    
    /// 开启链接
    open func openClient() {
        RKIMSocketManager.share.openClient()
    }
    
    /// 关闭连接
    open func closeClient() {
        RKIMSocketManager.share.closeClient()
    }
    
    ///  发送心跳
    open func sendBeat() {
        RKIMSocketManager.share.sendBeat()
    }
    
    // MARK: http
    
    /// 获取联系人列表
    /// - Parameter compelet:
    open func userList( compelet: @escaping RKResultCompelet) {
        _ = RKIMAPI.requestCombine(.userList(keyword: nil)) { isSuccess, errorMessage, result in
            compelet(isSuccess, errorMessage, result)
        }
    }
    
    ///群聊列表
    open func groupList( compelet: @escaping RKResultCompelet) {
        _ = RKIMAPI.requestCombine(.groupList(keyword: nil)) { isSuccess, errorMessage, result in
            compelet(isSuccess, errorMessage, result)
        }
    }
    
    /// 查询群组内成员信息列表
    /// - Parameters:
    ///   - groupID: 群组id
    ///   - compelet: 回调
    open func groupMember(_ groupID: String, compelet: @escaping RKResultCompelet) {
        _ = RKIMAPI.requestCombine(.selectUserList(groupId: groupID)) { isSuccess, errorMessage, result in
            compelet(isSuccess, errorMessage, result)
        }
    }
    
    /// 创建群
    open func createGroup(groupName name: String, userList users:[String], compelet: @escaping RKResultCompelet) {
        _ = RKIMAPI.requestCombine(.createGroup(groupName: name, userId: nil, userList: users)) { isSuccess, errorMessage, result in
            compelet(isSuccess, errorMessage, result)
        }
    }
    
    ///拉人入群
    open func addUsersToGroup(_ groupID: String,  userList users:[String], compelet: @escaping RKResultCompelet) {
        _ = RKIMAPI.requestCombine(.addUserInGroup(groupId: groupID, userList: users)) { isSuccess, errorMessage, result in
            compelet(isSuccess, errorMessage, result)
        }
    }
    
    ///移除群成员
    open func rmoveUserToGroup(_ groupID: String,  userList users:[String], compelet: @escaping RKResultCompelet) {
        _ = RKIMAPI.requestCombine(.removeUser(groupId: groupID, userList: users)) { isSuccess, errorMessage, result in
            compelet(isSuccess, errorMessage, result)
        }
    }
    
    /// 解散群
    open func dissolveGroup(_ groupID: String, compelet: @escaping RKResultCompelet) {
        _ = RKIMAPI.requestCombine(.dismissGroup(groupId: groupID)) { isSuccess, errorMessage, result in
            compelet(isSuccess, errorMessage, result)
        }
    }
    
    /// 发送消息
    open func sendMessage(reciever: String?, receiveGroup: String?, messageType: String?, messageDetail: String?, compelet: @escaping RKResultCompelet) {
        _ = RKIMAPI.requestCombine(.sendMsg(reciever: reciever, receiveGroup: receiveGroup, messageType: messageType, messageDetail: messageDetail)) { isSuccess, errorMessage, result in
            compelet(isSuccess, errorMessage, result)
        }
    }
    
    /// 获取历史消息
    open func historyMessage(reciever: String?, receiveGroup: String?, pageSize: String?, pageIndex: String?, sendTimeLongEnd: String?, compelet: @escaping RKResultCompelet) {
        _ = RKIMAPI.requestCombine(.historyMsg(reciever: reciever, receiveGroup: receiveGroup, pageSize: pageSize, pageIndex: pageIndex, sendTimeLongEnd: sendTimeLongEnd)) { isSuccess, errorMessage, result in
            compelet(isSuccess, errorMessage, result)
        }
    }
    
    /// 更新会话已读
    open func updateMessageRecordTime(_ groupID: String, compelet: @escaping RKResultCompelet) {
        _ = RKIMAPI.requestCombine(.updateMsgRecordTime(groupOrFriendId: groupID)) { isSuccess, errorMessage, result in
            compelet(isSuccess, errorMessage, result)
        }
    }
    
    open func uploadCompressFile(file: Data, isImage: Bool, compress: Float, callbackQueue: DispatchQueue? = .none, progressBlock:@escaping (Double) ->Void, completion: @escaping RKResultCompelet) {
        _ = RKIMAPI.request(.uploadCompressFile(file: file, isImage: isImage, compress: compress), progress: { progress in
            progressBlock(progress.progress)
        }, completion: { result in
            result.commen { isSuccess, response, errorMessage, code in
                completion(isSuccess, errorMessage, response)
            }
        })
    }
}



extension RKIMManager: ImSocketDelegate {
    func rkwebSocketDidOpen() {
        _ = RKIMSetting.allDelegate().map { delegate in
            delegate.RKDidOpen()
        }
    }
    
    func rkwebSocket(didFailWithError error: Error) {
        _ = RKIMSetting.allDelegate().map { delegate in
            delegate.RKDidFail(WithError: error)
        }
    }
    
    func rkwebSocket(didCloseWithCode code: Int, reason: String?, wasClean: Bool) {
        _ = RKIMSetting.allDelegate().map { delegate in
            delegate.RKDidClose(code: code, reason: reason, wasClean: wasClean)
        }
    }
    
    func rkwebSocket(didReceiveMessageWith string: String) {
        _ = RKIMSetting.allDelegate().map { delegate in
            delegate.RKMessage(didReceiveMessageWith: string)
        }
    }
    
    func identString() -> String {
        return "rkMainManager"
    }
    
    
}
