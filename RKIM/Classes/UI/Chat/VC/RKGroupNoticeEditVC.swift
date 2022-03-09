//
//  RKGroupNoticeEditVC.swift
//  RKIM
//
//  Created by chzy on 2022/2/16.
//  编辑公告页

import Foundation
import RKIMCore
import RKBaseView
import IQKeyboardManager
import UIKit
import RKHandyJSON

class RKGroupNoticeEditVC: RKBaseViewController {
    var groupInfo = RKIMGroup() {
        didSet {
            notiModel = JSONDeserializer<DemoNoticeModel>.deserializeFrom(json: groupInfo.groupConfig)
        }
    }
    var notiModel: DemoNoticeModel? {
        didSet {
            if let notiModel = notiModel {
                titleTextfield.text = notiModel.title
                noticeTextView.text = notiModel.content
            }
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        IQKeyboardManager.shared().isEnableAutoToolbar = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        IQKeyboardManager.shared().isEnableAutoToolbar = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "修改群公告"
        
        view.addSubViews([titleTextfield, noticeTextView])
        titleTextfield.snp.makeConstraints { make in
            make.top.left.equalTo(10)
            make.height.equalTo(50)
            make.right.equalTo(-10)
        }
        navigationConfig()
        noticeTextView.snp.makeConstraints { make in
            make.edges.equalTo(UIEdgeInsets(top: 80, left: 10, bottom: 80, right: 10))
        }
    }
    
    func navigationConfig() {
        let rightBarButtonItem = UIBarButtonItem(title: "保存", style: .done, target: self, action: #selector(saveGroupNotice))
        self.navigationItem.rightBarButtonItem = rightBarButtonItem
    }
    
    
    @objc func saveGroupNotice() {
        guard let title = titleTextfield.text  else { return RKToast.show(withText: "公告标题不能为空", in: view) }
        guard let content = noticeTextView.text else {
            RKToast.show(withText: "公告内容不能为空", in: view)
            return }
        let groupID = groupInfo.groupId
        let tpNotiModel = DemoNoticeModel()
        tpNotiModel.content = content
        tpNotiModel.title = title
        guard let notiString = tpNotiModel.toJSONString()else { return  }
        RKIMManager.share.updateGroupInfo(groupId: groupID, groupConfig: notiString) { isSuccess, errorMessage, result in
            if isSuccess {
                DBHelper.asyGroup(groupID) { model in
                    if let group = model {
                        group.groupConfig = notiString
                        RKIMDBManager.dbAddObjects([group])
                    }
                }
                self.groupInfo.groupConfig = notiString
                self.notiModel = tpNotiModel
                RKToast.show(withText: "修改群信息成功", in: self.view)
            }
        }
    }
    
    lazy var titleTextfield: UITextField = {
        let tf = UITextField()
        tf.placeholder = "请输入公告名称"
        return tf
    }()
    lazy var noticeTextView: UITextView = {
        let textView = UITextView()
        textView.layer.borderWidth = 0.5
        textView.layer.borderColor = UIColor.gray.cgColor
        return textView
    }()
    
    
    
}
