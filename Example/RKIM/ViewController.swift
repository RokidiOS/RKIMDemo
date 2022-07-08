//
//  ViewController.swift
//  RKIM
//
//  Created by chzy on 10/28/2021.
//  Copyright (c) 2021 chzy. All rights reserved.
//

import UIKit
import RKIM
import RKIMCore
import RKILogger
import WCDBSwift
import Alamofire
import RKIBaseView
import Kingfisher
import RKIUtils
import AFNetworking
import RKIHandyJSON
import RKSassLog

class demo: NSObject {
    var age: Int
    init(age: Int) {
        self.age = age
    }
}

class ViewController: UIViewController {
    
    @IBOutlet weak var consoleTextView: UITextView!
    
    @IBOutlet weak var userNameTf: UITextField!
    
    @IBOutlet weak var passwordTf: UITextField!
    
    @IBOutlet weak var infoLb: UILabel!

    
    var logText = ""
    @IBAction func loginAction(_ sender: Any) {
        infoLb.text = "正在登陆中"
        guard let userName = userNameTf.text else {
            RKToast.show(withText: "用户名不能为空", duration: 1, in: view)
            return }
        guard let password = passwordTf.text else {
            RKToast.show(withText: "密码不能为空", duration: 1, in: view)
            return  }
        env = .test
        
        LoginHelper.loginAction(companyID: "rokid", userName: userName, password: password, compeletBlock: { [self] uuid, token, erroMsg ,_ ,_  in
            guard let _ = uuid, let token = token else {
                if let msg = erroMsg {
                    RKToast.show(withText: msg, duration: 2, in: self.view)
                    self.infoLb.text = "登陆失败\(msg)"
                }
                return
            }
            
            LoginHelper.getUserInfo(token) { userDict, isSuccess in
                let model = JSONDeserializer<RKIMUser>.deserializeFrom(dict: userDict)
                if let model = model {
                    self.imInit(model.companyId, model.userId)
                }
            }
            
            self.infoLb.text = "登陆成功"
            UserDefaults.standard.set(self.userNameTf.text, forKey: self.udUserKey)
            UserDefaults.standard.set(self.passwordTf.text, forKey: self.udPwdKey)
        })
    }
    
    let udUserKey = "userName"
    let udPwdKey = "passwordName"
    override func viewDidLoad() {
        autoLogin()
        configImageCache()
    }

    func imInit(_ company: String, _ uid: String) {
        kUserId = uid
        

        RKToast.show(withText: "登陆成功", duration: 1, in: view)
        var isDev = false
        if isDev {
            env = .develop
            let httpURL = env.imURl()
            let socketUrl = env.socketURl()
            let appId = "11"
            let secrect = "7ba1b9a5566d4f609cc8efb25d0f1d60"
            let config = RKIMConfig(socketURL: socketUrl, httpURL: httpURL, appId: appId, secret: secrect)
            RKIMManager.share.config(config: config)
        } else {
            env = .test
            let httpURL = env.imURl()
            let socketUrl = "wss://im-testwss.rokid-inc.com/ws/"
            let appId = "12"
            let secrect = "e6c7207e2b3d4f9f8004298cedd127c8"
            let config = RKIMConfig(socketURL: socketUrl, httpURL: httpURL, appId: appId, secret: secrect)
            RKIMManager.share.config(config: config)
        }
     
        
        RKIMManager.share.addDelegate(newDelegate: self)
        

        RKIMManager.share.login(userId: uid, companyId: company)
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let demotbVC = storyboard.instantiateViewController(withIdentifier: "demotab")
        UIApplication.shared.keyWindow?.rootViewController = demotbVC
        if let demotbVC = demotbVC as? UITabBarController {
            if #available(iOS 15.0, *) {
                demotbVC.tabBar.scrollEdgeAppearance = demotbVC.tabBar.standardAppearance;
            }
        }
        
        rkInfoVC.share.startLisent()
        /// 登出回调
        LogoutHelper.logoutBlock = {
            UserDefaults.standard.removeObject(forKey: self.udUserKey)
            UserDefaults.standard.removeObject(forKey: self.udUserKey)
            UIApplication.shared.keyWindow?.rootViewController = self
            RKIMManager.share.logout()
        }
    }
    
    /// 自动登录策略
    func autoLogin() {
        if let userName = UserDefaults.standard.value(forKey: udUserKey) as? String,
            let pwd = UserDefaults.standard.value(forKey: udPwdKey) as? String  {
            userNameTf.text = userName
            passwordTf.text = pwd
            loginAction(self)
        }
    }
    
    /// 图片缓存策略
    func configImageCache() {
        let cache = ImageCache(name: "ctom", path: RKFileUtil.fileDir())
        cache.maxMemoryCost =  1024 * 1024 * 100
        KingfisherManager.shared.defaultOptions = [.targetCache(cache)]
        consoleTextView.isHidden = true
    }
    
}

extension ViewController: RKIMDelegate {
    func didFail(WithError error: Swift.Error) {
        RKLog("\(error.localizedDescription)")
        infoLb.text = "socket 连接失败\(error.localizedDescription)"
    }
    
    public func message(didReceiveSystemMessage message: RKIMMessage) {
        if message.messageDetailModel?.systemType == .LogOut {
            RKToast.show(withText: "其他端登录")
            LogoutHelper.logoutBlock()
        }
    }
    
    func message(didReceiveNormalMessage message: RKIMMessage) {
        
    }
    
    func didOpen() {
        infoLb.text = "socket 连接已打开"
    }
    
    func didClose(code: Int, reason: String?) {
        infoLb.text = "socket 关闭\(String(describing: reason))"
    }
      
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
}




