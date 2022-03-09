//
//  RKMessageHistoryVC.swift
//  RKIM
//
//  Created by chzy on 2022/2/18.
//

import UIKit

class RKMessageHistoryVC: UIViewController {
    var groupID: String?
    var index = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let textBtn = UIButton()
        let imageBtn = UIButton()
        let videoBtn = UIButton()
        let fileBtn = UIButton()
        
        textBtn.setTitle("文字消息", for: .normal)
        imageBtn.setTitle("图片消息", for: .normal)
        videoBtn.setTitle("视频消息", for: .normal)
        fileBtn.setTitle("文件消息", for: .normal)
        
        textBtn.setTitleColor(.black, for: .normal)
        imageBtn.setTitleColor(.black, for: .normal)
        videoBtn.setTitleColor(.black, for: .normal)
        fileBtn.setTitleColor(.black, for: .normal)
        
        textBtn.backgroundColor = .gray
        imageBtn.backgroundColor = .gray
        videoBtn.backgroundColor = .gray
        fileBtn.backgroundColor = .gray
        
        textBtn.addTarget(self, action: #selector(searchTextVC), for: .touchUpInside)
        imageBtn.addTarget(self, action: #selector(searchImageVC), for: .touchUpInside)
        videoBtn.addTarget(self, action: #selector(searchVideoVC), for: .touchUpInside)
        fileBtn.addTarget(self, action: #selector(searchFileVC), for: .touchUpInside)
        
        view.addSubViews([textBtn, imageBtn, videoBtn, fileBtn])
        textBtn.snp.makeConstraints { make in
            make.size.equalTo((CGSize(width: 100, height: 100)))
            make.top.equalTo(50)
            make.left.equalTo(10)
        }

        imageBtn.snp.makeConstraints { make in
            make.top.equalTo(textBtn)
            make.size.equalTo(textBtn)
            make.centerX.equalToSuperview()
        }
        
        videoBtn.snp.makeConstraints { make in
            make.top.equalTo(textBtn)
            make.size.equalTo(textBtn)
            make.right.equalTo(-10)
        }
        
        fileBtn.snp.makeConstraints { make in
            make.size.equalTo(textBtn)
            make.left.equalTo(textBtn)
            make.top.equalTo(textBtn.snp_bottom).offset(20)
        }
    }

    
}

extension RKMessageHistoryVC {
    
    @objc func searchTextVC() {
        guard let groupID = groupID else { return }
        let chatHistoryVC = RKTextMessageHistoryVC()
        chatHistoryVC.groupID = groupID
        navigationController?.pushViewController(chatHistoryVC, animated: true)
    }
    
    @objc func searchImageVC() {
        guard let groupID = groupID else { return }
        let chatHistoryVC = RKImageVideoMessageVC()
        chatHistoryVC.groupID = groupID
        chatHistoryVC.messageType = .Image
        navigationController?.pushViewController(chatHistoryVC, animated: true)
    }
   
    @objc func searchVideoVC() {
        guard let groupID = groupID else { return }
        let chatHistoryVC = RKImageVideoMessageVC()
        chatHistoryVC.groupID = groupID
        chatHistoryVC.messageType = .Video
        navigationController?.pushViewController(chatHistoryVC, animated: true)
    }
    
    @objc func searchFileVC() {
        guard let groupID = groupID else { return }
        let chatHistoryVC = RKImageVideoMessageVC()
        chatHistoryVC.groupID = groupID
        chatHistoryVC.messageType = .File
        navigationController?.pushViewController(chatHistoryVC, animated: true)
    }
}
