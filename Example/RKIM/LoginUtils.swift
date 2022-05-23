//
//  LoginUtils.swift
//  RKIM_Example
//
//  Created by chzy on 2021/11/18.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import Alamofire

public enum EnvType {
    case test
    case develop
    case product
    
   public func sassURl() ->String {
        switch self {
        case .test:
            return "https://saas-ar-test.rokid.com"
        case .develop:
            return "https://saas-ar-dev.rokid-inc.com"
        case .product:
            return "https://saas-ar.rokid.com"
        }
    }
    
   public func imURl() ->String {
        switch self {
        case .test:
            return "https://im-test.rokid-inc.com/business/"
        case .develop:
            return "https://im-dev.rokid-inc.com/business/"
        case .product:
            return "https://im.rokid.com/business/"
        }
    }
    
   public func socketURl() ->String {
        switch self {
        case .test:
            return "wss://im-testwss.rokid-inc.com/ws/"
        case .develop:
            return "wss://im-devwss.rokid-inc.com/ws/"
        case .product:
            return "wss://im-wss.rokid.com/ws/"
        }
    }

}

public var env = EnvType.test

public class LoginHelper: NSObject {
    
    static let kurlPrex = env.sassURl()
    static let ktokenPrex = "Bearer "
    public class func loginAction(companyID: String?, userName: String?, password: String?, compeletBlock:@escaping (_ uid: String?, _ token: String?, _ errorMsg: String?) ->Void) {
        guard let userName = userName else {
            compeletBlock(nil, nil, "请输入用户名")
            return
        }
        guard let password = password else {
            compeletBlock(nil, nil, "请输入密码")
            return
        }
        
        var loginData: [String: String] = [:]
        loginData["appKey"] = "app"
        loginData["grantType"] = "companyUser"
        loginData["companyIndex"] = companyID ?? "rokid"
        loginData["deviceUserName"] = (userName)
        loginData["password"] = (password)
        loginData["scope"] = "server"
        
        let url = kurlPrex + "/api/auth/oauth/token"
        var headers = HTTPHeaders()
        headers.add(name: "Accept-Language", value: "zh-CN")
        headers.add(name: "Content-Type", value: "application/json")
        
        let req = AF.request(url, method: .post, parameters: loginData, encoding: JSONEncoding.default, headers: headers)
        req.response(queue: .main) { response in
            guard let data = response.data else { return }
            do {
              let json = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                let dic = json as! Dictionary<String, Any>
                guard let code = dic["code"] as? Int else { return }
                if code != 1 {
                    compeletBlock(nil, nil, dic["msg"] as? String)
                    return
                }
                let tpDict =  dic["data"] as! Dictionary<String, Any>
                let refreshToken = tpDict["accessToken"] as? String
                let uuid = dic["uuid"] as? String
                compeletBlock(uuid, refreshToken, nil)
            } catch let error {
              compeletBlock(nil, nil, "\(error)")
            }
        }
    }
    
    public class func getUserInfo(_ token: String, compelet:@escaping([String: Any]?, Bool) ->Void) {
        let url = kurlPrex + "/api/upms/v1/deviceUser/getDeviceUserLoginInfo"
        var headers = HTTPHeaders()
        headers.add(name: "Accept-Language", value: "zh-CN")
        headers.add(name: "Authorization", value: ktokenPrex + token)
        let req = AF.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers)
        req.response(queue: .main) { response in
            guard let data = response.data else {
                compelet(nil, false)
                return
            }
            do {
              let json = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let dic = json as? [String: Any] {
                    if let dataDict = dic["data"] as? [String: Any] {
                        compelet(dataDict, true)
                    }
                }
            } catch let error {
              print(error)
              compelet(nil, false)
            }
        }
    }

}
