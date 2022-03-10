//
//  rkInfoVC.swift
//  RKIM_Example
//
//  Created by chzy on 2022/2/17.
//  Copyright © 2022 CocoaPods. All rights reserved.
//

import UIKit
import RKIMCore
import RKILogger

class rkInfoVC: UIViewController {
    static let share = rkInfoVC()
    
    var isShow = false
    var logText = ""
    var isAddListen = false
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.consoleTextView.text = self.logText
        isShow = true
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isShow = false
    }
    private func addpendTextView(string: String) {
        logText = logText + "\n" + "\(Date())" + "\n" +  string
        if isShow {
            DispatchQueue.main.async {
                self.consoleTextView.text = self.logText
            }
        }
    }

    
    func startLisent() {
        if isAddListen {
            return
        }
        RKIMManager.share.addDelegate(newDelegate: self)
        isAddListen = true
    }
    
    override
    func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        view.addSubview(consoleTextView)
        consoleTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    

    lazy var consoleTextView = UITextView()
}

extension rkInfoVC: RKIMDelegate {
    func didFail(WithError error: Swift.Error) {
        self.title = "socket 连接失败\(error.localizedDescription)"
        addpendTextView(string: self.title!)
    }
    
    public func message(didReceiveSystemMessage message: RKIMMessage) {
        if  let json = message.toJSONString() {
            
            addpendTextView(string: json)
        }
    }
    
    func didOpen() {
        self.title = "socket 连接已打开"
        addpendTextView(string: self.title!)
    }
    
    func didClose(code: Int, reason: String?) {
        self.title = "socket 关闭\(String(describing: reason))"
        guard let reason = reason else {
            return
        }
        addpendTextView(string: reason)
    }
      
}
