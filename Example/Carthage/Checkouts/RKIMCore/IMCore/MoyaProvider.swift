//
//  MoyaProvider.swift
//  RKIM
//
//  Created by chzy on 2021/10/28.
//

import Foundation
import Moya
import Alamofire
import RKLogger
import Result
import CommonCrypto


class CustomServerTrustPoliceManager : ServerTrustPolicyManager {
    override func serverTrustPolicy(forHost host: String) -> ServerTrustPolicy? {
        return .disableEvaluation
    }
    
    public init() {
        super.init(policies: [:])
    }
}

public class RKProvider: MoyaProvider<RMIMHttpEnum> {
    
    public func requestCombine(_ target:RMIMHttpEnum, _ completion: @escaping RKResultCompelet) -> Cancellable {
        return request(target) { result in
            result.commen { isSuccess, response, errorMsg, code in
                completion(isSuccess, errorMsg, response as Any)
            }
        }
    }
    
    
    public override func request(_ target: RMIMHttpEnum, callbackQueue: DispatchQueue? = .none, progress: ProgressBlock? = .none, completion: @escaping Completion) -> Cancellable {
        //        print("*****************网络请求*************************")
        RKLog("*****************网络请求*************************", .info)
        RKLog("\(target.describeString) URL:\(target.method): \(target.baseURL)\(target.path) \n headers: \(target.headers!) \(target.task)", .verbose)
        let tmComletion:Completion = { result in
            RKLog("*****************网络结果*************************", .info)
            var message = "Couldn't access API"
            if case let .success(response) = result {
                let jsonString = try? response.mapString()
                message = jsonString ?? message
                RKLog(message, .verbose)
            }
            completion(result)
        }
        return super.request(target, callbackQueue: callbackQueue, progress: progress, completion: tmComletion)
        
    }
}


public let RKIMAPI: RKProvider = RKProvider()


public enum RMIMHttpEnum {
    
    case userList(keyword: String?)   /// 联系人列表
    case groupList(keyword: String?)  ///  群列表
    case selectUserList(groupId: String?) /// 查询群组内成员信息列表
    case createGroup(groupName: String?, userId: String?, userList: [String]?) ///  新建群
    case addUserInGroup(groupId: String?, userList: [String]?) ///拉人进群
    case removeUser(groupId: String?, userList: [String]?)     ///移除群用户
    case dismissGroup(groupId: String?)   ///解散群
    case uploadFile(file: Data?)     ///上传文件
    case uploadCompressFile(file: Data?, isImage: Bool, compress: Float = 0.5)  /// 上传图片视频 压缩， 是否是图片
    case historyMsgsearch(messageDetail: String?) /// 搜索聊天记录
    case sendMsg(reciever: String?, receiveGroup: String?, messageType: String?, messageDetail: String?)    /// 发送消息
    case historyMsg(reciever: String?, receiveGroup: String?, pageSize: String?, pageIndex: String?, sendTimeLongEnd: String?)    ///历史消息
    case updateMsgRecordTime(groupOrFriendId: String!) ///更新回话已读时间
}

extension RMIMHttpEnum: TargetType {
    
    public var describeString: String {
        switch self {
        case .userList: return "联系人列表"
        case .groupList: return "群列表"
        case .selectUserList: return "查询群内成员信息"
        case .createGroup: return "新建群"
        case .addUserInGroup: return "拉人进群"
        case .removeUser: return "移除群用户"
        case .dismissGroup: return "解散群"
        case .uploadFile: return "上传文件"
        case .historyMsgsearch: return "搜索聊天记录"
        case .sendMsg: return "发送消息"
        case .historyMsg: return "历史消息"
        case .updateMsgRecordTime: return "更新回话已读时间"
        case .uploadCompressFile(file: _, isImage: let isImage, compress: _):
            return "上传\(isImage) 图片"
        }
        return "暂未设置描述"
    }
    
    public var sampleData: Data {
        return "Half measures are as bad as nothing at all.".data(using: String.Encoding.utf8)!
    }
    
    public var baseURL: URL {
        return URL(string: RKIMSetting.MoyaBaseUrl)!
    }
    
    public var path: String {
        var path = ""
        switch self {
        case .userList: path = "group/selectUserList"
        case .groupList: path = "group/selectGroupUserList"
            //        case .selectUserList(g): path = "group/selectUserList"
        case .selectUserList(groupId: let groupId):
            path = "group/selectUserList/" + (groupId ?? "")
        case .createGroup: path = "group/newGroup"
        case .addUserInGroup: path = "group/addGroupUser"
        case .removeUser: path = "group/removeGroupUser"
        case .dismissGroup: path = "group/removeGroup/{groupId}"
        case .uploadFile: path = "imFile/uploadFile"
        case .historyMsgsearch: path = "message/historyMessageSearch"
        case .sendMsg: path = "message/sendMessage"
        case .historyMsg: path = "message/historyMessage"
        case .updateMsgRecordTime:  path = "message/updateRecordTime"
        case .uploadCompressFile(file: _, isImage: _, compress: _):
            path = "imFile/uploadCompressFile"
        }
        return path
    }
    
    public var method: Moya.Method {
        switch self {
        case .userList: return .get
        case .groupList: return .get
        case .selectUserList: return .get
        case .createGroup: return .post
        case .addUserInGroup: return .post
        case .removeUser: return .post
        case .dismissGroup: return .post
        case .uploadFile: return .post
        case .historyMsgsearch: return .post
        case .sendMsg: return .post
        case .historyMsg: return .post
        case .updateMsgRecordTime: return .post
        case .uploadCompressFile(file: _, isImage: _, compress: _):
            return .post
        }
    }
    
    
    
    public var task: Task {
        switch self {
        case .userList(keyword: let keyword) , .groupList(keyword: let keyword):
            var params: [String: Any] = [:]
            params["keywords"] = keyword
            return .requestParameters(parameters: params, encoding: URLEncoding.default)
            
        case .createGroup(groupName: let groupName, userId: let userId, userList: let userList):
            var params: [String: Any] = [:]
            params["groupName"] = groupName
            params["ownerId"] = userId
            params["userIdList"] = userList
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        case .selectUserList(groupId: _):
            return .requestPlain
        case .addUserInGroup(groupId: let groupId, userList: let userList), .removeUser(groupId: let groupId, userList: let userList):
            var params: [String: Any] = [:]
            params["groupId"] = groupId
            params["userIdList"] = userList
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
            
        case .dismissGroup(groupId: let groupId):
            var params: [String: Any] = [:]
            params["groupId"] = groupId
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
            
        case .uploadFile(file: let fileData):
            var formData: [Moya.MultipartFormData] = []
            guard let fileData = fileData else {
                return .requestPlain
            }
            let moyaFileData = Moya.MultipartFormData(provider: .data(fileData), name: "file", fileName: "\(arc4random())", mimeType: "image/jpeg")
            formData.append(moyaFileData)
            return .uploadMultipart(formData)
            
        case .uploadCompressFile(file: let fileData, isImage: let isImage, compress: let compress):
            var formData: [Moya.MultipartFormData] = []
            guard let fileData = fileData else {
                return .requestPlain
            }
            let miniType = isImage ? "image/jpeg" : "application/x-mpegURL"
            let moyaFileData = Moya.MultipartFormData(provider: .data(fileData), name: "file", fileName: "\(arc4random())", mimeType: miniType)
            formData.append(moyaFileData)
            var params: [String: Any] = [:]
            params["messageType"] = isImage ? "2" : "3"
            params["scale"] = "1.0"
            params["quality"] =  compress
            if isImage {
                params["frameNum"] = 1
            }
            return .uploadCompositeMultipart(formData, urlParameters: params)
            //            return .uploadMultipart(formData, )
            
        case .historyMsgsearch(messageDetail: let messageDetail):
            var params: [String: Any] = [:]
            params["messageDetail"] = messageDetail
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
            
        case .sendMsg(reciever: let reciever, receiveGroup: let receiveGroup, messageType: let messageType, messageDetail: let messageDetail):
            var params: [String: Any] = [:]
            params["reciever"] = reciever
            params["receiveGroup"] = receiveGroup
            params["messageType"] = messageType
            params["messageDetail"] = messageDetail
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
            
        case .historyMsg(reciever: let reciever, receiveGroup: let receiveGroup, pageSize: let pageSize, pageIndex: let pageIndex, sendTimeLongEnd: let sendTimeLongEnd):
            var params: [String: Any] = [:]
            params["reciever"] = reciever
            params["receiveGroup"] = receiveGroup
            params["pageSize"] = pageSize
            params["pageIndex"] = pageIndex
            params["sendTimeLongEnd"] = sendTimeLongEnd
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
            
        case .updateMsgRecordTime(groupOrFriendId: let groupOrFriendId):
            var params: [String: Any] = [:]
            params["groupOrFriendId"] = groupOrFriendId
            return .requestParameters(parameters: params, encoding: JSONEncoding.default)
        }
    }
    
    public var headers: [String : String]? {
        var _headers: [String: String] = [:]
        _headers["Access-Token"] = RKIMSetting.Moyatoken
        switch self {
        case .uploadCompressFile(file: _, isImage: _, compress:_):
            _headers["Content-Type"] = "application/x-www-form-urlencoded"
        default:break
        }
        return _headers
    }
    
    
}

